#!/usr/bin/env python3
"""
reflect_to_org_roam.py

Convert a Reflect Notes JSON export into an Org-Roam-shaped folder tree.

Input  : reflect-org-mattie-YYYYMMDD-HHMM-vN.N.json
Output : <out_dir>/
           ├── concepts/
           ├── projects/
           ├── people/
           ├── refs/
           ├── journal/        (org-roam dailies)
           └── attachments/    (empty placeholder)

Conventions matched to Mattie's Doom config:
  - one .org file per Reflect note
  - :ID: property is a fresh UUID (Reflect IDs preserved as :REFLECT_ID:)
  - daily notes named YYYY-MM-DD.org (matches org-roam-dailies template)
  - other notes named <created>-<slug>.org (matches org-roam-capture template)
  - filetags reflect category + any user-applied Reflect tags
  - backlinks rewritten to [[id:UUID][label]] using new IDs
  - unresolved backlinks degrade to [[roam:label]] so org-roam can resolve later

Usage:
  python3 reflect_to_org_roam.py <input.json> <output_dir>
"""

from __future__ import annotations

import json
import os
import re
import sys
import uuid
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# CATEGORIZATION
# ---------------------------------------------------------------------------

PERSON_TAGS  = {"person"}
REF_TAGS     = {"book", "author", "reference", "quick-ref", "bookmark",
                "app-doc", "manual", "directory", "font"}
PROJECT_TAGS = {"project", "career", "organization", "application",
                "job-posting", "planning"}
PROJECT_EMOJIS = {"💾", "🌐", "🔭", "🈺", "🏴‍☠️", "🍰", "🎸", "🌊"}

# Tags we never propagate into the file (purely structural)
HOIST_ONLY_TAGS: set[str] = set()


def slugify(s: str, fallback: str = "untitled") -> str:
    """Org-roam-style slug: lowercase, ascii alphanum, underscore-separated."""
    if not s:
        return fallback
    s = s.lower()
    # strip emoji and most non-ascii, but keep word chars
    s = re.sub(r"[^\w\s-]", "", s, flags=re.UNICODE)
    s = re.sub(r"[^a-z0-9\s_-]", "", s)
    s = re.sub(r"[\s_-]+", "_", s).strip("_")
    return s or fallback


def gather_tags(doc: dict) -> set[str]:
    out: set[str] = set()

    def walk(n: dict) -> None:
        if n.get("type") == "tag":
            label = (n.get("attrs") or {}).get("label")
            if label:
                out.add(label.strip())
        for c in n.get("content", []) or []:
            walk(c)

    walk(doc)
    return out


def categorize(note: dict, doc: dict | None) -> str:
    """Return one of: journal, people, refs, projects, concepts."""
    if note.get("daily_at"):
        return "journal"

    tags = gather_tags(doc) if doc else set()
    if tags & PERSON_TAGS:
        return "people"
    if tags & REF_TAGS:
        return "refs"
    if tags & PROJECT_TAGS:
        return "projects"

    title = (note.get("subject") or "").lstrip()
    if title:
        # Crude emoji-prefix sniff: first char in PROJECT_EMOJIS
        # (some emoji are multi-codepoint; check first 4 chars)
        head = title[:4]
        if any(e in head for e in PROJECT_EMOJIS):
            return "projects"

    return "concepts"


# ---------------------------------------------------------------------------
# PROSEMIRROR → ORG CONVERSION
# ---------------------------------------------------------------------------

LIST_KIND_BULLET = {
    "bullet": "-",
    "ordered": "1.",
    "checklist": "-",
    "task": "-",
    "todo": "-",
}
CHECKABLE = {"checklist", "task", "todo"}


