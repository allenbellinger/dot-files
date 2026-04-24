return {
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-lua/popup.nvim',
      'natecraddock/telescope-zf-native.nvim',
      'nvim-telescope/telescope-media-files.nvim',
    },
    config = function()
      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      local telescope = require 'telescope'
      local open_with_trouble = require('trouble.sources.telescope').open

      telescope.setup {
        defaults = {
          mappings = {
            i = {
              ['<C-u>'] = false,
              ['<C-d>'] = false,
              ['<C-t>'] = open_with_trouble,
            },
            n = {
              ['<C-t>'] = open_with_trouble,
            },
          },
          path_display = { 'filename_first' },
        },
        extensions = {
          media_files = {
            filetypes = { 'png', 'webp', 'jpg', 'jpeg' },
            find_cmd = 'rg',
          },
        },
        pickers = {
          find_files = {
            file_ignore_patterns = {
              '.git/',
              '.cache',
              '.obsidian',
              'Archive',
            },
            hidden = true,
          },
        },

      }

      telescope.load_extension 'media_files'

      -- Enable telescope zf native for filename-prioritized sorting
      pcall(telescope.load_extension, 'zf-native')
      -- See `:help telescope.builtin`
      vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
      vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>/', function()
        -- You can pass additional configuration to telescope to change theme, layout, etc.
        require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = true,
        })
      end, { desc = '[/] Fuzzily search in current buffer' })

      vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sn', function()
        require('telescope.builtin').find_files { cwd = '~/Notes/' }
      end, { desc = '[S]earch [N]otes' })
      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set('n', '<leader>sv', function()
        require('telescope.builtin').find_files {
          cwd = vim.fn.stdpath 'config',
        }
      end, { desc = '[S]earch neo[V]im files' })
    end,
  },
}
