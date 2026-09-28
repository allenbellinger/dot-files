return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'

      local function project_root(bufnr)
        local filename = vim.api.nvim_buf_get_name(bufnr)
        if filename == '' then
          return
        end

        local pom = vim.fs.find('pom.xml', {
          path = vim.fs.dirname(filename),
          upward = true,
          type = 'file',
        })[1]

        return pom and vim.fs.dirname(pom)
      end

      local function checkstyle_command(root)
        if vim.fn.executable 'mvn' == 1 then
          return 'mvn'
        end

        local wrapper = root .. '/mvnw'
        if vim.uv.fs_stat(wrapper) then
          return wrapper
        end

        return 'mvn'
      end

      lint.linters.maven_checkstyle = {
        cmd = function()
          local root = project_root(vim.api.nvim_get_current_buf())
          return root and checkstyle_command(root) or 'mvn'
        end,
        args = { '-Dstyle.color=never', 'checkstyle:check' },
        stdin = false,
        append_fname = false,
        stream = 'stdout',
        ignore_exitcode = true,
        parser = function(output, bufnr, cwd)
          local diagnostics = {}
          local buffer_path = vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr))

          for line in vim.gsplit(output, '\n', { plain = true, trimempty = true }) do
            local filename, line_number, column, message, code = line:match(
              '^%[ERROR%]%s+(.+):(%d+):(%d+):%s+(.+)%s+%[([^%]]+)%]$'
            )
            if not filename then
              filename, line_number, message, code = line:match(
                '^%[ERROR%]%s+(.+):(%d+):%s+(.+)%s+%[([^%]]+)%]$'
              )
            end

            if filename then
              local diagnostic_path = vim.fs.normalize(vim.fs.abspath(filename, cwd))
              if diagnostic_path == buffer_path then
                diagnostics[#diagnostics + 1] = {
                  lnum = tonumber(line_number) - 1,
                  col = column and tonumber(column) - 1 or 0,
                  message = message,
                  code = code,
                  severity = vim.diagnostic.severity.ERROR,
                  source = 'checkstyle',
                }
              end
            end
          end

          return diagnostics
        end,
      }

      local group = vim.api.nvim_create_augroup('JavaCheckstyleLint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost' }, {
        group = group,
        pattern = '*.java',
        callback = function(args)
          local root = project_root(args.buf)
          if root then
            lint.try_lint('maven_checkstyle', { cwd = root })
          end
        end,
      })
    end,
  },
  {
    'folke/trouble.nvim',
    opts = { win = { wo = { wrap = true } } },
    cmd = 'Trouble',
  },
  {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {},
  },
}
