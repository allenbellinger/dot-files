return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      vim.lsp.config('stylelint_lsp', {
        filetypes = { 'css', 'scss', 'typescript' },
        settings = {
          stylelint = {
            validate = { 'css', 'scss', 'typescript' },
            snippet = { 'css', 'scss', 'typescript' },
          },
        },
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('DisableTsLsSemanticTokens', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == 'ts_ls' then
            client.server_capabilities.semanticTokensProvider = nil
          end
        end,
      })

      vim.lsp.enable {
        'angularls',
        'basedpyright',
        'eslint',
        'jsonls',
        'lua_ls',
        'nginx_language_server',
        'ruff',
        'rust_analyzer',
        'stylelint_lsp',
        'ts_ls',
        'yamlls',
      }

      -- Rename via the built-in `vim.lsp.buf.rename`, which accepts a client
      -- filter. Arbitrating between angularls and ts_ls matters because both
      -- answer `textDocument/rename` and would produce duplicate edits. The
      -- prompt is `vim.ui.input`, i.e. the Snacks input float.
      local function rename(client_name)
        vim.lsp.buf.rename(nil, client_name and { name = client_name } or nil)
      end

      local function smart_rename()
        local bufnr = vim.api.nvim_get_current_buf()
        local angular_clients = vim.lsp.get_clients { bufnr = bufnr, name = 'angularls' }
        local has_angular = #angular_clients > 0 and angular_clients[1].server_capabilities.renameProvider

        if has_angular then
          -- angularls answers prepareRename only for symbols it actually owns
          -- (template bindings, component members); fall back to ts_ls otherwise.
          local client = angular_clients[1]
          local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
          client:request('textDocument/prepareRename', params, function(err, result)
            local target = (err or not result) and 'ts_ls' or 'angularls'
            vim.schedule(function()
              rename(target)
            end)
          end, bufnr)
        elseif #vim.lsp.get_clients { bufnr = bufnr, name = 'ts_ls' } > 0 then
          rename 'ts_ls'
        else
          rename(nil)
        end
      end

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('LspKeymaps', { clear = true }),
        callback = function(args)
          local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end

          map('n', '<leader>gd', function()
            Snacks.picker.lsp_definitions()
          end, 'Go to definition')
          map('n', '<leader>gr', function()
            Snacks.picker.lsp_references()
          end, 'Go to references')
          map('n', '<leader>gi', function()
            Snacks.picker.lsp_implementations()
          end, 'Go to implementation')
          map('n', '<leader>gt', function()
            Snacks.picker.lsp_type_definitions()
          end, 'Go to type definition')
          map('n', '<leader>ws', function()
            Snacks.picker.lsp_workspace_symbols()
          end, 'Workspace symbols')

          map({ 'n', 'x' }, '<leader>ca', function()
            vim.lsp.buf.code_action()
          end, 'Code action')

          map('n', '<leader>rn', smart_rename, 'Rename')
          map('n', 'K', function()
            vim.lsp.buf.hover { border = 'rounded' }
          end, 'Hover')
        end,
      })

      vim.keymap.set(
        'n',
        '<leader>q',
        '<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>',
        { desc = 'Open diagnostics list' }
      )
    end,
  },
  {
    'nvim-java/nvim-java',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    config = function()
      local java_settings = {
        completion = {
          guessMethodArguments = 'off',
        },
      }

      local java_file = vim.fs.find({ 'pom.xml', 'build.gradle', 'build.gradle.kts' }, {
        path = vim.api.nvim_buf_get_name(0),
        upward = true,
        type = 'file',
      })[1]

      if java_file then
        local project_root = vim.fs.dirname(java_file)
        local formatter = project_root .. '/config/eclipse-java-formatter.xml'

        if vim.uv.fs_stat(formatter) then
          java_settings.format = {
            enabled = true,
            settings = {
              url = vim.uri_from_fname(formatter),
              profile = 'Eclipse',
            },
          }
        end
      end

      vim.lsp.config('jdtls', {
        settings = {
          java = java_settings,
        },
      })

      require('java').setup()
      vim.lsp.enable 'jdtls'
    end,
  },
}
