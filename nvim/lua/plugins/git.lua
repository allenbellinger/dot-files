return {
  {
    'dlyongemallo/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose' },
    keys = {
      { '<leader>do', '<cmd>DiffviewOpen<cr>', desc = 'Open Diffview' },
      { '<leader>dc', '<cmd>DiffviewClose<cr>', desc = 'Close Diffview' },
    },
    opts = {
      view = {
        merge_tool = {
          layout = 'diff1_plain',
        },
      },
    },
  },
  { -- Adds git releated signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },
  {
    'f-person/git-blame.nvim',
    opts = {
      enabled = false,
    },
    keys = {
      { '<leader>gb', '<cmd>GitBlameToggle<cr>', desc = 'Toggle Git blame' },
    },
  },
}
