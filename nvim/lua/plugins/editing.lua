return {
  {
    'tpope/vim-sleuth',
    event = { 'BufReadPost', 'BufNewFile' },
  },
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'David-Kunz/treesitter-unit',
    event = 'VeryLazy',
    config = function()
      require('treesitter-unit').enable_highlighting()
    end,
  },
  {
    'RRethy/vim-illuminate',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
      require('illuminate').configure {
        filetypes_denylist = {
          'oil',
          'snacks_input',
          'snacks_picker_input',
          'snacks_dashboard',
          'yaml',
        },
      }
    end,
  },
}
