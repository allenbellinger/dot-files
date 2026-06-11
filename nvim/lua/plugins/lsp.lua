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

      local function find_workspace_root(path)
        return fs.root(path, { 'angular.json', 'nx.json' })
      end

      local function resolve_workspace_node_modules(start_path)
        local workspace_root = find_workspace_root(start_path)
        if not workspace_root then
          return nil
        end

        local current = fs.normalize(start_path)
        local normalized_workspace_root = fs.normalize(workspace_root)

        while current and is_within(current, normalized_workspace_root) do
          local candidate = fs.joinpath(current, 'node_modules')
          if path_exists(candidate) then
            return candidate
          end

          if current == normalized_workspace_root then
            break
          end

          local parent = fs.dirname(current)
          if parent == current then
            break
          end
          current = parent
        end

        return nil
      end

      local missing_angularls_paths = {}

      local function notify_missing_paths_once(root_dir, missing)
        local key = root_dir .. '::' .. table.concat(missing, ',')
        if missing_angularls_paths[key] then
          return
        end

        missing_angularls_paths[key] = true
        vim.schedule(function()
          vim.notify(
            string.format(
              'angularls strict mode: missing project-local dependency in %s: %s',
              root_dir,
              table.concat(missing, ', ')
            ),
            vim.log.levels.ERROR
          )
        end)
      end

      local function angularls_cmd(root_dir)
        local ngserver_bin = vim.fn.exepath 'ngserver'
        local node_modules = resolve_workspace_node_modules(root_dir)
        local angular_language_service = nil
        local typescript_lib = nil

        if node_modules then
          angular_language_service = fs.joinpath(node_modules, '@angular', 'language-service')
          typescript_lib = fs.joinpath(node_modules, 'typescript', 'lib')
        end

        local missing = {}
        if ngserver_bin == '' then
          table.insert(missing, 'ngserver (from PATH / mason)')
        end
        if not node_modules then
          table.insert(missing, 'node_modules (searched from project root up to workspace root)')
        end
        if node_modules and not path_exists(node_modules) then
          table.insert(missing, 'node_modules')
        end
        if not path_exists(angular_language_service) then
          table.insert(missing, '@angular/language-service')
        end
        if not path_exists(typescript_lib) then
          table.insert(missing, 'typescript/lib')
        end

        if #missing > 0 then
          notify_missing_paths_once(root_dir, missing)
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

      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
      vim.keymap.set('n', '<leader>pd', '<cmd>Lspsaga peek_definition<cr>', { desc = 'Peek definition' })
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, { desc = 'Go to references' })
      vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, { desc = 'Go to implementation' })
      vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, { desc = 'Go to type definition' })
      vim.keymap.set('n', '<leader>rn', function()
        local bufnr = vim.api.nvim_get_current_buf()
        local angular_clients = vim.lsp.get_clients { bufnr = bufnr, name = 'angularls' }
        local has_angular = #angular_clients > 0 and angular_clients[1].server_capabilities.renameProvider

        -- Wrap vim.lsp.buf.rename so Lspsaga's do_rename uses only one client
        local orig_rename = vim.lsp.buf.rename
        vim.lsp.buf.rename = function(new_name, opts)
          vim.lsp.buf.rename = orig_rename
          opts = opts or {}
          if has_angular then
            local client = angular_clients[1]
            local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
            client:request('textDocument/prepareRename', params, function(err, result)
              if err or not result then
                orig_rename(
                  new_name,
                  vim.tbl_extend('force', opts, {
                    filter = function(c)
                      return c.name == 'ts_ls'
                    end,
                  })
                )
              else
                orig_rename(
                  new_name,
                  vim.tbl_extend('force', opts, {
                    filter = function(c)
                      return c.name == 'angularls'
                    end,
                  })
                )
              end
            end, bufnr)
          else
            orig_rename(
              new_name,
              vim.tbl_extend('force', opts, {
                filter = function(c)
                  return c.name == 'ts_ls'
                end,
              })
            )
          end
        end

        vim.cmd 'Lspsaga rename'
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
