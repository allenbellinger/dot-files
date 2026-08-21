return {
  {
    'echasnovski/mini.icons',
    lazy = false,
    priority = 900,
    config = function()
      require('mini.icons').setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  {
    'EdenEast/nightfox.nvim',
    lazy = true,
    priority = 1000,
  },
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    opts = {
      options = {
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
      extensions = { 'oil', 'lazy', 'quickfix' },
    },
  },
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim' },
    opts = {
      lsp = {
        signature = { enabled = false },
        hover = { enabled = false },
      },
      routes = {
        {
          filter = { event = 'msg_show', kind = '', find = 'written' },
          opts = { skip = true },
        },
      },
    },
  },
}
