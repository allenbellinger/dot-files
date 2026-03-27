#!/usr/bin/env bash
# bootstrap.sh — Install all external dependencies for these dotfiles.
# Run once on a fresh macOS machine after cloning the repo to ~/.config.
#
# Usage:
#   git clone https://github.com/allenbellinger/dot-files.git ~/.config
#   cd ~/.config && chmod +x bootstrap.sh && ./bootstrap.sh
#
# What auto-installs on first Neovim launch (no action needed):
#   - lazy.nvim plugin manager (self-bootstraps)
#   - All Neovim plugins (via lazy.nvim)
#   - LSP servers, formatters, linters (via Mason)
#   - Treesitter parsers (compiled automatically)
#
# Optional:
#   - nvim/init-local.lua: machine-specific Neovim overrides (not tracked in git)

set -euo pipefail

info() { printf '\033[1;34m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m==> %s\033[0m\n' "$1"; }

# --- Xcode Command Line Tools (provides cc/clang, make, git) ---
if ! xcode-select -p &>/dev/null; then
  info "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Press any key after the installation completes."
  read -r -n 1
else
  ok "Xcode Command Line Tools: already installed"
fi

# --- Homebrew ---
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  ok "Homebrew: already installed"
fi

# --- Homebrew packages ---
BREW_PACKAGES=(
  neovim      # Editor (0.11+)
  node        # Required by Mason for LSP servers (angularls, ts_ls, eslint, etc.)
  ripgrep     # Telescope live_grep
  fd          # Telescope file finder
  bat         # Syntax-highlighted file previews (Telescope, etc.)
  chafa       # Image previews (telescope-media-files)
  git         # Plugin management, lazy.nvim bootstrap
  ghostty     # Terminal emulator
  zellij      # Terminal multiplexer
)

info "Installing Homebrew packages..."
for pkg in "${BREW_PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    ok "  $pkg: already installed"
  else
    info "  Installing $pkg..."
    brew install "$pkg"
  fi
done

# --- Ghostty font ---
info "Ensuring JetBrains Mono font..."
if brew list --cask font-jetbrains-mono &>/dev/null; then
  ok "  font-jetbrains-mono: already installed"
else
  brew install --cask font-jetbrains-mono
fi

# --- Java (for nvim-java / jdtls) ---
if ! command -v java &>/dev/null; then
  info "Installing Java (Eclipse Temurin)..."
  brew install --cask temurin
else
  ok "Java: already installed ($(java -version 2>&1 | head -1))"
fi

# --- Rust (for rust-analyzer, rustfmt, cargo) ---
if ! command -v rustc &>/dev/null; then
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
else
  ok "Rust: already installed ($(rustc --version))"
fi

info "Ensuring Rust components (rust-analyzer, rustfmt)..."
rustup component add rust-analyzer rustfmt 2>/dev/null || true

# --- Bacon (Rust background checker, used by nvim-bacon) ---
if ! command -v bacon &>/dev/null; then
  info "Installing bacon..."
  cargo install --locked bacon
else
  ok "bacon: already installed"
fi

# --- OpenCode ---
if ! command -v opencode &>/dev/null; then
  info "Installing OpenCode..."
  brew install opencode-ai/tap/opencode
else
  ok "OpenCode: already installed"
fi

# --- Summary ---
echo ""
ok "All dependencies installed!"
echo ""
echo "Next steps:"
echo "  1. Open Ghostty"
echo "  2. Run: nvim"
echo "     - lazy.nvim auto-installs all plugins on first launch"
echo "     - Mason auto-installs LSP servers, formatters, and linters"
echo "     - Treesitter compiles parsers on first launch"
echo "  3. (Optional) Create ~/.config/nvim/init-local.lua for machine-specific settings"
echo ""
