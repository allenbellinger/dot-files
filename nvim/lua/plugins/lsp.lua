return {
  'joeveiga/ng.nvim',
  {
    'mason-org/mason.nvim',
    lazy = false,
    opts = {
      ensure_installed = {
        'angular-language-server',
        'eslint-lsp',
        'typescript-language-server',
        'lua-language-server',
        'stylelint-lsp',
        'json-lsp',
        'yaml-language-server',
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
    'rachartier/tiny-code-action.nvim',
    event = 'LspAttach',
    opts = {
      backend = 'diffsofancy',
      picker = {
        'snacks',
        opts = {
          focus = 'list',
        },
      },
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
      local stylelint_filetypes = { 'css', 'scss', 'typescript' }

      -- Config must come before enable so servers start with the right settings
      vim.lsp.config('stylelint_lsp', {
        filetypes = stylelint_filetypes,
        on_attach = function(client)
          client.server_capabilities.documentHighlightProvider = false
        end,
        settings = {
          stylelint = {
            validate = stylelint_filetypes,
          },
        },
        handlers = {
          -- Stylelint LSP sends window/showMessageRequest prompts when it
          -- can't parse inline styles (e.g. typing '@' in a TS file). The
          -- default handler routes these through vim.ui.select, which
          -- triggers telescope-ui-select. Suppress them here.
          ['window/showMessageRequest'] = function(_, result)
            return result
          end,
        },
      })

      -- Disable willRename so only ts_ls handles file-move import updates from Oil,
      -- avoiding a race condition when both servers respond to the same rename.
      vim.lsp.config('angularls', {
        capabilities = {
          workspace = {
            fileOperations = {
              willRename = vim.NIL,
            },
          },
        },
        on_attach = function(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })

      vim.lsp.enable 'angularls'
      vim.lsp.enable 'eslint'
      vim.lsp.enable 'ts_ls'
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'jsonls'
      vim.lsp.enable 'stylelint_lsp'

      vim.lsp.enable 'rust_analyzer'
      vim.lsp.enable 'yamlls'

      vim.keymap.set('n', '<leader>gd', '<cmd>Trouble lsp_definitions toggle focus=true<cr>', { desc = 'Go to definition' })
      vim.keymap.set('n', '<leader>gr', '<cmd>Trouble lsp_references toggle focus=true<cr>', { desc = 'Go to references' })
      vim.keymap.set('n', '<leader>gi', '<cmd>Trouble lsp_implementations toggle focus=true<cr>', { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>gt', '<cmd>Trouble lsp_type_definitions toggle focus=true<cr>', { desc = 'Go to type definition' })
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename' })

      vim.keymap.set({ 'n', 'x' }, '<leader>ca', function()
        require('tiny-code-action').code_action {}
      end, { desc = 'Code action' })

      vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, { desc = 'Workspace symbols' })
      vim.keymap.set('n', '<leader>ds', '<cmd>Trouble symbols toggle focus=true<cr>', { desc = 'Document symbols' })
      vim.keymap.set('n', '<leader>q', '<cmd>Trouble diagnostics toggle focus=true<cr>', { desc = 'Open diagnostics list' })
    end,
  },
}
