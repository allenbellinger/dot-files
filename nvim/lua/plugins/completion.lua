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
    version = '1.*',
    event = 'VeryLazy',
    dependencies = {
      'folke/lazydev.nvim',
    },
    opts = {
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 0 },
        accept = {
          auto_brackets = {
            enabled = false,
          },
        },
      },
      sources = {
        default = { 'lsp', 'path', 'lazydev' },
        providers = {
          lazydev = { name = 'LazyDev', module = 'lazydev.integrations.blink', score_offset = 100 },
          lsp = {
            transform_items = function(ctx, items)
              local cursor_line = ctx.cursor[1] - 1
              local cursor_col = ctx.cursor[2]

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
                if item.client_id then
                  local client = vim.lsp.get_client_by_id(item.client_id)
                  if client and client.name == 'angularls' then
                    local te = item.textEdit
                    if te then
                      clamp_range(te.range)
                      clamp_range(te.insert)
                      clamp_range(te.replace)
                    end
                  end
                end
              end
              return items
            end,
          },
        },
      },
      signature = { enabled = true },
    },
  },
}
