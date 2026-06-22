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
        'basedpyright',
        'ruff',
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
    'nvimdev/lspsaga.nvim',
    event = 'LspAttach',
    opts = {
      lightbulb = { enable = false },
      symbol_in_winbar = { enable = false },
    },
    config = function(_, opts)
      require('lspsaga').setup(opts)
      -- Hide rename reference highlights (they can stick after closing)
      vim.api.nvim_set_hl(0, 'RenameMatch', {})
    end,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
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
      local fs = vim.fs
      local uv = vim.uv

      local function path_exists(path)
        return path and uv.fs_stat(path) ~= nil
      end

      local function is_within(path, root)
        local normalized_path = fs.normalize(path)
        local normalized_root = fs.normalize(root)
        return normalized_path == normalized_root
          or normalized_path:sub(1, #normalized_root + 1) == normalized_root .. '/'
      end

      local function angular_root_dir(fname)
        local workspace_root = fs.root(fname, { 'angular.json', 'nx.json' })
        if not workspace_root then
          return nil
        end

        local project_root = fs.root(fname, {
          'project.json',
          'tsconfig.app.json',
          'tsconfig.lib.json',
          'tsconfig.json',
        })

        if project_root and is_within(project_root, workspace_root) then
          return project_root
        end

        return workspace_root
      end

      local angularls_warned = {}

      local function angularls_cmd(root_dir)
        local ngserver_bin = vim.fn.exepath 'ngserver'
        local workspace_root = fs.root(root_dir, { 'angular.json', 'nx.json' })
        local node_modules = workspace_root and fs.joinpath(workspace_root, 'node_modules') or nil

        if node_modules and not path_exists(node_modules) then
          node_modules = nil
        end

        local angular_language_service = node_modules and fs.joinpath(node_modules, '@angular', 'language-service')
        local typescript_lib = node_modules and fs.joinpath(node_modules, 'typescript', 'lib')

        local missing = {}
        if ngserver_bin == '' then
          table.insert(missing, 'ngserver')
        end
        if not node_modules then
          table.insert(missing, 'node_modules')
        end
        if not path_exists(angular_language_service) then
          table.insert(missing, '@angular/language-service')
        end
        if not path_exists(typescript_lib) then
          table.insert(missing, 'typescript/lib')
        end

        if #missing > 0 then
          if not angularls_warned[root_dir] then
            angularls_warned[root_dir] = true
            vim.schedule(function()
              vim.notify(
                string.format('angularls: missing in %s: %s', root_dir, table.concat(missing, ', ')),
                vim.log.levels.ERROR
              )
            end)
          end
          return nil
        end

        return {
          ngserver_bin,
          '--stdio',
          '--tsProbeLocations',
          node_modules,
          '--ngProbeLocations',
          node_modules,
        }
      end

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
        root_dir = angular_root_dir,
        cmd = function(dispatchers, config)
          local root_dir = config and config.root_dir or nil
          if type(root_dir) == 'function' then
            local bufnr = vim.api.nvim_get_current_buf()
            local fname = vim.api.nvim_buf_get_name(bufnr)
            root_dir = root_dir(fname)
          end
          if not root_dir or root_dir == '' then
            return nil
          end

          local cmd = angularls_cmd(root_dir)
          if not cmd then
            return nil
          end

          return vim.lsp.rpc.start(cmd, dispatchers)
        end,
        capabilities = {
          workspace = {
            fileOperations = {
              willRename = vim.NIL,
            },
          },
        },
        filetypes = { 'typescript', 'html', 'typescriptreact', 'htmlangular' },
        on_attach = function(client)
          client.server_capabilities.semanticTokensProvider = nil

          local workspace = client.server_capabilities.workspace
          if workspace and workspace.fileOperations then
            workspace.fileOperations.willRename = false
          end
        end,
      })

      local angularls_group = vim.api.nvim_create_augroup('AngularLspStart', { clear = true })
      local function ensure_angularls(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        if #vim.lsp.get_clients { bufnr = bufnr, name = 'angularls' } > 0 then
          return
        end

        local cfg = vim.lsp.config.angularls
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if not cfg or fname == '' then
          return
        end

        local root_dir = cfg.root_dir and cfg.root_dir(fname) or nil
        if not root_dir then
          return
        end

        vim.lsp.start(vim.tbl_deep_extend('force', cfg, { root_dir = root_dir }), { bufnr = bufnr })
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = angularls_group,
        pattern = { 'typescript', 'html', 'typescriptreact', 'htmlangular' },
        callback = function(args)
          ensure_angularls(args.buf)
        end,
      })

      vim.lsp.enable 'eslint'
      vim.lsp.enable 'ts_ls'
      vim.lsp.enable 'lua_ls'
      vim.lsp.enable 'jsonls'
      vim.lsp.enable 'stylelint_lsp'
      vim.lsp.enable 'rust_analyzer'
      vim.lsp.enable 'yamlls'
      vim.lsp.enable 'basedpyright'
      vim.lsp.enable 'ruff'

      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', '<leader>pd', '<cmd>Lspsaga peek_definition<cr>', { desc = 'Peek definition' })
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, { desc = 'Go to references' })
      vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, { desc = 'Go to type definition' })
      vim.keymap.set('n', '<leader>rn', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local angular_clients = vim.lsp.get_clients { bufnr = bufnr, name = 'angularls' }
        local has_angular = #angular_clients > 0 and angular_clients[1].server_capabilities.renameProvider

        if has_angular then
          local client = angular_clients[1]
          local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
          client:request('textDocument/prepareRename', params, function(err, result)
            if err or not result then
              vim.lsp.buf.rename(nil, {
                filter = function(c)
                  return c.name == 'ts_ls'
                end,
              })
            else
              vim.lsp.buf.rename(nil, {
                filter = function(c)
                  return c.name == 'angularls'
                end,
              })
            end
          end, bufnr)
        else
          vim.lsp.buf.rename(nil, {
            filter = function(c)
              return c.name == 'ts_ls'
            end,
          })
        end
      end, { desc = 'Rename (angularls preferred)' })

      vim.keymap.set({ 'n', 'x' }, '<leader>ca', '<cmd>Lspsaga code_action<cr>', { desc = 'Code action' })

      vim.keymap.set('n', 'K', '<cmd>Lspsaga hover_doc<cr>', { desc = 'Hover doc' })
      vim.keymap.set('n', '<leader>ws', vim.lsp.buf.workspace_symbol, { desc = 'Workspace symbols' })
      vim.keymap.set(
        'n',
        '<leader>q',
        '<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>',
        { desc = 'Open diagnostics list' }
      )
    end,
  },
}
