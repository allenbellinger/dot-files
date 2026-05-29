return {
  'folke/snacks.nvim',
  lazy = false,
  dependencies = {
    'folke/trouble.nvim',
  },
  ---@type snacks.Config
  opts = function(_, opts)
    return vim.tbl_deep_extend('force', opts or {}, {
      zen = {
        toggles = {
          dim = true,
        },
        show = {
          statusline = false,
          tabline = false,
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
        actions = require('trouble.sources.snacks').actions,
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
    })
  end,
  keys = {
    { '<leader>z', function() Snacks.zen() end, desc = 'Toggle Zen Mode' },
    -- find
    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [F]iles' },
    { '<leader>sg', function() Snacks.picker.grep() end, desc = '[S]earch by [G]rep' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch current [W]ord', mode = { 'n', 'x' } },
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader><space>', function() Snacks.picker.buffers() end, desc = '[ ] Find existing buffers' },
    { '<leader>?', function() Snacks.picker.recent() end, desc = '[?] Find recently opened files' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },
    { '<leader>sn', function() Snacks.picker.files({ cwd = '~/Notes/' }) end, desc = '[S]earch [N]otes' },
    { '<leader>sv', function() Snacks.picker.files({ cwd = vim.fn.stdpath 'config' }) end, desc = '[S]earch neo[V]im files' },
  },
}
