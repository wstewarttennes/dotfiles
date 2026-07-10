#!/usr/bin/env bash
# macOS system tweaks. Run manually — NOT invoked by install.sh.
#   ./macos/defaults.sh
# Re-runnable. Some changes need a logout/restart to fully apply.
set -euo pipefail
[[ "$OSTYPE" == darwin* ]] || { echo "macOS only."; exit 1; }

echo "Applying macOS defaults..."

# --- Keyboard: fast key repeat, no press-and-hold accent popup ---
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# --- Text: disable auto-correct / smart quotes (annoying for coding) ---
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# --- Finder: show extensions, path/status bar, POSIX path in title ---
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"   # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# --- Screenshots: PNG into ~/Screenshots, no drop shadow ---
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# --- Dock: autohide, faster, no recent apps ---
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false

# --- Misc quality of life ---
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true  # no .DS_Store on network
defaults write NSGlobalDomain com.apple.springing.enabled -bool true          # spring-load folders

echo "Restarting affected apps..."
for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1 || true; done
echo "Done. Some settings apply after logout/restart."
