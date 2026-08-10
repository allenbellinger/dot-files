-- Code actions with a diff preview, replacing lspsaga's code_action.
--
-- delta renders the diff with real syntax highlighting and emits ANSI, which the
-- snacks previewer displays in a terminal. The `vim` backend can only produce a
-- plain diff, and the `diff` treesitter grammar has no language injections, so
-- it can never colour the code inside a hunk.
--
-- The `buffer` picker reuses one preview buffer and calls nvim_open_term on it,
-- which throws "Terminal already connected to buffer" for every action with no
-- preview; the snacks picker scratches a fresh buffer per preview.
return {
  'rachartier/tiny-code-action.nvim',
  event = 'LspAttach',
  opts = {
    backend = 'delta',
    backend_opts = {
      delta = {
        -- Bundled with delta, so no theme file or `bat cache` is needed. Much
        -- closer to tokyonight than delta's Monokai Extended default.
        --
        -- NOTE: `args` is a list, so tbl_deep_extend replaces it wholesale
        -- rather than merging -- `--line-numbers` has to be repeated to keep
        -- the plugin default. `header_lines_to_remove` is map-like and does
        -- deep-merge, so it keeps its default of 4, which is what strips
        -- delta's tempfile-path header.
        args = { '--line-numbers', '--syntax-theme', 'Catppuccin Mocha' },
      },
    },
    picker = 'snacks',
  },
}
