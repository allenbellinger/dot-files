return {
  'joeveiga/ng.nvim',
  {
    'mason-org/mason.nvim',
    lazy = false,
    config = function()
      require('mason').setup()
    end,
    opts = { ensure_installed = { 'prettierd' } },
  },
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    opts = { auto_install = true },
  },
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      { 'mason-org/mason.nvim', config = true }, -- NOTE: Must be loaded before dependants
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      'folke/neodev.nvim',
    },
    config = function()
      local emmet_filetypes = { 'astro', 'css', 'html', 'less', 'scss', 'sugarss', 'vue', 'wxss', 'typescript' }
      local stylelint_filetypes = { 'css', 'less', 'scss', 'typescript' }

      require('mason').setup()
      require('mason-lspconfig').setup {
        automatic_enable = false,
      }
      require('mason-tool-installer').setup {}
      vim.api.nvim_command 'MasonToolsInstall'

      vim.lsp.enable 'angularls'
      vim.lsp.enable 'eslint'
      vim.lsp.enable 'ts_ls'
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'emmet_language_server'
      vim.lsp.config('emmet_language_server', {
        filetypes = emmet_filetypes,
      })
      vim.lsp.enable 'stylelint_lsp'
      vim.lsp.config('stylelint_lsp', {
        filetypes = stylelint_filetypes,
        settings = {
          stylelintplus = {
            autoFixOnSave = true,
            autoFixOnFormat = true,
          },
        },
      })
      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, { desc = 'Go to references' })
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

      vim.diagnostic.config { virtual_text = true }
    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    config = function()
      require('lspsaga').setup {}
      vim.keymap.set('n', '<leader>rn', ':Lspsaga rename<cr>', { desc = 'Rename' })
      vim.keymap.set('n', '<leader>ca', ':Lspsaga code_action<cr>', { desc = 'Code action' })
      vim.keymap.set('n', 'K', ':Lspsaga hover_doc<cr>')
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
}
