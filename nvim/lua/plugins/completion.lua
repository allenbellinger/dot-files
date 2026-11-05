return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'saghen/blink.cmp',
    dependencies = {
      'saghen/blink.lib',
    },
    build = function()
      require('blink.cmp').build():pwait()
    end,
    opts = {
      keymap = { preset = 'default' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 0 },
        accept = {
          auto_brackets = {
            enabled = false,
          },
        },
      },
      sources = {
        providers = {
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
          lsp = {
            transform_items = function(ctx, items)
              local cursor_line = ctx.pos.row
              local cursor_col = ctx.pos.col

              -- angularls can return an end position past the cursor, which
              -- would eat text to the right of it.
              local function clamp_range(range)
                if not range then
                  return
                end
                local end_pos = range['end']
                if end_pos.line > cursor_line then
                  end_pos.line = cursor_line
                  end_pos.character = cursor_col
                elseif end_pos.line == cursor_line and end_pos.character > cursor_col then
                  end_pos.character = cursor_col
                end
              end

              for _, item in ipairs(items) do
                local te = item.textEdit
                if te and item.client_name == 'angularls' then
                  clamp_range(te.range)
                  clamp_range(te.insert)
                  clamp_range(te.replace)
                end
              end
              return items
            end,
          },
        },
      },
    },
  },
}
