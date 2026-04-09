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

      vim.lsp.enable 'angularls'
      vim.lsp.enable 'eslint'
      vim.lsp.enable 'ts_ls'
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'jsonls'
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

      -- Highlight references of the symbol under the cursor (replaces treesitter-refactor highlight_definitions)
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method 'textDocument/documentHighlight' then
            local group = vim.api.nvim_create_augroup('lsp-document-highlight-' .. args.buf, { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = args.buf,
              group = group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = args.buf,
              group = group,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        callback = function(args)
          pcall(vim.api.nvim_del_augroup_by_name, 'lsp-document-highlight-' .. args.buf)
        end,
      })
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
      'echasnovski/mini.icons',
    },
  },
}