class Renderer:
    def __init__(self, registry: dict[str, dict], note_id: str) -> None:
        self.registry = registry
        self.note_id = note_id
        self.note = registry[note_id]
        self.warnings: list[str] = []

    # ---- inline (text + marks) ------------------------------------------

    def render_inline(self, nodes: list[dict]) -> str:
        out: list[str] = []
        for n in nodes:
            t = n.get("type")
            if t == "text":
                out.append(self._render_text(n))
            elif t == "hardBreak":
                out.append("\n")
            elif t == "backlink":
                out.append(self._render_backlink(n))
            elif t == "tag":
                # tags are hoisted to filetags; drop them from body
                pass
            else:
                # nested block inside what we expected to be inline:
                # render it block-style and append
                out.append("\n" + self.render_block(n) + "\n")
        return "".join(out)

    def _render_text(self, n: dict) -> str:
        text = n.get("text", "")
        if not text:
            return ""
        marks = [m.get("type") for m in (n.get("marks") or [])]
        attrs_by_mark = {m.get("type"): (m.get("attrs") or {}) for m in (n.get("marks") or [])}

        # Normalize: emphasis can't wrap text containing newlines cleanly in org
        # so we split on \n and apply marks to each chunk.
        chunks = text.split("\n")
        rendered = []
        for chunk in chunks:
            if not chunk:
                rendered.append("")
                continue
            r = chunk
            # code/verbatim is exclusive — skip other style marks
            if "code" in marks:
                r = f"={r}="
            else:
                if "bold" in marks:
                    r = f"*{r}*"
                if "italic" in marks:
                    r = f"/{r}/"
                if "strike" in marks:
                    r = f"+{r}+"
                if "underline" in marks:
                    r = f"_{r}_"
                if "textHighlight" in marks:
                    # Org has no native highlight; wrap in a noop macro-ish marker
                    r = f"@@html:<mark>@@{r}@@html:</mark>@@"
            if "link" in marks:
                href = attrs_by_mark.get("link", {}).get("href", "")
                if href:
                    r = f"[[{href}][{r}]]"
            rendered.append(r)
        return "\n".join(rendered)

    def _render_backlink(self, n: dict) -> str:
        attrs = n.get("attrs") or {}
        target_reflect_id = attrs.get("id")
        label = attrs.get("label", "") or ""
        target = self.registry.get(target_reflect_id)
        if target:
            return f"[[id:{target['uuid']}][{label}]]"
        # Fallback: org-roam's "roam:" link will resolve at-find-time if a
        # node with that title (or alias) is later created.
        self.warnings.append(f"unresolved backlink: {label!r} ({target_reflect_id})")
        if label:
            return f"[[roam:{label}]]"
        return ""

    # ---- block renderers -------------------------------------------------

    def render_block(self, n: dict, indent: int = 0) -> str:
        t = n.get("type")
        if t == "doc":
            return self._render_children(n, indent)
        if t == "paragraph":
            return self._render_paragraph(n)
        if t == "heading":
            return self._render_heading(n)
        if t == "list":
            return self._render_list_item(n, indent)
        if t == "orderedList":
            # legacy / rare — treat children as bullet items
            return "\n".join(self._render_list_item(c, indent) for c in (n.get("content") or []) if c.get("type") == "list" or True)
        if t == "listItem":
            # rare — treat as a paragraph
            return self._render_paragraph(n)
        if t == "blockquote":
            return self._render_blockquote(n, indent)
        if t == "codeBlock":
            return self._render_code(n)
        if t == "horizontalRule":
            return "-----\n"
        if t == "image":
            return self._render_image(n)
        if t == "iframe":
            return self._render_iframe(n)
        if t == "file":
            return self._render_file(n)
        if t == "hardBreak":
            return "\n"
        # Unknown — best effort: render any inline content
        if "content" in n:
            return self._render_children(n, indent)
        return ""

    def _render_children(self, n: dict, indent: int) -> str:
        return "\n".join(
            self.render_block(c, indent) for c in (n.get("content") or [])
        )

    def _render_paragraph(self, n: dict) -> str:
        return self.render_inline(n.get("content") or [])

    def _render_heading(self, n: dict) -> str:
        level = (n.get("attrs") or {}).get("level", 1) or 1
        text = self.render_inline(n.get("content") or []).strip()
        if not text:
            return ""
        # Skip duplicate-of-title H1 (Reflect convention)
        if level == 1 and text.strip().lower() == (self.note["title"] or "").strip().lower():
            return ""
        # Demote H1 → *, H2 → **, etc., but cap at 5 stars
        stars = "*" * max(1, min(5, level))
        return f"{stars} {text}"

    def _render_list_item(self, n: dict, indent: int) -> str:
        """A Reflect 'list' node IS one item. Its content is the item's body
        plus any nested 'list' children."""
        attrs = n.get("attrs") or {}
        kind = attrs.get("kind", "bullet")
        bullet = LIST_KIND_BULLET.get(kind, "-")
        if kind in CHECKABLE:
            bullet = "- [X]" if attrs.get("checked") else "- [ ]"
        pad = "  " * indent

        # Separate the item's "first-line" content from nested lists
        own_lines: list[str] = []
        nested: list[str] = []
        for c in n.get("content") or []:
            ct = c.get("type")
            if ct == "list":
                nested.append(self._render_list_item(c, indent + 1))
            elif ct == "paragraph":
                own_lines.append(self.render_inline(c.get("content") or []))
            elif ct == "heading":
                # Headings inside a list — render inline so bullets stay valid
                txt = self.render_inline(c.get("content") or []).strip()
                own_lines.append(txt)
            elif ct == "blockquote":
                # Render quote contents as a sublist
                for cc in c.get("content") or []:
                    if cc.get("type") == "list":
                        nested.append(self._render_list_item(cc, indent + 1))
                    else:
                        own_lines.append(self.render_block(cc, indent))
            elif ct == "codeBlock":
                # Code block under a list item — emit on its own line, indented
                code = self._render_code(c)
                own_lines.append("\n" + code)
            else:
                own_lines.append(self.render_block(c, indent))

        first = ""
        if own_lines:
            # Join multi-line item bodies with proper indentation
            joined = "\n".join(s for s in own_lines if s).strip("\n")
            # Indent any continuation lines to align with the bullet text
            cont_pad = pad + "  "
            joined_lines = joined.split("\n")
            joined = ("\n" + cont_pad).join(joined_lines)
            first = f"{pad}{bullet} {joined}"
        else:
            first = f"{pad}{bullet}"
        out = [first]
        out.extend(nested)
        return "\n".join(out)

    def _render_blockquote(self, n: dict, indent: int) -> str:
        inner = self._render_children(n, indent).strip("\n")
        return f"#+begin_quote\n{inner}\n#+end_quote"

    def _render_code(self, n: dict) -> str:
        attrs = n.get("attrs") or {}
        lang = attrs.get("language") or ""
        text_parts = []
        for c in n.get("content") or []:
            if c.get("type") == "text":
                text_parts.append(c.get("text", ""))
        body = "".join(text_parts)
        return f"#+begin_src {lang}\n{body}\n#+end_src"

    def _render_image(self, n: dict) -> str:
        attrs = n.get("attrs") or {}
        src = attrs.get("src", "")
        alt = attrs.get("alt", "") or "image"
        if not src:
            return ""
        # Reflect images live on Reflect's CDN; keep the URL link.
        return f"[[{src}][{alt}]]"

    def _render_iframe(self, n: dict) -> str:
        attrs = n.get("attrs") or {}
        src = attrs.get("src", "")
        kind = attrs.get("type", "embed")
        if not src:
            return ""
        return f"[[{src}][{kind}: {src}]]"

    def _render_file(self, n: dict) -> str:
        attrs = n.get("attrs") or {}
        url = attrs.get("url", "")
        name = attrs.get("fileName", "file")
        if not url:
            return ""
        return f"[[{url}][{name}]]"


