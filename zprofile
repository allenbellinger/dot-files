# ~/.zprofile -- tracked in the dotfiles repo as ~/.config/zprofile and
# symlinked into place by bootstrap.sh. Edit this file, not the symlink target.
#
# Login-shell setup only. Interactive configuration lives in ~/.config/zshrc.

eval "$(/opt/homebrew/bin/brew shellenv)"

printf '\n# Use Homebrew OpenJDK 25 globally\nexport JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"\nexport PATH="$JAVA_HOME/bin:$PATH"\n' >> ~/.config/zprofile

# Use Homebrew OpenJDK 25 globally
export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# Use Homebrew OpenJDK 25 globally
export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
