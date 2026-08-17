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
#   - Treesitter parsers (compiled automatically; needs tree-sitter-cli)
#   - jdtls/lombok/java-test/openjdk (via nvim-java, into stdpath('data')/nvim-java)
#
# LSP servers and formatters are installed by this script (Homebrew/uv/pnpm/rustup),
# not by a Neovim plugin. `:checkhealth` (see nvim/lua/health.lua) lists every
# binary this script is responsible for.
#
# Install-source preference, in order:
#   1. Homebrew  -- anything with a formula
#   2. pnpm/uv   -- language-ecosystem tools with no formula
#   3. npm       -- last resort (currently nothing; global npm installs are
#                   unmanaged and silently go stale)
#
# Two servers are resolved per-project from node_modules/.bin when a project
# ships them, falling back to the pnpm globals below:
# @angular/language-server and @stylelint/language-server.
#
# Node policy: fnm owns the user-facing Node. Homebrew's `node` formula is
# installed only as a dependency of the brew language servers and is kept off
# PATH, so `node` always means "the fnm-selected version".
#
# Shell: ~/.zshrc and ~/.zprofile are symlinks to ~/.config/{zshrc,zprofile},
# both tracked in this repo.
#
# Optional:
#   - nvim/init-local.lua: machine-specific Neovim overrides (not tracked in git)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
eval "$(brew shellenv)"

# --- Homebrew packages ---
# Scope: editor + dev toolchain. Cloud/infra/db tooling (azure-cli, colima,
# docker, maven, msodbcsql18, gcloud-cli, git-credential-manager) is installed
# per-machine as needed and deliberately left out.
#
# `node` is NOT listed: it arrives as a dependency of the language servers
# below, and fnm provides the version actually used for development.
BREW_PACKAGES=(
  # --- core CLI ---
  git         # Plugin management, lazy.nvim bootstrap
  wget        # General fetching
  ripgrep     # snacks.picker grep
  fd          # snacks.picker files
  bat         # Syntax-highlighted file previews
  neovim      # Editor (0.12+, see nvim/lua/health.lua)
  zellij      # Terminal multiplexer

  # --- editor support binaries ---
  tree-sitter-cli  # nvim-treesitter (main branch) compiles parsers with this
  diff-so-fancy    # tiny-code-action backend = 'diffsofancy'
  git-delta        # Git pager / diff rendering
  bacon            # Rust background checker (nvim-bacon)
  opencode         # AI coding agent

  # --- Node toolchain ---
  fnm          # Node version manager (owns the user-facing `node`)
  pnpm         # Package manager + global editor tooling installs
  angular-cli  # `ng`
  nx           # `nx`

  # --- Python toolchain ---
  uv          # Python tool installer (nginx language server / formatter)

  # --- Rust toolchain ---
  rustup      # rustc/cargo/rust-analyzer/rustfmt/clippy

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
  if brew list --formula "$pkg" &>/dev/null; then
    ok "  $pkg: already installed"
  else
    info "  Installing $pkg..."
    brew install "$pkg"
  fi
done

# --- Homebrew casks ---
BREW_CASKS=(
  ghostty              # Terminal emulator
  font-jetbrains-mono  # Ghostty font
)

info "Installing Homebrew casks..."
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask "$cask" &>/dev/null; then
    ok "  $cask: already installed"
  else
    info "  Installing $cask..."
    brew install --cask "$cask"
  fi
done

# --- Shell config (~/.zshrc, ~/.zprofile -> ~/.config/) ---
info "Linking shell config..."
for rc in zprofile zshrc; do
  target="$DOTFILES/$rc"
  link="$HOME/.$rc"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
    ok "  ~/.$rc: already symlinked"
    continue
  fi
  if [ -e "$link" ]; then
    backup="$link.pre-bootstrap"
    warn "  Existing ~/.$rc backed up to $backup"
    mv "$link" "$backup"
  fi
  ln -sfn "$target" "$link"
  ok "  ~/.$rc -> $target"
done

# uv installs shims into ~/.local/bin, which ~/.config/zshrc puts on PATH.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# --- Java (for nvim-java / jdtls) ---
if ! command -v java &>/dev/null; then
  info "Installing Java (Eclipse Temurin)..."
  brew install --cask temurin
else
  ok "Java: already installed ($(java -version 2>&1 | head -1))"
fi

# --- Rust (rust-analyzer, rustfmt, clippy) ---
info "Ensuring Rust toolchain..."
# Same SIGPIPE caveat as the fnm block below: capture, then match.
rust_toolchains="$(rustup toolchain list 2>/dev/null || true)"
case "$rust_toolchains" in
  stable*) ok "  stable toolchain: already installed" ;;
  *)
    info "  Installing stable toolchain..."
    rustup default stable
    ;;
