return {
  'joeveiga/ng.nvim',
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = {
      ensure_installed = {
        -- LSP servers
        'angular-language-server',
        'eslint-lsp',
        'typescript-language-server',
        'lua-language-server',
        'emmet-language-server',
        'stylelint-lsp',
        'json-lsp',
        'yaml-language-server',
        -- Formatters / linters
        'prettierd',
        'stylua',
      },
    },
  },
  {
    'mason-org/mason-lspconfig.nvim',
    lazy = false,
    opts = {
      auto_install = true,
      automatic_enable = false,
    },
  },
  {
    'neovim/nvim-lspconfig',
    lazy = false,
    dependencies = {
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
    },
    config = function()
      local emmet_filetypes = { 'css', 'html', 'scss', 'typescript' }
      local stylelint_filetypes = { 'css', 'scss', 'typescript' }

      -- Config must come before enable so servers start with the right settings
      vim.lsp.config('emmet_language_server', {
        filetypes = emmet_filetypes,
      })
      vim.lsp.config('stylelint_lsp', {
        filetypes = stylelint_filetypes,
        settings = {
          stylelint = {
            validate = stylelint_filetypes,
          },
        },
      })

      vim.lsp.enable 'angularls'
      vim.lsp.enable 'eslint'
      vim.lsp.enable 'ts_ls'
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'jsonls'
      vim.lsp.enable 'emmet_language_server'
      vim.lsp.enable 'stylelint_lsp'

      vim.lsp.enable 'rust_analyzer'
      vim.lsp.enable 'yamlls'

      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, { desc = 'Go to references' })
      vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, { desc = 'Go to type definition' })
      vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, { desc = 'Workspace symbols' })
      vim.keymap.set('n', '<leader>ds', vim.lsp.buf.document_symbol, { desc = 'Document symbols' })
      vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
    end,
  },
  {
    'nvimdev/lspsaga.nvim',
    opts = {},
    keys = {
      { '<leader>rn', ':Lspsaga rename<cr>', desc = 'Rename' },
      { '<leader>ca', ':Lspsaga code_action<cr>', desc = 'Code action' },
    },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
  },
  {
    'vuki656/package-info.nvim',
    dependencies = 'MunifTanjim/nui.nvim',
    opts = { autostart = false },
    config = function(_, opts)
      require('package-info').setup(opts)
      vim.keymap.set('n', '<leader>ns', function()
        require('package-info').show { force = true }
      end, { desc = 'Show package versions', silent = true })
      vim.keymap.set('n', '<leader>nc', function()
        require('package-info').hide()
      end, { desc = 'Hide package versions', silent = true })
    end,
  },
}
