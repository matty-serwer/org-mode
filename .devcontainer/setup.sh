#!/usr/bin/env bash
set -eu

# Emacs (terminal build) plus the tools Doom expects
sudo apt-get update
sudo apt-get install -y emacs-nox ripgrep fd-find

# Doom Emacs
git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
~/.config/emacs/bin/doom install --force

# Notes live in the repo; expose them at ~/org
ln -sfn /workspaces/org-mode ~/org

# Put the doom command on PATH
echo 'export PATH="$HOME/.config/emacs/bin:$PATH"' >>~/.bashrc
