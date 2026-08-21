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
    event = { 'InsertEnter', 'CmdlineEnter' },
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

              -- Completing `this.#fo` used to insert `this.##foo`. With `#fo`
              -- already typed, tsserver returns no replacementSpan, so ts_ls
              -- sends the item with no textEdit and no insertText, and strips
              -- the leading `#` from filterText (`#myField` -> `myField`).
              -- blink then has to guess the edit range: it takes the inserted
              -- text from `insertText or label` (`#myField`) but derives the
              -- range from `insertText or filterText or label` (`myField`), so
              -- the range starts *after* the typed `#` while the inserted text
              -- still carries one.
              --
              -- Pinning insertText to the label makes both sides agree, so the
              -- guessed range extends back over the `#`. filterText is left
              -- alone so fuzzy matching still scores against `myField`, which
              -- is what the keyword under the cursor looks like (`#` is not in
              -- 'iskeyword').
              local function restore_private_prefix(item)
                if item.textEdit == nil and item.insertText == nil then
                  item.insertText = item.label
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

              -- Both fixups share a pass: they touch disjoint clients.
              for _, item in ipairs(items) do
                if item.client_name == 'ts_ls' and vim.startswith(item.label or '', '#') then
                  restore_private_prefix(item)
                end

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
