return {
  'folke/snacks.nvim',
  lazy = false,
  -- Loads before other start plugins: `Snacks.input` backs `vim.ui.input` and
  -- the picker backs the LSP keymaps, both of which are wired up at startup.
  priority = 1000,
  ---@type snacks.Config
  opts = function(_, opts)
    return vim.tbl_deep_extend('force', opts or {}, {
      -- `input` backs the native vim.lsp.buf.rename prompt.
      input = { enabled = true },
      bigfile = { enabled = true },
      quickfile = { enabled = true },
      styles = {
        -- `vim.lsp.buf.rename` passes `scope = 'cursor'` to `vim.ui.input`, but
        -- Snacks.input ignores it, so the float would otherwise sit pinned near
        -- the top of the screen. This is the cursor-relative variant that
        -- snacks/input.lua ships commented out.
        input = {
          relative = 'cursor',
          row = -3,
          col = 0,
          -- Select the prefilled value so typing replaces it instead of
          -- appending to it. Must be scheduled: snacks calls `startinsert!`
          -- *after* `on_win` fires, which would clobber a synchronous change.
          -- Prompts with no default are left alone (plain insert-mode prompt).
          on_win = function(self)
            vim.schedule(function()
              if not self:valid() then
                return
              end
              vim.api.nvim_win_call(self.win, function()
                if vim.api.nvim_get_current_line() ~= '' then
                  vim.cmd 'stopinsert'
                  vim.cmd 'normal! gH'
                end
              end)
            end)
          end,
        },
      },
      zen = {
        toggles = {
          dim = true,
        },
        show = {
          statusline = false,
          tabline = false,
        },
      },
      dashboard = {
        sections = {
          { section = 'header' },
          { icon = '󰈙 ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1, limit = 15 },
          { icon = '󰝰 ', title = 'Projects', section = 'projects', indent = 2, padding = 1, limit = 15 },
          { section = 'startup' },
        },
      },
      picker = {
        layout = {
          preset = 'dropdown',
        },
        sources = {
          files = {
            hidden = true,
            exclude = { '.git/', '.cache', '.obsidian', 'Archive' },
          },
        },
        formatters = {
          file = {
            filename_first = true,
          },
        },
        -- Resolved lazily: snacks is `lazy = false`, so requiring the trouble
        -- source directly here would drag trouble in at startup.
        actions = setmetatable({}, {
          __index = function(_, key)
            return require('trouble.sources.snacks').actions[key]
          end,
        }),
        win = {
          input = {
            keys = {
              ['<c-t>'] = {
                'trouble_open',
                mode = { 'n', 'i' },
              },
            },
          },
        },
      },
    })
  end,
  keys = {
    {
      '<leader>z',
      function()
        Snacks.zen()
      end,
      desc = 'Toggle Zen Mode',
    },
    -- find
    {
      '<leader>sf',
      function()
        Snacks.picker.files()
      end,
      desc = '[S]earch [F]iles',
    },
    {
      '<leader>sg',
      function()
        Snacks.picker.grep()
      end,
      desc = '[S]earch by [G]rep',
    },
    {
      '<leader>sw',
      function()
        Snacks.picker.grep_word()
      end,
      desc = '[S]earch current [W]ord',
      mode = { 'n', 'x' },
    },
    {
      '<leader>sh',
      function()
        Snacks.picker.help()
      end,
      desc = '[S]earch [H]elp',
    },
    {
      '<leader>sd',
      function()
        Snacks.picker.diagnostics()
      end,
      desc = '[S]earch [D]iagnostics',
    },
    {
      '<leader><space>',
      function()
        Snacks.picker.buffers()
      end,
      desc = '[ ] Find existing buffers',
    },
    {
      '<leader>?',
      function()
        Snacks.picker.recent()
      end,
      desc = '[?] Find recently opened files',
    },
    {
      '<leader>/',
      function()
        Snacks.picker.lines()
      end,
      desc = '[/] Fuzzily search in current buffer',
    },
    {
      '<leader>sn',
      function()
        Snacks.picker.files { cwd = '~/Notes/' }
      end,
      desc = '[S]earch [N]otes',
    },
    {
      '<leader>sv',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = '[S]earch neo[V]im files',
    },
  },
}
