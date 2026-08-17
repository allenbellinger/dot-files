return {
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
