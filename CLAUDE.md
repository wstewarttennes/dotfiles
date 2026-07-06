# CLAUDE.md

Guidance for Claude Code when working in this repo.

## What this is

Personal dotfiles managed with **GNU Stow**. Every top-level directory is a stow
*package* whose internal tree mirrors `$HOME`. Files here are symlinked into the
home directory, so `~/.config/ghostty/config` is a symlink pointing back to
`ghostty/.config/ghostty/config` in this repo.

## The one rule that matters

**Edit files inside this repo, never through the live symlink target's real
path elsewhere.** Since the home-directory paths are symlinks INTO this repo,
editing `~/.config/ghostty/config` edits the repo file — that's fine and
expected. But if a home path turns out to be a *real file* (not yet stowed),
don't edit it in place: move it into the matching package and `stow` it so it
becomes tracked. The goal is that all config lives here and `$HOME` only holds
symlinks.

Note: the Edit tool refuses to write through a symlink. When a `~/...` path is a
symlink into this repo, resolve it with `readlink -f` and edit the real repo file
at `~/dev/dotfiles/<package>/...`.

## Adding a config to the repo

1. Recreate the file's `$HOME`-relative path inside a package dir
   (e.g. `~/.config/bat/config` → `bat/.config/bat/config`).
2. `stow --no-folding -t "$HOME" <package>` to create the symlink
   (`--no-folding` links individual files rather than replacing a whole
   `$HOME` directory with one symlink — important for dirs like `~/.claude`
   and `~/.config/git` that also contain untracked state).
3. Commit.

## Never track secrets or runtime state

Keep these OUT of the repo (they hold tokens, keys, or per-machine state):
`~/.claude.json`, `~/.aws`, `~/.ssh`, `~/.config/homeassistant`,
`~/.mcp-auth`, `~/.goblin`, `~/.config/cagent`, `~/.tmux` (installed plugins).
From `~/.claude`, track ONLY `settings.json` and `commands/` — never
`sessions/`, `history.jsonl`, `projects/`, `daemon*`, caches, or `settings.local.json`.
Scan any new file for keys/tokens before committing.

## Cross-platform

This machine is macOS (`darwin`). Many packages (`hyprland`, `i3`, `waybar`,
`polybar`, `picom`, `rofi`, `xresources`, `screenlayout`, `backgrounds`) are
Linux/WM-only and are not stowed here. `install.sh` selects the right set per OS.

## Committing

When the user asks to push, commit only the files relevant to the change — this
repo often has unrelated dirty state (e.g. `nvim/lazy-lock.json`,
`tmux/.tmux.conf`). Don't sweep those in.
