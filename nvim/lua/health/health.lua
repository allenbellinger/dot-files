--[[
--
-- Healthcheck for tooling this config expects on PATH but does not install.
-- Everything here comes from bootstrap.sh (Homebrew / uv / pnpm / rustup),
-- never from a Neovim plugin.
--
-- Deliberately scoped: `conform.nvim` verifies the formatters it drives, so
-- those are omitted here -- but note it is lazy-loaded on `BufWritePre`, so its
-- section is absent from `:checkhealth` until you save a file.
--
-- Language server binaries are NOT covered elsewhere: `:checkhealth vim.lsp`
-- prints each enabled configuration but never checks whether its `cmd` is
-- executable, and `nvim-lspconfig`'s healthcheck now defers to `vim.lsp`
-- entirely. So every server binary this config enables is listed below.
--
-- `lazy.nvim` and `vim.health` cover the Neovim version and the
-- git/make/unzip/rg basics, so those are omitted too.
--
-- Run with `:checkhealth` (this appears as the `health` section) or
-- `:checkhealth health`. Note the latter also matches Neovim's builtin
-- `vim.health`, so both sections are produced.
--
--]]

local check_language_tooling = function()
  local tools = {
    -- Language servers. `vim.lsp` lists these but never checks the binary.
    ['typescript-language-server'] = 'brew install typescript-language-server',
    ['vscode-eslint-language-server'] = 'brew install vscode-langservers-extracted',
    ['vscode-json-language-server'] = 'brew install vscode-langservers-extracted',
    ['yaml-language-server'] = 'brew install yaml-language-server',
    ['lua-language-server'] = 'brew install lua-language-server',
    ['basedpyright-langserver'] = 'brew install basedpyright',
    ['ruff'] = 'brew install ruff', -- ruff LSP (conform covers ruff_format)

    -- Started via a `cmd` function in lua/plugins/lsp.lua, so they are doubly
    -- invisible: no plain `cmd` string for anything else to inspect.
    ['ngserver'] = 'pnpm add -g @angular/language-server',
    ['stylelint-language-server'] = 'pnpm add -g @stylelint/language-server',

    -- uv-installed into ~/.local/bin; missing if that dir fell off PATH.
    ['nginx-language-server'] = 'uv tool install nginx-language-server',
    ['nginxfmt'] = 'uv tool install nginxfmt',

    -- rustup components, not Homebrew formulae -- different install path and
    -- a different failure mode from the rest of the toolchain.
    ['rust-analyzer'] = 'rustup component add rust-analyzer',
    ['rustfmt'] = 'rustup component add rustfmt',
  }

  for _, exe in ipairs(vim.fn.sort(vim.tbl_keys(tools))) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok(string.format("Found: '%s'", exe))
    else
      vim.health.warn(string.format("Missing: '%s' -- install with `%s`", exe, tools[exe]))
    end
  end

  vim.health.info [[`ngserver` (angularls) and `stylelint-language-server` are
resolved from the project's `node_modules/.bin` when it ships them, otherwise
from the global pnpm install above. They are editor tools, so projects are not
expected to carry them as devDependencies.]]

  vim.health.info [[Formatters (stylua, prettierd, ...) are reported by
`conform.nvim`, which is lazy-loaded on `BufWritePre` -- save a file before
trusting a clean report, or run `:Lazy load conform.nvim` first.]]
end

return {
  check = function()
    vim.health.start 'dotfiles'

    check_language_tooling()
  end,
}