# ---------------------------------------------------------------------------
# FILE EMISSION
# ---------------------------------------------------------------------------

def parse_iso(ts: str) -> datetime | None:
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00"))
    except Exception:
        return None


def filename_for(note: dict, category: str) -> str:
    if category == "journal":
        # Reflect daily IDs are MMDDYYYY strings; daily_at is ISO
        d = parse_iso(note.get("daily_at") or "")
        if d:
            return f"{d:%Y-%m-%d}.org"
        # fall back
        return f"{note['id']}.org"
    created = parse_iso(note.get("created_at") or "") or datetime.now(timezone.utc)
    return f"{created:%Y%m%d%H%M%S}-{note['slug']}.org"


def emit_note(out_root: Path, note: dict, registry: dict) -> tuple[str, list[str]]:
    """Write a single org file and return (relative_path, warnings)."""
    category = note["category"]
    filename = note["filename"]
    folder = out_root / category
    folder.mkdir(parents=True, exist_ok=True)
    path = folder / filename

    doc = note.get("doc")

    # Build header
    header_lines = [
        ":PROPERTIES:",
        f":ID:       {note['uuid']}",
        f":REFLECT_ID: {note['id']}",
    ]
    created = parse_iso(note.get("created_at") or "")
    updated = parse_iso(note.get("updated_at") or "")
    if created:
        header_lines.append(f":CREATED:  [{created:%Y-%m-%d %a %H:%M}]")
    if updated:
        header_lines.append(f":MODIFIED: [{updated:%Y-%m-%d %a %H:%M}]")
    header_lines.append(":END:")

    # Strip trailing #tag tokens that users typed into Reflect titles for
    # visual flair (e.g. "Web Design Inspiration Sites #list").
    title = note["title"] or "(untitled)"
    title = re.sub(r"(?:\s+#[\w\-]+)+\s*$", "", title).strip() or "(untitled)"
    header_lines.append(f"#+title: {title}")

    # filetags = category + user tags, deduped
    cat_tag = {"journal": "daily", "people": "person", "refs": "ref",
               "projects": "project", "concepts": "concept"}[category]
    user_tags = sorted({t for t in (note.get("tags") or set()) if t})
    norm_tags: list[str] = []
    seen_tags: set[str] = set()
    for t in [cat_tag] + [t.replace(" ", "_").replace("-", "_") for t in user_tags]:
        if t not in seen_tags:
            norm_tags.append(t)
            seen_tags.add(t)
    header_lines.append(f"#+filetags: :{':'.join(norm_tags)}:")

    if created:
        header_lines.append(f"#+date: {created:%Y-%m-%d}")

    header_lines.append("")  # blank line

    # Body
    body_warnings: list[str] = []
    if doc is not None:
        renderer = Renderer(registry, note["id"])
        body = renderer.render_block(doc).strip("\n")
        body_warnings = renderer.warnings
    else:
        body = ""

    # Collapse > 2 consecutive blank lines into 2
    body = re.sub(r"\n{3,}", "\n\n", body)

    text = "\n".join(header_lines) + body + "\n"
    path.write_text(text, encoding="utf-8")
    rel = path.relative_to(out_root)
    return str(rel), body_warnings


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    in_path = Path(sys.argv[1])
    out_root = Path(sys.argv[2])

    if out_root.exists() and any(out_root.iterdir()):
        print(f"WARN: output dir {out_root} is not empty; existing files may be overwritten")
    out_root.mkdir(parents=True, exist_ok=True)
    (out_root / "attachments").mkdir(exist_ok=True)

    raw = json.loads(in_path.read_text(encoding="utf-8"))
    notes_raw = raw.get("notes", [])
    print(f"Loaded {len(notes_raw)} notes from {in_path.name}")

    # Pass 1: build registry (assign UUIDs, parse docs, categorize)
    registry: dict[str, dict] = {}
    parse_failures: list[str] = []
    for n in notes_raw:
        rid = n["id"]
        title = (n.get("subject") or "").strip()
        try:
            doc = json.loads(n["document_json"]) if n.get("document_json") else None
        except Exception as e:
            doc = None
            parse_failures.append(f"{rid}: {e}")
        category = categorize(n, doc) if doc else ("journal" if n.get("daily_at") else "concepts")
        tags = gather_tags(doc) if doc else set()
        slug = slugify(title)
        entry = {
            "id": rid,
            "uuid": str(uuid.uuid4()),
            "title": title,
            "slug": slug,
            "category": category,
            "tags": tags,
            "doc": doc,
            "created_at": n.get("created_at"),
            "updated_at": n.get("updated_at"),
            "edited_at": n.get("edited_at"),
            "daily_at": n.get("daily_at"),
            "backlinked_count": n.get("backlinked_count", 0),
        }
        entry["filename"] = filename_for(entry, category)
        registry[rid] = entry

    if parse_failures:
        print(f"document_json parse failures: {len(parse_failures)}")
        for f in parse_failures[:5]:
            print(f"  {f}")

    # Detect filename collisions (e.g., two dailies on same date — shouldn't happen)
    seen: dict[tuple[str, str], str] = {}
    collisions = 0
    for rid, e in registry.items():
        key = (e["category"], e["filename"])
        if key in seen:
            collisions += 1
            # Disambiguate by appending short uuid
            stem, ext = os.path.splitext(e["filename"])
            e["filename"] = f"{stem}-{e['uuid'][:8]}{ext}"
        seen[(e["category"], e["filename"])] = rid
    if collisions:
        print(f"Filename collisions resolved: {collisions}")

    # Pass 2: emit files
    by_cat: Counter = Counter()
    all_warnings: Counter = Counter()
    for rid, e in registry.items():
        rel, warns = emit_note(out_root, e, registry)
        by_cat[e["category"]] += 1
        for w in warns:
            all_warnings[w] += 1

    # Summary
    print(f"\nWrote {sum(by_cat.values())} files to {out_root}")
    for cat in ("concepts", "projects", "people", "refs", "journal"):
        print(f"  {cat:10s} {by_cat.get(cat, 0):4d}")
    if all_warnings:
        print(f"\nWarnings ({sum(all_warnings.values())} total, {len(all_warnings)} unique):")
        for msg, count in all_warnings.most_common(10):
            print(f"  [{count}x] {msg}")

    # Quick sanity: total backlinks resolved vs unresolved
    return 0


if __name__ == "__main__":
    sys.exit(main())