esac
rustup component add rust-analyzer rustfmt clippy 2>/dev/null || true

# --- Node (via fnm) ---
# Homebrew's node is a dependency of the language servers only; fnm supplies the
# `node` used for development. corepack is disabled so its pnpm/yarn shims don't
# shadow the Homebrew pnpm installed above.
info "Ensuring fnm-managed Node..."
eval "$(fnm env --shell bash)"
# NOTE: no pipe into `grep -q` here. `grep -q` exits on first match, fnm then
# dies of SIGPIPE, and `set -o pipefail` turns that into a false "not installed"
# result -- which then tries a network install and aborts the whole script.
fnm_versions="$(fnm list 2>/dev/null || true)"
case "$fnm_versions" in
  *v22.*) ok "  Node 22: already installed" ;;
  *)
    info "  Installing Node 22..."
    # Downloads route through Artifactory via FNM_NODE_DIST_MIRROR, which needs
    # credentials from ~/.zsh_secrets. Don't abort the rest of the bootstrap if
    # they aren't in place yet.
    if ! fnm install 22; then
      warn "  Node 22 install failed -- fill in ~/.zsh_secrets, then run: fnm install 22"
    fi
    ;;
esac

fnm_versions="$(fnm list 2>/dev/null || true)"
case "$fnm_versions" in
  *v22.*)
    fnm default 22
    fnm use 22
    ok "  Node default: $(node --version 2>/dev/null)"
    ;;
esac

if command -v corepack &>/dev/null; then
  info "  Disabling corepack shims (pnpm comes from Homebrew)..."
  corepack disable 2>/dev/null || true
fi

# --- Python-based language tooling (via uv) ---
# uv needs an index config of its own (pip is not installed and uv does not
# read pip.conf). Credentials stay out of this file -- uv resolves them from
# UV_INDEX_JBH_ARTIFACTORY_PYPI_{USERNAME,PASSWORD} in the shell, matching the
# index name below.
UV_CONFIG="$HOME/.config/uv/uv.toml"
if [ ! -f "$UV_CONFIG" ]; then
  info "Writing $UV_CONFIG..."
  mkdir -p "$(dirname "$UV_CONFIG")"
  cat > "$UV_CONFIG" <<'UVEOF'
[[index]]
name = "jbh-artifactory-pypi"
url = "https://artifactory-prd.jbhunt.com/artifactory/api/pypi/pypi-repos/simple"
default = true
UVEOF
else
  ok "uv index config: already present"
fi

info "Ensuring uv tools..."
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
export PNPM_HOME="${PNPM_HOME:-$HOME/Library/pnpm}"
if [ ! -d "$PNPM_HOME" ]; then
  info "  Running pnpm setup..."
  SHELL="${SHELL:-/bin/zsh}" pnpm setup
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
  if [ -x "$PNPM_HOME/bin/$bin_name" ]; then
    ok "  $bin_name: already installed"
  else
    info "  Installing $spec..."
    pnpm add -g "$spec"
  fi
done

# --- Secrets ---
# Credentials are never stored in this repo. ~/.zsh_secrets (chmod 600, outside
# version control) is the single source; ~/.config/zshrc sources it and derives
# the uv / fnm / npm variables from it.
if [ ! -f "$HOME/.zsh_secrets" ]; then
  info "Creating ~/.zsh_secrets template..."
  cat > "$HOME/.zsh_secrets" <<'SECEOF'
# Artifactory credentials -- the ONLY file on this machine holding secrets.
# Outside version control. Sourced by ~/.config/zshrc. Keep chmod 600.
export ARTIFACTORY_USERNAME=""
export ARTIFACTORY_PASSWORD=""
export ARTIFACTORY_NPM_TOKEN=""
SECEOF
  chmod 600 "$HOME/.zsh_secrets"
  warn "  Fill in ~/.zsh_secrets before using uv, npm, pnpm or fnm."
else
  ok "~/.zsh_secrets: already present"
fi

# --- Summary ---
echo ""
ok "All dependencies installed!"
echo ""
echo "Next steps:"
echo "  1. Open Ghostty (or run: exec zsh) to pick up the new ~/.zshrc"
echo "  2. Run: nvim"
echo "     - lazy.nvim auto-installs all plugins on first launch"
echo "     - Treesitter compiles parsers on first launch"
echo "     - nvim-java downloads jdtls on first Java file"
echo "     - Run :checkhealth to confirm all LSP/formatter binaries are found"
echo "  3. For Angular/stylelint projects, add to devDependencies:"
echo "       @angular/language-server   @stylelint/language-server"
echo "  4. (Optional) Create ~/.config/nvim/init-local.lua for machine-specific settings"
echo ""
