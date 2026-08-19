return {
  'folke/snacks.nvim',
  lazy = false,
  priority = 1000,
  ---@type snacks.Config
  opts = {
    input = { enabled = true },
    bigfile = { enabled = true },
    quickfile = { enabled = true },
    styles = {
      input = {
        relative = 'cursor',
        row = -3,
        col = 0,
        on_win = function(self)
          vim.schedule(function()
            if not self:valid() then
              return
            end
            vim.api.nvim_win_call(self.win, function()
              if vim.api.nvim_get_current_line() ~= '' then
                vim.cmd 'stopinsert'
                vim.cmd 'normal! gH'
              end
            end)
          end)
        end,
      },
    },
    dashboard = {
      sections = {
        { section = 'header' },
        { icon = '󰈙 ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1, limit = 15 },
        { icon = '󰝰 ', title = 'Projects', section = 'projects', indent = 2, padding = 1, limit = 15 },
        { section = 'startup' },
      },
    },
    picker = {
      layout = {
        preset = 'dropdown',
      },
      sources = {
        files = {
          hidden = true,
          exclude = { '.git/', '.cache', '.obsidian', 'Archive' },
        },
      },
      formatters = {
        file = {
          filename_first = true,
        },
      },
      actions = setmetatable({}, {
        __index = function(_, key)
          return require('trouble.sources.snacks').actions[key]
        end,
      }),
      win = {
        input = {
          keys = {
            ['<c-t>'] = {
              'trouble_open',
              mode = { 'n', 'i' },
            },
          },
        },
      },
    },
  },
  keys = {
    {
      '<leader>sf',
      function()
        Snacks.picker.files()
      end,
      desc = '[S]earch [F]iles',
    },
    {
      '<leader>sg',
      function()
        Snacks.picker.grep()
      end,
      desc = '[S]earch by [G]rep',
    },
    {
      '<leader><space>',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[ ] Find existing buffers',
    },
    {
      '<leader>sv',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = '[S]earch neo[V]im files',
    },
  },
}
