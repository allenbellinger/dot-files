return {
  check = function()
    vim.health.start 'dotfiles'

    local tools = {
      ['typescript-language-server'] = 'brew install typescript-language-server',
      ['vscode-eslint-language-server'] = 'brew install vscode-langservers-extracted',
      ['vscode-json-language-server'] = 'brew install vscode-langservers-extracted',
      ['yaml-language-server'] = 'brew install yaml-language-server',
      ['lua-language-server'] = 'brew install lua-language-server',
      ['basedpyright-langserver'] = 'brew install basedpyright',
      ['ruff'] = 'brew install ruff',
      ['ngserver'] = 'pnpm add -g @angular/language-server',
      ['stylelint-language-server'] = 'pnpm add -g stylelint-lsp',
      ['nginx-language-server'] = 'uv tool install nginx-language-server',
      ['nginxfmt'] = 'uv tool install nginxfmt',
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
  end,
}
