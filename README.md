# dotfiles

Personal dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Stowing a package symlinks its files into your home directory, so the
real file lives here in the repo and `~` just points at it. Edit the file at
either path — you're always editing the repo copy.

```
ghostty/.config/ghostty/config   ->   ~/.config/ghostty/config
```

## Setup on a new machine

```sh
# 1. Install GNU Stow
brew install stow          # macOS
# sudo apt install stow    # Debian/Ubuntu

# 2. Clone into ~/dev/dotfiles (the symlink paths assume this location)
git clone <this-repo-url> ~/dev/dotfiles
cd ~/dev/dotfiles

# 3. Symlink everything appropriate for this machine
./install.sh
```

`install.sh` is idempotent and picks the right packages per OS (macOS vs Linux).

## Manual stow / unstow

```sh
stow -t "$HOME" ghostty          # link one package
stow -R -t "$HOME" ghostty       # re-link after adding files to it
stow -D -t "$HOME" ghostty       # unlink (remove the symlinks)
stow --adopt -t "$HOME" ghostty  # pull an existing real file INTO the repo, then link
```

Always pass `-t "$HOME"` — Stow's default target is the parent of the current
directory, which is wrong here.

## Packages

| Package        | Links to                          | Platform |
|----------------|-----------------------------------|----------|
| `zsh`          | `~/.zshrc`, `~/.zprofile`         | all      |
| `git`          | `~/.config/git/ignore`            | all      |
| `claude`       | `~/.claude/settings.json`, `~/.claude/commands/` | all |
| `ghostty`      | `~/.config/ghostty/`              | macOS/Linux |
| `alacritty`    | `~/.config/alacritty/`            | all      |
| `nvim`         | `~/.config/nvim/`                 | all      |
| `tmux`         | `~/.tmux.conf`                    | all      |
| `starship`     | `~/.config/starship.toml`         | all      |
| `hyprland`     | `~/.config/hypr/`                 | Linux    |
| `i3`           | `~/.config/i3/`                   | Linux    |
| `waybar`       | `~/.config/waybar/`               | Linux    |
| `polybar`      | `~/.config/polybar/`              | Linux    |
| `picom`        | `~/.config/picom/`                | Linux    |
| `rofi`         | `~/.config/rofi/`                 | Linux    |
| `xresources`   | `~/.Xresources`                   | Linux    |
| `screenlayout` | `~/.screenlayout/`                | Linux    |
| `backgrounds`  | wallpapers                        | Linux    |

## Adding a new config

1. Move the real file into a package mirroring its `$HOME` path, e.g.
   `mkdir -p bat/.config/bat && mv ~/.config/bat/config bat/.config/bat/config`
2. Link it: `stow -t "$HOME" bat`
3. Commit.

Shortcut for a file that already exists in `$HOME`: create the package dir, then
`stow --adopt -t "$HOME" <package>` moves the real file into the repo and links it.

## What is intentionally NOT tracked

Secrets and machine-local state stay out of the repo: `~/.claude.json`,
`~/.aws`, `~/.ssh`, `~/.config/homeassistant`, `~/.mcp-auth`, `~/.goblin`, tmux
plugins under `~/.tmux`. Only `settings.json` and `commands/` are tracked from
`~/.claude` — never the sessions/history/cache.
