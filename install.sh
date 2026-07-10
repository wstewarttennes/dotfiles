#!/usr/bin/env bash
# Symlink dotfiles into $HOME with GNU Stow. Idempotent; safe to re-run.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# --- ensure stow is available ---
if ! command -v stow >/dev/null 2>&1; then
  echo "GNU Stow not found."
  if [[ "$OSTYPE" == darwin* ]] && command -v brew >/dev/null 2>&1; then
    echo "Installing via Homebrew..."; brew install stow
  elif command -v apt >/dev/null 2>&1; then
    echo "Installing via apt..."; sudo apt update && sudo apt install -y stow
  else
    echo "Please install GNU Stow, then re-run."; exit 1
  fi
fi

# --- packages ---
# Cross-platform: shells, git, gh, ssh, brew, claude, terminals, editor.
COMMON=(zsh git gh ssh brew claude alacritty ghostty nvim tmux starship)
# Linux-only: window managers, bars, X stuff, wallpapers.
LINUX=(hyprland i3 waybar polybar picom rofi xresources screenlayout backgrounds)

packages=("${COMMON[@]}")
if [[ "$OSTYPE" == linux* ]]; then
  packages+=("${LINUX[@]}")
fi

# Some target dirs already exist and hold untracked state; ensure parents exist
# and always use --no-folding so we link individual files, never whole dirs.
mkdir -p "$HOME/.claude/commands" "$HOME/.config/git" "$HOME/.config/gh"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/config.local" && chmod 600 "$HOME/.ssh/config.local"

echo "Stowing: ${packages[*]}"
for pkg in "${packages[@]}"; do
  [[ -d "$pkg" ]] || { echo "  skip $pkg (no such package)"; continue; }
  # --no-folding + -R (restow) is the safe, idempotent combination.
  if stow --no-folding -R -t "$HOME" "$pkg" 2>/tmp/stow_err_$$; then
    echo "  ok   $pkg"
  else
    echo "  WARN $pkg had conflicts:"; sed 's/^/       /' /tmp/stow_err_$$
    echo "       resolve (or 'stow --adopt -t \"\$HOME\" $pkg' to pull the real file in), then re-run."
  fi
done
rm -f /tmp/stow_err_$$

echo
echo "Done. Next steps (run manually):"
echo "  brew bundle --global            # install everything in ~/.Brewfile"
echo "  ./macos/defaults.sh             # apply macOS system tweaks (macOS only)"
