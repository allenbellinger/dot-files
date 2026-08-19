return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'echasnovski/mini.icons' },
    keys = {
      { '-', '<cmd>Oil<cr>', desc = 'Open parent directory' },
    },
    cmd = 'Oil',
    opts = {
      keymaps = {
        ['<C-h>'] = false,
        ['<M-h>'] = 'actions.select_split',
      },
      view_options = {
        show_hidden = true,
        is_always_hidden = function(name)
          return name == '.DS_Store'
        end,
      },
      cleanup_delay_ms = 1000,
      lsp_file_methods = {
        autosave_changes = true,
      },
    },
  },
}
