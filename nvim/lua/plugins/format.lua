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
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        css = { 'prettierd', 'stylelint' },
        scss = { 'prettierd', 'stylelint' },
        html = { 'prettierd' },
        htmlangular = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        python = { 'ruff_format', 'ruff_organize_imports' },
        rust = { 'rustfmt' },
        markdown = { 'prettierd' },
        nginx = { 'nginxfmt' },
      },
    },
  },
}
