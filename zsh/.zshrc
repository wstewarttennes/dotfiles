# ~/.zshrc — interactive shell config (managed in ~/dev/dotfiles)
# Login-shell / env bootstrap (Homebrew shellenv) lives in ~/.zprofile.

# --- PATH ---
export PATH="$HOME/.local/bin:$PATH"

# --- Editor ---
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim" VISUAL="nvim"
  alias vim="nvim" vi="nvim"
else
  export EDITOR="vim" VISUAL="vim"
fi

# --- History ---
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt SHARE_HISTORY          # share history across live sessions
setopt HIST_IGNORE_ALL_DUPS   # drop older duplicate of a repeated command
setopt HIST_IGNORE_SPACE      # a leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY        # record timestamps

# --- Navigation / QoL ---
setopt AUTO_CD                # `foo/` cds into ./foo
setopt AUTO_PUSHD             # cd pushes onto the dir stack
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
setopt NO_BEEP

# --- Completion ---
autoload -Uz compinit && compinit -C
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive
zstyle ':completion:*' menu select

# --- Aliases: core ---
alias ll="ls -lah"
alias la="ls -A"
alias l="ls -CF"
alias ..="cd .."
alias ...="cd ../.."
alias grep="grep --color=auto"
alias reload="source ~/.zshrc"
alias dotfiles="cd ~/dev/dotfiles"

# --- Aliases: git ---
alias g="git"
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline --graph --decorate -20"

# --- Optional tools (only wire up if installed) ---
command -v bat     >/dev/null 2>&1 && alias cat="bat --paging=never"
command -v eza     >/dev/null 2>&1 && { alias ls="eza"; alias ll="eza -lah --git"; }
command -v lazygit >/dev/null 2>&1 && alias lg="lazygit"
command -v fzf     >/dev/null 2>&1 && source <(fzf --zsh) 2>/dev/null
command -v zoxide  >/dev/null 2>&1 && eval "$(zoxide init zsh)"
command -v direnv  >/dev/null 2>&1 && eval "$(direnv hook zsh)"
command -v atuin   >/dev/null 2>&1 && eval "$(atuin init zsh)"

# --- Prompt (keep last) ---
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# --- Local, untracked overrides (secrets, machine-specific) ---
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
