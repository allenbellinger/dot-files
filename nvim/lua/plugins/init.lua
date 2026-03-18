return {
  'tpope/vim-rhubarb',
  'aserowy/tmux.nvim',
  'tpope/vim-sleuth',
  'nvim-tree/nvim-web-devicons',
  'Canop/nvim-bacon',

  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },
  {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load on lua files
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
        documentation = { auto_show = false, auto_show_delay_ms = 500 },
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
              -- insert text instead of overwriting what comes after the cursor
              local cursor_col = ctx.cursor[2]
              for _, item in ipairs(items) do
                if item.client_id then
                  local client = vim.lsp.get_client_by_id(item.client_id)
                  if client and client.name == 'angularls' then
                    local te = item.textEdit
                    if te then
                      local range = te.range or te.replace
                      if range and range['end'].character > cursor_col then
                        range['end'].character = cursor_col
                      end
                      if te.insert and te.insert['end'].character > cursor_col then
                        te.insert['end'].character = cursor_col
                      end
                      if te.replace and te.replace['end'].character > cursor_col then
                        te.replace['end'].character = cursor_col
                      end
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
    'numToStr/Comment.nvim',
    opts = {},
    lazy = false,
  },
  {
    'folke/which-key.nvim',
    opts = {},
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = true,
      format_on_save = { timeout_ms = 2500 },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        css = { 'prettierd' },
        scss = { 'prettierd' },
        html = { 'prettierd' },
        htmlangular = { 'prettierd' },
        json = { 'prettierd' },
        rust = { 'rustfmt' },
        markdown = { 'prettierd' },
      },
    },
  },
}
