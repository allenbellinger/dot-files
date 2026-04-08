return {
  {
    'stevearc/oil.nvim',
    dependencies = { 'echasnovski/mini.icons' },
    config = function()
      require('oil').setup {
        columns = { 'icon' },
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
      }

      -- Open parent directory in current window
      vim.keymap.set('n', '-', ':Oil<CR>', { desc = 'Open parent directory' })

      -- Open parent directory in floating window
      vim.keymap.set('n', '<space>-', require('oil').toggle_float)
    end,
  },
}
