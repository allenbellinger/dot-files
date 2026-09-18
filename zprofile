# ~/.zprofile -- tracked in the dotfiles repo as ~/.config/zprofile and
# symlinked into place by bootstrap.sh. Edit this file, not the symlink target.
#
# Login-shell setup only. Interactive configuration lives in ~/.config/zshrc.

eval "$(/opt/homebrew/bin/brew shellenv)"

# Use Homebrew OpenJDK 25 globally
export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
