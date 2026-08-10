-- Highlight other references to the symbol under the cursor.
-- Replaces the hand-rolled LSP documentHighlight driver that used to live in
-- lua/treesitter_highlight.lua. Providers cascade LSP -> treesitter -> regex,
-- so this still works in buffers with no language server attached.
return {
  'RRethy/vim-illuminate',
  event = { 'BufReadPost', 'BufNewFile' },
  config = function()
    -- NOTE: the entry point is `configure`, not `setup`, so lazy.nvim's `opts`
    -- and `main` shortcuts cannot be used here.
    require('illuminate').configure {
      providers = { 'lsp', 'treesitter', 'regex' },
      delay = 120,
      under_cursor = true,
      large_file_cutoff = 2000,
      large_file_overrides = { providers = { 'lsp' } },
      filetypes_denylist = {
        'DiffviewFiles',
        'help',
        'lazy',
        'mason',
        'oil',
        'snacks_dashboard',
        'snacks_picker_list',
        'trouble',
      },
    }

    -- Match the look of the previous custom implementation, and re-apply on
    -- every colorscheme load (the old code set these exactly once at startup).
    local group = vim.api.nvim_create_augroup('IlluminateHighlights', { clear = true })
    local function link_groups()
      for _, name in ipairs { 'IlluminatedWordText', 'IlluminatedWordRead', 'IlluminatedWordWrite' } do
        vim.api.nvim_set_hl(0, name, { link = 'CursorLine' })
      end
    end

    vim.api.nvim_create_autocmd('ColorScheme', { group = group, callback = link_groups })
    link_groups()
  end,
  keys = {
    {
      ']]',
      function()
        require('illuminate').goto_next_reference(false)
      end,
      desc = 'Next reference',
      mode = { 'n', 'x', 'o' },
    },
    {
      '[[',
      function()
        require('illuminate').goto_prev_reference(false)
      end,
      desc = 'Previous reference',
      mode = { 'n', 'x', 'o' },
    },
  },
}
