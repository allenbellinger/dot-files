# ~/.zprofile -- tracked in the dotfiles repo as ~/.config/zprofile and
# symlinked into place by bootstrap.sh. Edit this file, not the symlink target.
#
# Login-shell setup only. Interactive configuration lives in ~/.config/zshrc.

eval "$(/opt/homebrew/bin/brew shellenv)"

# Added by Toolbox App
export PATH="$PATH:$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
