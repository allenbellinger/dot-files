return {
  {
    'sainnhe/everforest',
    lazy = false,
    priority = 1000,
    config = function()
      -- Optionally configure and load the colorscheme
      -- directly inside the plugin declaration.
      vim.g.everforest_background = 'hard'
      vim.cmd.colorscheme 'everforest'
    end,
  },
  { -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = true,
        theme = 'everforest',
        component_separators = '|',
        section_separators = '',
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          {
            'mode',
            fmt = function(str)
              return str:sub(1, 1)
            end,
          },
        },
        lualine_b = { 'branch' },
        lualine_c = {
          {
            'diff',
            source = function()
              local g = vim.b.gitsigns_status_dict
              if g then
                return { added = g.added, modified = g.changed, removed = g.removed }
              end
            end,
          },
          {
            'diagnostics',
            sources = { 'nvim_diagnostic' },
          },
        },
        lualine_x = { 'filename' },
        lualine_y = { 'filetype' },
        lualine_z = { 'location' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      extensions = { 'oil', 'lazy', 'quickfix' },
    },
  },
  { -- Adds git releated signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
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
      { '<leader>gb', ':GitBlameToggle<CR>', desc = 'Toggle Git blame' },
    },
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        hover = {
          enabled = true,
          silent = true,
        },
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['vim.lsp.util.stylize_markdown'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      presets = {
        lsp_doc_border = true,
      },
      routes = {
        {
          filter = {
            event = 'notify',
            kind = '',
            find = 'No information available',
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = 'msg_show',
            kind = '',
            find = 'written',
          },
          opts = { skip = true },
        },
      },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    keys = {
      { '<leader>nd', ':NoiceDismiss<CR>', desc = 'Dismiss Noice Message' },
    },
  },
  {
    'monkoose/matchparen.nvim',
    opts = {},
  },
  {
    'goolord/alpha-nvim',
    dependencies = { 'echasnovski/mini.icons' },
    config = function()
      require('alpha').setup(require('alpha.themes.startify').config)
    end,
  },
}
