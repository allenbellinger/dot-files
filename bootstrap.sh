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
#   - Treesitter parsers (compiled automatically)
#   - jdtls/lombok/java-test/openjdk (via nvim-java, into stdpath('data')/nvim-java)
#
# LSP servers and formatters are installed by this script (Homebrew/uv/pnpm/rustup),
# not by a Neovim plugin.
#
# Install-source preference, in order:
#   1. Homebrew  -- anything with a formula
#   2. pnpm/uv   -- language-ecosystem tools with no formula
#   3. npm       -- last resort (currently nothing; global npm installs are
#                   unmanaged and silently go stale)
#
# One-off tools (e.g. sass-migrator, source-map-explorer) are deliberately NOT
# installed; run them on demand with `pnpm dlx <tool>`.
#
# Two servers are resolved per-project from node_modules/.bin when a project
# ships them, falling back to the pnpm globals below:
# @angular/language-server and @stylelint/language-server.
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
  node        # Runtime for the node-based language servers
  ripgrep     # Telescope live_grep
  fd          # Telescope file finder
  bat         # Syntax-highlighted file previews (Telescope, etc.)
  chafa       # Image previews (telescope-media-files)
  git         # Plugin management, lazy.nvim bootstrap
  ghostty     # Terminal emulator
  zellij      # Terminal multiplexer
  uv          # Python tool installer (nginx language server / formatter)

  # --- LSP servers & formatters (formerly installed via Mason) ---
  typescript-language-server    # ts_ls
  vscode-langservers-extracted  # eslint + jsonls (one formula, both servers)
  yaml-language-server          # yamlls
  lua-language-server           # lua_ls
  stylua                        # conform: lua
  stylelint                     # conform: css/scss/typescript
  prettierd                     # conform: js/ts/html/json/markdown/css
  ruff                          # ruff LSP + conform: python
  basedpyright                  # basedpyright LSP: python
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

# --- Python-based language tooling (via uv) ---
# uv installs shims into ~/.local/bin, which must be on PATH.
info "Ensuring ~/.local/bin is on PATH..."
mkdir -p "$HOME/.local/bin"
if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
  # shellcheck disable=SC2016
  printf '\n# uv tool shims\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.zshrc"
  ok "  added ~/.local/bin to ~/.zshrc"
else
  ok "  ~/.local/bin already on PATH"
fi
export PATH="$HOME/.local/bin:$PATH"

# uv needs an index config of its own (pip is not installed and uv does not
# read pip.conf). Credentials stay out of this file -- uv resolves them from
# UV_INDEX_JBH_ARTIFACTORY_PYPI_{USERNAME,PASSWORD} in ~/.zshrc, matching the
# index name below.
UV_CONFIG="$HOME/.config/uv/uv.toml"
if [ ! -f "$UV_CONFIG" ]; then
  info "  Writing $UV_CONFIG..."
  mkdir -p "$(dirname "$UV_CONFIG")"
  cat > "$UV_CONFIG" <<'UVEOF'
[[index]]
name = "jbh-artifactory-pypi"
url = "https://artifactory-prd.jbhunt.com/artifactory/api/pypi/pypi-repos/simple"
default = true
UVEOF
else
  ok "  uv index config: already present"
fi

for tool in nginx-language-server nginxfmt; do
  if command -v "$tool" &>/dev/null; then
    ok "  $tool: already installed"
  else
    info "  Installing $tool..."
    uv tool install "$tool"
  fi
done

# --- Node-based language servers (via pnpm global) ---
# These are editor tools, deliberately NOT added to project package.json files.
# Neovim prefers a project-local copy in node_modules/.bin when one exists and
# falls back to these globals otherwise.
info "Ensuring pnpm global language servers..."
if [ -z "${PNPM_HOME:-}" ]; then
  info "  Running pnpm setup..."
  SHELL="${SHELL:-/bin/zsh}" pnpm setup
  export PNPM_HOME="$HOME/Library/pnpm"
fi
export PATH="$PNPM_HOME/bin:$PATH"

# Supply-chain guard: refuse package versions published in the last 14 days.
# (npm's equivalent `min-release-age` miscomputes its cutoff, so the gate lives
# on pnpm, which is what we install node tooling with.)
if [ "$(pnpm config get minimumReleaseAge 2>/dev/null)" != "20160" ]; then
  info "  Setting pnpm minimumReleaseAge to 14 days..."
  pnpm config set minimumReleaseAge 20160
else
  ok "  pnpm minimumReleaseAge: already set"
fi

for spec in "@angular/language-server@22" "@stylelint/language-server"; do
  bin_name="ngserver"
  case "$spec" in
    *stylelint*) bin_name="stylelint-language-server" ;;
  esac
  if command -v "$bin_name" &>/dev/null; then
    ok "  $bin_name: already installed"
  else
    info "  Installing $spec..."
    pnpm add -g "$spec"
  fi
done

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
# --- Secrets ---
# Credentials are never stored in this repo. ~/.zsh_secrets (chmod 600, outside
# version control) is the single source; ~/.zshrc sources it and derives the
# uv / fnm / npm variables from it.
if [ ! -f "$HOME/.zsh_secrets" ]; then
  info "Creating ~/.zsh_secrets template..."
  cat > "$HOME/.zsh_secrets" <<'SECEOF'
# Artifactory credentials -- the ONLY file on this machine holding secrets.
# Outside version control. Sourced by ~/.zshrc. Keep chmod 600.
export ARTIFACTORY_USERNAME=""
export ARTIFACTORY_PASSWORD=""
export ARTIFACTORY_NPM_TOKEN=""
SECEOF
  chmod 600 "$HOME/.zsh_secrets"
  warn "  Fill in ~/.zsh_secrets before using uv, npm, pnpm or fnm."
else
  ok "~/.zsh_secrets: already present"
fi

echo "Next steps:"
echo "  1. Open Ghostty"
echo "  2. Run: nvim"
echo "     - lazy.nvim auto-installs all plugins on first launch"
echo "     - Treesitter compiles parsers on first launch"
echo "     - nvim-java downloads jdtls on first Java file"
echo "     - Run :checkhealth to confirm all LSP/formatter binaries are found"
echo "  3. For Angular/stylelint projects, add to devDependencies:"
echo "       @angular/language-server   @stylelint/language-server"
echo "  4. (Optional) Create ~/.config/nvim/init-local.lua for machine-specific settings"
echo ""
