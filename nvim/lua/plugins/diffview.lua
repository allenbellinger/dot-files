return {
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
}
