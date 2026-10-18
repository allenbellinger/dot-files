# ~/.zshrc -- tracked in the dotfiles repo as ~/.config/zshrc and symlinked
# into place by bootstrap.sh. Edit this file, not the symlink target.
#
# Node is managed exclusively by fnm. Homebrew's `node` formula is present only
# because the brew-installed language servers depend on it; it is deliberately
# kept off PATH so `node` always means "the fnm-selected version".

# uv tool shims (nginx-language-server, nginxfmt)
export PATH="$HOME/.local/bin:$PATH"

autoload -Uz compinit && compinit

eval "$(zellij setup --generate-auto-start zsh)"

eval "$(fnm env --use-on-cd --shell zsh)"

export HOMEBREW_NO_ENV_HINTS=1

# Artifactory credentials live in ~/.zsh_secrets (chmod 600, not in the
# dotfiles repo). Everything below is derived from that single pair.
if [[ -f "$HOME/.zsh_secrets" ]]; then
  source "$HOME/.zsh_secrets"
else
  print -u2 "warning: ~/.zsh_secrets missing -- Artifactory auth unavailable"
fi

# uv: index name below must match ~/.config/uv/uv.toml
export UV_INDEX_JBH_ARTIFACTORY_PYPI_USERNAME="$ARTIFACTORY_USERNAME"
export UV_INDEX_JBH_ARTIFACTORY_PYPI_PASSWORD="$ARTIFACTORY_PASSWORD"

# Route fnm Node downloads through JBHunt Artifactory
export FNM_NODE_DIST_MIRROR="https://${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}@artifactory-prd.jbhunt.com/artifactory/generic-node-dist-remote"

# Angular CLI autocompletion (guarded: `ng` is absent until bootstrap runs)
if (( $+commands[ng] )); then
  source <(ng completion script)
fi

# pnpm -- installed via Homebrew, not corepack. `corepack disable` is run by
# bootstrap.sh so fnm's corepack shims don't shadow the brew binary.
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
