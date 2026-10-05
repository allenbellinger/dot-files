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
          elseif client and client.name == 'spring-boot' then
            client.server_capabilities.completionProvider = nil
          end

          if client and client.name == 'jdtls' then
            local method = 'workspace/executeClientCommand'
            local original_handler = client.handlers[method] or vim.lsp.handlers[method]

            client.handlers[method] = function(err, params, ctx)
              if params.command == 'editor.action.triggerParameterHints' then
                vim.lsp.commands[params.command](params.arguments, ctx)
                return {}
              end

              return original_handler(err, params, ctx)
            end
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

      local original_select = vim.ui.select

      local function code_action_priority(item)
        local action = item.action or item
        local kind = action.kind or ''

        if kind == 'source.addMissingImports' then
          return 1
        elseif action.isPreferred then
          return 3
        elseif kind:match '^quickfix' then
          return 4
        elseif kind:match '^refactor' then
          return 5
        elseif kind == 'source.organizeImports' then
          return 6
        end

        return 7
      end

      vim.ui.select = function(items, opts, on_choice)
        if not opts or opts.kind ~= 'codeaction' then
          return original_select(items, opts, on_choice)
        end

        local ordered = {}
        for index, item in ipairs(items) do
          ordered[index] = { item = item, index = index }
        end

        table.sort(ordered, function(a, b)
          local a_priority = code_action_priority(a.item)
          local b_priority = code_action_priority(b.item)
          if a_priority == b_priority then
            return a.index < b.index
          end
          return a_priority < b_priority
        end)

        local sorted_items = {}
        for index, entry in ipairs(ordered) do
          sorted_items[index] = entry.item
        end

        return original_select(sorted_items, opts, on_choice)
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
        signatureHelp = {
          enabled = true,
        },
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

      -- nvim-java derives JDTLS's -data path from vim.fn.getcwd(). Use the
      -- detected project root so the same project has one workspace regardless
      -- of where Neovim was launched.
      local jdtls_cmd = vim.lsp.config.jdtls.cmd
      vim.lsp.config('jdtls', {
        cmd = function(dispatchers, config)
          local root_dir = config.root_dir
          if not root_dir then
            return jdtls_cmd(dispatchers, config)
          end

          local cwd = vim.fn.getcwd()
          vim.fn.chdir(root_dir)
          local ok, result = xpcall(function()
            return jdtls_cmd(
              dispatchers,
              vim.tbl_extend('force', config, {
                cmd_cwd = root_dir,
              })
            )
          end, debug.traceback)
          vim.fn.chdir(cwd)

          if not ok then
            error(result)
          end

          return result
        end,
      })

      -- spring-boot.nvim starts alongside jdtls and can issue its first
      -- command before either client has finished initializing. Return a
      -- request-only proxy so the plugin can wait without notifying that the
      -- client is missing.
      local spring_boot_util = require 'spring_boot.util'
      local get_jdtls_client = spring_boot_util.get_client
      local deferred_clients = { jdtls = true, ['spring-boot'] = true }

      local function deferred_client(name)
        return setmetatable({}, {
          __index = function(_, key)
            if key ~= 'request' then
              return nil
            end

            return function(method, params, callback, bufnr)
              local attempts = 0
              local function request_when_ready()
                local client = vim.lsp.get_clients({ name = name })[1]
                if client and client.initialized then
                  client:request(method, params, callback, bufnr)
                  return
                end

                attempts = attempts + 1
                if attempts < 100 then
                  vim.defer_fn(request_when_ready, 50)
                elseif callback then
                  callback({ code = -1, message = name .. ' did not become available' }, nil)
                else
                  vim.notify(name .. ' did not become available for Spring Boot', vim.log.levels.WARN)
                end
              end

              request_when_ready()
            end
          end,
        })
      end

      spring_boot_util.get_client = function(name)
        if not deferred_clients[name] then
          return get_jdtls_client(name)
        end

        local client = vim.lsp.get_clients({ name = name })[1]
        if client and client.initialized then
          return client
        end

        return deferred_client(name)
      end

      vim.lsp.enable 'jdtls'
    end,
  },
}
