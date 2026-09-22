return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      format_on_save = {
        timeout_ms = 2500,
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        css = { 'prettier', 'stylelint' },
        scss = { 'prettier', 'stylelint' },
        html = { 'prettier' },
        htmlangular = { 'prettier' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        python = { 'ruff_format', 'ruff_organize_imports' },
        rust = { 'rustfmt' },
        java = { lsp_format = 'prefer' },
        markdown = { 'prettier' },
        nginx = { 'nginxfmt' },
      },
    },
  },
}
