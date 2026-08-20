return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      -- `cmd`, `root_dir` and `filetypes` come from nvim-lspconfig's bundled
      -- `lsp/angularls.lua`, which probes both the project's `node_modules` and
      -- the global ngserver's own, and passes `--angularCoreVersion`. That
      -- matters here: the global ngserver is a different major than either
      -- project pins, so the probe paths are what keep it in lockstep.
      --
      -- Do NOT narrow `root_dir` to the nearest project (project.json /
      -- tsconfig.*): upstream's `cmd` resolves probe paths and the Angular core
      -- version relative to `root_dir` *without* climbing to the workspace, so a
      -- nested root in an nx repo silently falls back to the global
      -- @angular/language-service and an empty version.
      vim.lsp.config('angularls', {
        on_attach = function(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      })

      -- `cmd` and `root_dir` come from upstream. Its root_dir already decides
      -- whether a buffer uses stylelint at all (config lookup, deno exclusion,
      -- monorepo handling) and lands on the package-manager root -- which is
      -- what makes the *global* stylelint-language-server binary resolve each
      -- project's *local* stylelint, so custom syntaxes (postcss-scss,
      -- postcss-angular-inline) and plugins are available.
      --
      -- Only the filetypes/settings are ours: `typescript` is required because
      -- Angular components keep their styles inline, and .stylelintrc.json maps
      -- **/*.component.ts to the postcss-angular-inline syntax. Formatting stays
      -- with conform.
      vim.lsp.config('stylelint_lsp', {
        filetypes = { 'css', 'scss', 'typescript' },
        settings = {
          stylelint = {
            validate = { 'css', 'scss', 'typescript' },
            snippet = { 'css', 'scss', 'typescript' },
          },
        },
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
            require('tiny-code-action').code_action {}
          end, 'Code action')

          map('n', '<leader>rn', smart_rename, 'Rename (angularls preferred)')
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
    ft = 'java',
    dependencies = {
      'neovim/nvim-lspconfig',
    },
    config = function()
      require('java').setup()
      vim.lsp.enable 'jdtls'
    end,
  },
  {
    'rachartier/tiny-code-action.nvim',
    event = 'LspAttach',
    opts = {
      backend = 'diffsofancy',
      picker = 'snacks',
    },
  },
}
