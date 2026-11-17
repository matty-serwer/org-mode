;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; ============================================================================
;; IDENTITY
;; ============================================================================
(setq user-full-name "Mattie Aran"
      user-mail-address "mattie@lupinetechdesign.com")


;; ============================================================================
;; THEME & VISUAL
;; ============================================================================

;; Load custom themes from local directory
(add-to-list 'custom-theme-load-path "~/.config/doom/themes/")
(setq doom-theme 'doom-dracula)

;; Font stack
;;   doom-font         → primary monospace (code, prose)
;;   doom-big-font     → doom-big-font-mode (presentations / streaming)
;;   doom-variable-pitch-font → non-monospace prose
;;   doom-symbol-font  → icons / symbols
(setq doom-font              (font-spec :family "Menlo" :size 14.5)
      doom-big-font          (font-spec :family "NotoSansM NFM" :size 16.0)
      doom-variable-pitch-font (font-spec :family "Bangla MN" :size 14)
      doom-symbol-font       (font-spec :family "Symbols Nerd Font Mono"))
;; Smaller zoom step so Cmd+= / Cmd+- feel less jarring (default is 2)
(setq doom-font-increment 1)

;; Italic comments and keywords
(custom-set-faces!
  '(font-lock-comment-face :slant italic)
  '(font-lock-keyword-face :slant italic))

;; Dashboard banner foreground color
(after! doom-themes
  (custom-set-faces!
    '(doom-dashboard-banner
      :foreground "#8a8dff"
      :weight bold
      :slant normal)))

;; Window opacity: (active . inactive)
(set-frame-parameter (selected-frame) 'alpha '(98 . 90))
(add-to-list 'default-frame-alist '(alpha . (98 . 90)))

;; Default frame geometry (macOS)
                                        ;(setq frame-resize-pixelwise t)
                                        ;(add-to-list 'default-frame-ali;st '(width  . 180))
                                        ;(add-to-list 'default-frame-alist '(height . 55))

;; Custom ASCII dashboard banner
(defun my/doom-dashboard-banner ()
  (let ((banner
         '("                                   ...::::'''''::::::::'::::::::::::::::::"
           "                                ...::::::       `:::'`   `:::::::::::::::"
           "                            ......:::::::   .,cccc,       :::::::::::::::"
           "                            ....::::::::`` ,cd$$$$$$$$, cccc, `::::::::::::"
           "                    ......::::::::::``  ,c$$$$$$$$$$$$F $$$$$$, `::::::::::"
           "                .....,:::'.:::::`,cF',d$$$$$$$$$$$$$\" -?$$$$$$, ::::::::::"
           "             ........::: .::::: ,dP',$$$$$$$$$$$$$$\",c$$c ?$$$$$, ::::::::"
           "        .....::...::::::',d$F c$$$$$$$$$$$P\"',d$$$$$$c ?$$$$,`:::::::"
           "      .....::::::::::::::::',$$F c$$$$$$$$$P\"',d$$$$$$$$$$b ?$$$F :::::::"
           "     ....::::::::::::::::: ,$$P J$$$>?\"\"\".,r=\"\"?$$$$$$$$$$$b $$$P :::::::"
           "       ..`':::::::::::::::' d$$> $$$$$P\",$$Lzd$$c,C$$$$$$$??? $$P'.:::::::"
           "         `::::::::::::::: d$$$> $$$P\" ,$$$$P??\"\"?$$$$$$$cc$c \".::::::::::"
           "          `'::::::::::::: $$$$b J$$P\",d$$P\",   -$$$$P\"3$?$?  ::::::::::::"
           "         :::.`'`::::::::: <$$$$$=\"  ,c$$$$c,   _4$$$P ',  `  ::::::::::::'"
           "         ::::::::::::::' <$$$$, $, ?$$$$$$$$$$$$$$$L  \"    ::::::::::::: :"
           "        ::: ::::::::: ,c <$$$$$b,$c,  $$$$$$$$$$P?$$ 4$cd  `:::::::::::: :"
           "        ::: ::::::'  z$$ <$$$$$$$$$ ? $$$$$$$$P?$$L,c$$$F dc `:::::::::: :"
           "       :::: ::::'  z$$:$$,<$$$$$$$$$$,  ?$$$$$.  -  $$$P\",d$$b `::::::::::."
           "       :::  :::' .$$$$$$L$$$$$$$$$$$b    ?$$$$c;;ccP\"',c$$$$$c :::::::::::"
           "       ::  :::  d$$$$$$$$$$$$$$$$$$$$L   . \"????\"\"  c$$$$$$$$$ :::::::::::"
           "       '  :::  $$$$$$$$$$$$???$$$$$c\"$ <L ?$ccr= xL  `\"\"\"\"\"\"\"\" ` . :::::::"
           "        .:::  $$$$$$$$$$$>`\"= `$$$$$L  <Mh.\"\" ,eMM\"?P MMMMbeMP  \"\" ::::::"
           "       ::::: 4P'$$$$$$$$$'  \"M,`$$$$$  `M\" xMn.`TT \"C. ,MMMM\",CCCCC `::: :"
           "           ,__  ___   ___  ______ ______ _  _____                          "
           "           |  \\/  |  /   ||___  /|___  /(_)|____ |                         "
           "           | .  . | / /| |   / /    / /  _     / /     ___ __  __  ___     "
           "          | |\\/| |/ /_| |  / /    / /  | |    \\ \\    / _ \\\\ \\ / /  _ \\   "
           "           | |  | |\\___  |./ /   ./ /   | |.___/ / _ |  __/ >  < |  __/    "
           "           \\_|  |_/    |_/\\_/    \\_/    |_|\\____/ (_) \\___|/_/\\_\\ \\___|    ")))
    (dolist (line banner)
      (insert
       (propertize
        (+doom-dashboard--center +doom-dashboard--width line)
        'face 'doom-dashboard-banner))
      (insert "\n"))))

(setq +doom-dashboard-ascii-banner-fn #'my/doom-dashboard-banner)

;; ============================================================================
;; EDITOR DEFAULTS
;; ============================================================================

(setq display-line-numbers-type t)  ; set to 'relative for relative line numbers

(setq-default standard-indent 2
              tab-width       2
              indent-tabs-mode nil)

;; Soft-wrap everywhere
(+global-word-wrap-mode +1)

;; Spell check: off by default. Toggle in any buffer with SPC t s
;; (or M-x flyspell-mode). Backend: aspell.
;; (setq ispell-program-name "aspell"
;;      ispell-dictionary   "en_US")

;; Make sure flyspell isn't auto-enabled by any hooks
;; (remove-hook 'text-mode-hook #'flyspell-mode)
;; (remove-hook 'prog-mode-hook #'flyspell-prog-mode)

;; ============================================================================
;; COMPLETION — CORFU
;; ============================================================================

(after! corfu
  ;; Off by default — no popup as you type. Trigger manually with C-SPC
  ;; (or TAB in insert mode, depending on context).
  (setq corfu-auto nil
        ;; Don't let SPC / RET trigger completion on an exact match.
        corfu-on-exact-match nil
        ;; If auto IS turned on, require 3 chars before popping up.
        corfu-auto-prefix 3
        ;; And wait 0.3s of idle time before showing the popup.
        corfu-auto-delay 0.3)

  (defun my/toggle-corfu-auto ()
    "Toggle corfu inline auto-completion on/off."
    (interactive)
    (setq corfu-auto (not corfu-auto))
    (if corfu-auto
        (corfu-mode 1)  ; ensure it's on
      (corfu-quit))     ; close any open popup
    (message "Corfu auto-popup: %s" (if corfu-auto "ON" "OFF")))

  (map! :leader
        :desc "Toggle code suggestions"
        "t c" #'my/toggle-corfu-auto))

;; ============================================================================
;; WINDOW NAVIGATION
;; ============================================================================

;; Super (Cmd on macOS) + hjkl to move between windows
(map! :after evil
      :map override
      :nvi
      "s-h" #'evil-window-left
      "s-j" #'evil-window-down
      "s-k" #'evil-window-up
      "s-l" #'evil-window-right)

;; Leader prefix for visual/split shortcuts
(map! :leader
      (:prefix ("v" . "ltd visual")
       :desc "Vertical split with new buffer"   "v" #'evil-window-vnew
       :desc "Horizontal split with new buffer" "-" #'evil-window-new))


;; ============================================================================
;; LANGUAGE TOOLING
;; ============================================================================

;; Java — LSP via Eclipse JDT Language Server
;; JDT auto-downloads on first .java file open. Takes a minute. Be patient.
(after! lsp-java
  (setq lsp-java-java-path "/usr/bin/java"
        ;; Auto-organize imports on save (correct variable, was a typo before)
        lsp-java-save-action-organize-imports t
        ;; Show overloaded method signatures in completion
        lsp-java-completion-overwrite t
        ;; Enable Maven download sources so jump-to-definition works on
        ;; library code, not just .class headers
        lsp-java-maven-download-sources t))

;; Debug support for Java (DAP — like IntelliJ's debugger, but rougher).
;; Loads automatically when you open a Java file with lsp-mode active.
(after! dap-mode
  (require 'dap-java nil 'noerror))

;; Prisma schema files
(use-package! prisma-mode
  :mode "\\.prisma\\'")

;; ============================================================================
;; PROJECTILE — PROJECT ROOTS
;; ============================================================================

;; Scan ~/Developer up to 3 levels deep when running `SPC p d` (discover
;; projects). One unified path replaces the previous duplicate-ridden list.
(setq projectile-project-search-path '(("~/Developer/" . 3)))

;; ============================================================================
;; ORG — DIRECTORIES
;; ============================================================================

;; These must be set before org loads.
(setq org-directory "~/org/")

;; ============================================================================
;; ORG — CORE CONFIGURATION
;; ============================================================================

(after! org
  (setq
   ;; --- Startup & folding ---
   org-startup-folded 'content          ; show headings, hide body on open
   org-cycle-separator-lines 1

   ;; --- Editing behavior ---
   org-catch-invisible-edits  'show-and-error ; was org-fold-catch-invisible-edits in newer Org
   org-special-ctrl-a/e       t
   org-insert-heading-respect-content t
   org-M-RET-may-split-line   '((default . nil))
   org-return-follows-link    nil       ; RET doesn't follow links (use C-c C-o)

   ;; --- Visual ---
   org-hide-emphasis-markers  t         ; hide *bold* /italic/ markers
   org-pretty-entities        t         ; render \alpha as α, etc.
   org-ellipsis               "…"       ; folding indicator
   org-image-actual-width     '(600)    ; cap inline image width

   ;; --- Tags ---
   org-auto-align-tags        nil
   org-tags-column            0

   ;; --- Logging ---
   org-log-done               'time     ; timestamp when a TODO → DONE
   org-log-into-drawer        t         ; keep LOGBOOK tidy

   ;; --- TODO keywords ---
   ;; Kept intentionally light — your data shows ~13 checklist items/week.
   org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "DOING(g)" "WAIT(w@/!)" "|" "DONE(d@)" "CANCELLED(c@)"))

   org-todo-keyword-faces
   '(("NEXT"      . (:foreground "#fabd2f" :weight bold))
     ("DOING"     . (:foreground "#fe8019" :weight bold))
     ("WAIT"      . (:foreground "#83a598"))
     ("CANCELLED" . (:foreground "#928374" :strike-through t)))

   ;; --- Bullets ---
   org-list-demote-modify-bullet '(("-" . "-") ("+" . "-") ("*" . "-"))

   ;; --- Block-level linking ---
   org-id-link-to-org-use-id 'create-if-interactive-and-no-custom-id))

;; org-appear — reveal *bold* /italic/ =verbatim= markers when the cursor
;; enters them, re-hide on exit. Requires org-hide-emphasis-markers t (set above).
(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis   t    ; bold/italic/underline/verbatim
        org-appear-autolinks      t    ; reveal link syntax too
        org-appear-autosubmarkers t))  ; sub/superscript markers


;; SPC X → org-capture (single-key access)

(map! :leader "X" #'org-capture)

;; ----------------------------------------------------------------------------
;; Capture helpers
;; ----------------------------------------------------------------------------

(defun my/org-capture-song-sessions ()
  "Pick a song under * Songs in the capture file and move to its Sessions heading.
Creates the Sessions heading if the song doesn't have one yet."
  (let ((songs-pos (org-find-exact-headline-in-buffer "Songs")))
    (unless songs-pos
      (user-error "No * Songs heading here; add one with SPC X m n first"))
    (let* ((songs (org-with-point-at songs-pos
                    (let (acc)
                      (org-map-entries
                       (lambda () (push (org-get-heading t t t t) acc))
                       "LEVEL=2" 'tree)
                      (nreverse acc))))
           (song (completing-read "Song: " songs nil t)))
      (or (ignore-errors
            (goto-char (org-find-olp (list "Songs" song "Sessions") t)))
          (progn
            (goto-char (org-find-olp (list "Songs" song) t))
            (let ((stars (make-string (1+ (org-current-level)) ?*)))
              (org-end-of-subtree t t)
              (unless (bolp) (insert "\n"))
              (insert stars " Sessions\n")
              (forward-line -1)))))))

;; ----------------------------------------------------------------------------
;; Capture templates — SPC X (or SPC n n)
;; ----------------------------------------------------------------------------
;;   i  Inbox            not sure where it goes → inbox.org, sort on Sunday
;;   t  Task             → tasks.org * Inbox (the tasks tool's inbox)
;;   y  Someday / idea   → tasks.org * Ideas
;;   j  Journal          → journal.org, Year › Month › Day
;;   s  Sequence/how-to  → inbox.org with a Reference/Steps skeleton
;;   d  Dictionary term  → dictionary.org
;;   w  Work…
;;      g  Gig record    → work.org * Gigs
;;      c  Call/meeting  → work.org * Meetings
;;   m  Music…
;;      i  Music idea    → audio.org * Ideas
;;      n  New song      → audio.org * Songs (new song project)
;;      s  Song session  → audio.org * Songs › <song> › Sessions

(after! org
  (setq org-refile-targets '((org-agenda-files :maxlevel . 3))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil
        org-capture-templates
        '(;; --- Sort-later & tasks -------------------------------------------
          ("i" "Inbox (not sure where)" entry
           (file "inbox.org")
           "* %?\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n%i"
           :empty-lines 1)

          ("t" "Task" entry
           (file+headline "tasks.org" "Inbox")
           "* TODO %?\n:PROPERTIES:\n:ID:       %(org-id-new)\n:CREATED:  %U\n:END:\n")

          ("y" "Someday / idea" entry
           (file+headline "tasks.org" "Ideas")
           "* %?\n:PROPERTIES:\n:ID:       %(org-id-new)\n:CREATED:  %U\n:END:\n")

          ;; --- Notes with a known home --------------------------------------
          ("j" "Journal" entry
           (file+olp+datetree "journal.org")
           "* %U %?\n%i"
           :empty-lines 1)

          ("s" "Sequence / how-to" entry
           (file "inbox.org")
           "* %^{Title} :sequence:\n:PROPERTIES:\n:CAPTURED: %U\n:END:\n** Reference\n** Steps\n1. %?\n"
           :empty-lines 1)

          ("d" "Dictionary term" entry
           (file "dictionary.org")
           "* %^{Term}\n%?"
           :empty-lines 1)

          ;; --- Work ---------------------------------------------------------
          ("w" "Work…")

          ("wg" "Gig record" entry
           (file+headline "work.org" "Gigs")
           "* %^{Event} :record:%^{Client|418|tallen|ltd}:\n%^t--%^t\n** Details\n%?\n** Schedule\n** Notes\n"
           :empty-lines 1)

          ("wc" "Call / meeting" entry
           (file+headline "work.org" "Meetings")
           "* %^{Who / about} :meeting:%^{Client|418|tallen|ltd}:\n%U\n** Notes\n%?\n** Follow-ups\n"
           :empty-lines 1)

          ;; --- Music --------------------------------------------------------
          ("m" "Music…")

          ("mi" "Music idea" entry
           (file+headline "audio.org" "Ideas")
           "* %? :idea:\n:PROPERTIES:\n:CAPTURED: %U\n:END:\nKey: \nBPM: \nVibe: "
           :empty-lines 1)

          ("mn" "New song project" entry
           (file+headline "audio.org" "Songs")
           "* %^{Song title}\n:PROPERTIES:\n:KEY:      %^{Key}\n:BPM:      %^{BPM}\n:DAW:      %^{DAW|Ableton Live|Logic Pro|Bitwig Studio}\n:STATUS:   %^{Status|idea|writing|arranging|mixing|done}\n:CREATED:  %U\n:END:\n** Project files\n%?\n** Sessions\n** Arrangement\n** Mix notes\n** To do\n"
           :empty-lines 1)

          ("ms" "Song session log" entry
           (file+function "audio.org" my/org-capture-song-sessions)
           "* %U %^{Session focus}\n- File/version: \n- Did: %?\n- Next: \n"
           :empty-lines 1))))

;; ============================================================================
;; ORG — AGENDA
;; ============================================================================
;; Scoped to inbox + projects + journal so random concept TODOs don't pollute.

;; Scan every top-level .org file in ~/org/ for TODOs and timestamps.
;; Non-recursive — skips learn/ and the dead roam/ folder. New topic files
;; added to ~/org/ show up in the agenda automatically, no config change.

(setq org-agenda-files
      (directory-files "~/org/" t "\\.org$"))

(after! org
  (setq org-agenda-custom-commands
        '(("d" "Dashboard"
           ((agenda "" ((org-agenda-span 'day)))
            (todo "NEXT" ((org-agenda-overriding-header "Next actions")))
            (todo "WAIT" ((org-agenda-overriding-header "Waiting on")))
            (alltodo "" ((org-agenda-overriding-header "All TODOs"))))))))

;; ============================================================================
;; ORG — ORG-MODERN (visual polish)
;; ============================================================================

;; org-modern — modern styling for headings, keywords, tags, tables, blocks.
;; Replaces org-superstar (disabled in packages.el). The core org settings
;; above (org-tags-column 0, org-hide-emphasis-markers, org-ellipsis) are
;; already the recommended org-modern companions.
(after! org-modern
  (setq org-modern-list   '((?- . "•")    ; hyphen bullets → round dot
                            (?+ . "◦")    ; plus bullets → hollow dot
                            (?* . "▸"))   ; star bullets → triangle
        org-modern-hide-stars nil          ; keep leading stars visible
        org-modern-table t)                ; prettify tables
  ;; Turn org-modern on for every org buffer.
  (global-org-modern-mode))

;; A little line-spacing helps org-modern's tag pills and boxes breathe.
;; (Recommended by the org-modern author: 0.1–0.4.)
(add-hook 'org-mode-hook (lambda () (setq-local line-spacing 0.2)))

;; ============================================================================
;; ORG — AUTO-INSERT HEADER FOR NEW FILES
;; ============================================================================

;; Auto-insert a header into new .org files via Doom's file-templates module.
;; The actual template lives at ~/.config/doom/snippets/org-mode/__
;; (Doom's file-templates supersede vanilla auto-insert, so we use its system.)
(set-file-template! "\\.org$" :trigger "__" :mode 'org-mode)

;; KEYBINDINGS IN ORG BUFFERS
;; ============================================================================

;; Smart Return: insert new list item inside a list, normal newline otherwise
;; Smart Return: insert new list item inside a list, normal newline otherwise
(defun my/org-return-dwim ()
  "In a list, create new item. Otherwise, normal newline."
  (interactive)
  (if (org-in-item-p)
      (org-insert-item)
    (org-return)))

(map! :after org
      :map org-mode-map
      :i "RET"      #'my/org-return-dwim
      :i "<return>" #'my/org-return-dwim)

;; Indent / Unindent headings and list items with Meta-brackets or Cmd-brackets
(map! :after org
      :map org-mode-map
      :ni "M-]" #'org-metaright   ; demote / indent
      :ni "M-[" #'org-metaleft    ; promote / unindent
      :ni "s-]" #'org-metaright   ; macOS: Cmd+]
      :ni "s-[" #'org-metaleft)   ; macOS: Cmd+[

;; Smart heading converter: typing "- ** SPC" converts the bullet to a heading
(defun my/org-maybe-convert-to-heading ()
  "If current line is a bullet followed by asterisk(s) and a space,
convert it to an org heading of the appropriate level."
  (interactive)
  (let* ((line-start (line-beginning-position))
         (line-text  (buffer-substring-no-properties line-start (point))))
    (when (string-match "^[[:space:]]*[-+]\\s-+\\(\\*+\\) $" line-text)
      (let ((stars (match-string 1 line-text)))
        (delete-region line-start (point))
        (insert (concat stars " "))))))

(map! :after org
      :map org-mode-map
      :i "SPC" (lambda ()
                 (interactive)
                 (my/org-maybe-convert-to-heading)
                 (let* ((line-text (buffer-substring-no-properties
                                    (line-beginning-position) (point)))
                        (converted (string-match "^\\*+ $" line-text)))
                   (unless converted
                     (insert " ")))))


;; ============================================================================
;; ORG — IMAGE DRAG, DROP & PASTE (org-download)
;; ============================================================================
;; Drag an image into an org buffer, or paste/screenshot one, and it's saved
;; to the attachments dir and linked inline.

(use-package! org-download
  :after org
  :config
  (setq org-download-method            'directory
        org-download-image-dir         "~/org/attachments/"   ; de-roamed path
        org-download-heading-lvl       nil
        org-download-screenshot-method "screencapture -i %s"))  ; macOS

;; ============================================================================
;; ORG — BLOCK-LEVEL LINKING (copy ID link to heading)
;; ============================================================================

(defun my/org-id-get-create-and-copy ()
  "Create an ID for the current heading and copy an org-link to clipboard."
  (interactive)
  (let ((id (org-id-get-create)))
    (kill-new (format "[[id:%s][%s]]"
                      id
                      (org-get-heading t t t t)))
    (message "Link copied: %s" (car kill-ring))))

(map! :leader
      :desc "Copy link to heading"
      "n l" #'my/org-id-get-create-and-copy)

;; ============================================================================
;; REFERENCE FILE SHORTCUTS (CSS / Java / React)
;; ============================================================================

;; Fuzzy-find a reference file under DIR using Doom's default file picker
;; (Vertico + find-file). Replaces the old Helm-based version.
(defun my/ref-find-in (dir)
  "Open a file picker rooted at DIR."
  (let ((default-directory (expand-file-name dir)))
    (call-interactively #'find-file)))

(defun my/ref-css   () (interactive) (my/ref-find-in "~/.config/ref/css/"))
(defun my/ref-java  () (interactive) (my/ref-find-in "~/.config/ref/java/"))
(defun my/ref-react () (interactive) (my/ref-find-in "~/.config/ref/ts/react/"))

(map! :leader
      (:prefix ("r" . "ltd reference")
       :desc "CSS references"  "c" #'my/ref-css
       :desc "Java references" "j" #'my/ref-java
       :desc "React TS refs"   "r" #'my/ref-react))


;; ============================================================================
;; CUSTOM UTILITIES
;; ============================================================================

(defun my/copy-buffer-to-clipboard ()
  "Copy the entire current buffer to the clipboard."
  (interactive)
  (kill-new (buffer-string))
  (message "Buffer copied to clipboard"))

(map! :leader
      :desc "Copy entire buffer"
      "m y" #'my/copy-buffer-to-clipboard)

(defun +my/delete-no-clipboard ()
  "Delete the current line, or the visual selection, without touching the kill ring or clipboard."
  (interactive)
  (if (evil-visual-state-p)
      (let ((beg (region-beginning))
            (end (region-end))
            (type (evil-visual-type)))
        (evil-delete beg end type ?_)
        (evil-normal-state))
    (evil-delete (line-beginning-position)
                 (line-beginning-position 2)
                 'line ?_)))

(map! :leader
      :desc "Delete line/region (no clipboard)"
      :nv "v d" #'+my/delete-no-clipboard)

(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autolinks t
        org-appear-trigger 'manual)
  (add-hook 'org-mode-hook
            (lambda ()
              (add-hook 'evil-insert-state-entry-hook #'org-appear-manual-start nil t)
              (add-hook 'evil-insert-state-exit-hook  #'org-appear-manual-stop  nil t))))

;; ============================================================================
;; CLAUDE CODE
;; ============================================================================

(use-package! claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools
