return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local function path_exists(path)
        return path and vim.uv.fs_stat(path) ~= nil
      end

      local function is_within(path, root)
        local normalized_path = vim.fs.normalize(path)
        local normalized_root = vim.fs.normalize(root)
        return normalized_path == normalized_root
          or normalized_path:sub(1, #normalized_root + 1) == normalized_root .. '/'
      end

      local function angular_root_dir(fname)
        local workspace_root = vim.fs.root(fname, { 'angular.json', 'nx.json' })
        if not workspace_root then
          return nil
        end

        local project_root = vim.fs.root(fname, {
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

      -- Resolve binaries from the project's own `node_modules/.bin` when it
      -- ships one, so the server stays in lockstep with the project's
      -- Angular/stylelint version. Otherwise fall back to the global install
      -- (pnpm global) -- these are editor tools, so most repos don't and
      -- shouldn't carry them as devDependencies.
      local function project_bin(root, name)
        if not root then
          return nil
        end
        local workspace_root = vim.fs.root(root, { 'package.json' }) or root
        local bin = vim.fs.joinpath(workspace_root, 'node_modules', '.bin', name)
        return path_exists(bin) and bin or nil
      end

      local function resolve_bin(root, name)
        local local_bin = project_bin(root, name)
        if local_bin then
          return local_bin
        end
        local exe = vim.fn.exepath(name)
        return exe ~= '' and exe or nil
      end

      local function angularls_cmd(root_dir)
        local workspace_root = vim.fs.root(root_dir, { 'angular.json', 'nx.json' })
        local node_modules = workspace_root and vim.fs.joinpath(workspace_root, 'node_modules') or nil

        if node_modules and not path_exists(node_modules) then
          node_modules = nil
        end

        -- Project-local ngserver wins; otherwise the global pnpm install.
        local ngserver_bin = resolve_bin(root_dir, 'ngserver')

        local angular_language_service = node_modules and vim.fs.joinpath(node_modules, '@angular', 'language-service')
        local typescript_lib = node_modules and vim.fs.joinpath(node_modules, 'typescript', 'lib')

        local missing = {}
        if not ngserver_bin then
          table.insert(missing, 'ngserver (pnpm add -g @angular/language-server)')
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

      -- Disable willRename so only ts_ls handles file-move import updates from Oil,
      -- avoiding a race condition when both servers respond to the same rename.
      vim.lsp.config('angularls', {
        -- NOTE: native `vim.lsp.config` calls root_dir as (bufnr, on_dir), not
        -- (fname) like nvim-lspconfig did. Getting this wrong is what forced the
        -- old manual `ensure_angularls` FileType autocmd.
        root_dir = function(bufnr, on_dir)
          local dir = angular_root_dir(vim.api.nvim_buf_get_name(bufnr))
          if dir and angularls_cmd(dir) then
            on_dir(dir)
          end
        end,
        -- NOTE: a `cmd` function must return an rpc client; returning nil makes
        -- `client:initialize()` index a nil `rpc`. Availability is therefore
        -- decided in `root_dir` above (declining to call `on_dir`), and the
        -- error below only guards a race where the tree changes in between --
        -- `cmd` runs inside `Client.create`'s pcall, so it logs cleanly.
        cmd = function(dispatchers, config)
          local root_dir = config and config.root_dir or nil
          local cmd = root_dir ~= nil and root_dir ~= '' and angularls_cmd(root_dir) or nil
          if not cmd then
            error('angularls: ngserver or Angular deps unavailable in ' .. tostring(root_dir))
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

      -- Let the server resolve each project's local stylelint (so project
      -- plugins/custom syntax like postcss-scss are available). Validate scss
      -- in addition to the css/postcss defaults; formatting stays with conform.
      --
      -- Capture nvim-lspconfig's own root_dir first: it already decides whether
      -- a buffer is using stylelint at all (config file lookup, deno exclusion,
      -- monorepo handling). We only add "and a server binary is resolvable".
      local stylelint_root_dir = vim.lsp.config.stylelint_lsp.root_dir

      vim.lsp.config('stylelint_lsp', {
        -- Gate startup here rather than in `cmd`: a `cmd` function must return
        -- an rpc client, and returning nil crashes `client:initialize()`.
        root_dir = function(bufnr, on_dir)
          stylelint_root_dir(bufnr, function(dir)
            if resolve_bin(dir, 'stylelint-language-server') then
              on_dir(dir)
            end
          end)
        end,
        cmd = function(dispatchers, config)
          local root_dir = config and config.root_dir or nil
          local bin = resolve_bin(root_dir, 'stylelint-language-server')
          if not bin then
            error('stylelint_lsp: stylelint-language-server unavailable for ' .. tostring(root_dir))
          end
          return vim.lsp.rpc.start({ bin, '--stdio' }, dispatchers)
        end,
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

      -- Buffer-local LSP keymaps: these used to be global, so they were bound
      -- even in buffers with no language server attached.
      --
      -- NOTE: the <leader>g* / <leader>ca maps intentionally duplicate the
      -- built-in grr/gri/grt/gra -- they route to Snacks pickers and
      -- tiny-code-action instead of the quickfix list. `K` is *not* mapped
      -- here: Neovim binds it to `vim.lsp.buf.hover()` on attach already, and
      -- the border comes from `winborder`.
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
