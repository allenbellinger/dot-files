return {
  'sindrets/diffview.nvim',
  cmd = { 'DiffviewOpen', 'DiffviewClose' },
  keys = {
    { '<leader>do', ':DiffviewOpen<cr>', desc = 'Open Diffview' },
    { '<leader>dc', ':DiffviewClose<cr>', desc = 'Close Diffview' },
  },
  opts = {
    view = {
      merge_tool = {
        layout = 'diff1_plain',
      },
    },
  },
}
