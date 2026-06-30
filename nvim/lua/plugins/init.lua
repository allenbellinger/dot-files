return {
  'tpope/vim-sleuth',
  {
    'echasnovski/mini.icons',
    lazy = false,
    config = function()
      require('mini.icons').setup()
      MiniIcons.mock_nvim_web_devicons()
    end,
  },
  'Canop/nvim-bacon',
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },
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
    event = { 'InsertEnter', 'CmdlineEnter' },
    dependencies = {
      'folke/lazydev.nvim',
    },
    opts = {
      keymap = { preset = 'default' },
      appearance = {
        nerd_font_variant = 'mono',
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
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
              -- Clamp angularls textEdit ranges to the cursor so completions
              -- insert text instead of overwriting what comes after the cursor.
              -- Angular LS returns ranges that can span multiple lines, so we
              -- must clamp both the end line and end character.
              local cursor_line = ctx.cursor[1] - 1 -- 0-indexed line (LSP uses 0-indexed)
              local cursor_col = ctx.cursor[2] -- 0-indexed col (LSP uses 0-indexed)

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
      fuzzy = { implementation = 'prefer_rust' },
      signature = { enabled = true },
    },
  },
  {
    'nvim-java/nvim-java',
    ft = 'java',
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
      'mason-org/mason-lspconfig.nvim',
    },
    config = function()
      require('java').setup()
      vim.lsp.enable 'jdtls'
    end,
  },

  {
    'folke/which-key.nvim',
    opts = {},
  },
  {
    'folke/trouble.nvim',
    opts = {
      win = {
        wo = {
          wrap = true,
        },
      },
    },
    cmd = 'Trouble',
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    opts = {
      format_on_save = {
        timeout_ms = 2500,
      },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        css = { 'prettierd', 'stylelint' },
        scss = { 'prettierd', 'stylelint' },
        html = { 'prettierd' },
        htmlangular = { 'prettierd' },
        json = { 'prettierd' },
        jsonc = { 'prettierd' },
        python = { 'ruff_format', 'ruff_organize_imports' },
        rust = { 'rustfmt' },
        markdown = { 'prettierd' },
      },
    },
  },
}
