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

              -- ts_ls labels private fields `#foo` (the label is the raw
              -- `entry.name`) but the replacement range it returns starts
              -- *after* the `#` already typed, so accepting yields `this.##foo`.
              -- Widening the range start by one swallows the typed `#`.
              --
              -- All three range fields are covered on purpose: ts_ls emits an
              -- InsertReplaceEdit (`insert`/`replace`, no `range`) when the
              -- client advertises insertReplaceSupport -- blink does -- and a
              -- plain TextEdit (`range` only) when tsserver supplies a
              -- replacementSpan. blink then collapses the former down to
              -- `insert` unless `completion.keyword.range` is 'full', so
              -- `insert` is the one that actually gets applied here.
              local function shift_start(range)
                local start = range and range.start
                if start and start.character > 0 then
                  start.character = start.character - 1
                end
              end

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

              -- Both fixups share a pass: they touch disjoint clients, and even
              -- on an overlap `shift_start` only moves `start` while
              -- `clamp_range` only moves `end`.
              for _, item in ipairs(items) do
                local te = item.textEdit
                local client = item.client_id and vim.lsp.get_client_by_id(item.client_id)
                if te and client then
                  if client.name == 'ts_ls' and vim.startswith(item.label or '', '#') then
                    shift_start(te.range)
                    shift_start(te.insert)
                    shift_start(te.replace)
                  end

                  if client.name == 'angularls' then
                    clamp_range(te.range)
                    clamp_range(te.insert)
                    clamp_range(te.replace)
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
