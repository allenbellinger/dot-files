-- Default indentation (vim-sleuth will override per-buffer based on file contents)
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.textwidth = 80
--Set <space> as the leader key See `:help mapleader` NOTE: Must happen before
--plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable unused remote providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0

vim.opt.conceallevel = 1

-- Install package manager
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)
vim.opt.relativenumber = true

local local_config = vim.fn.expand '~/.config/nvim/init-local.lua'
if vim.fn.filereadable(local_config) == 1 then
  vim.cmd('source ' .. local_config)
end

require('lazy').setup('plugins', {
  rocks = { enabled = false },
})

-- [[ Setting options ]]
-- See `:help vim.o`

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

local format_on_save_ts = vim.api.nvim_create_augroup('fmt-ts', {})
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.ts', '*.js' },
  callback = function(args)
    local clients = vim.lsp.get_clients { bufnr = args.buf, name = 'eslint' }
    if #clients > 0 then
      vim.cmd 'silent! EslintFixAll'
    end
  end,
  group = format_on_save_ts,
})

-- [[ Diagnostic display configuration ]]
vim.diagnostic.config {
  virtual_text = {
    source = true,
    format = function(diagnostic)
      if diagnostic.user_data and diagnostic.user_data.code then
        return string.format('%s %s', diagnostic.user_data.code, diagnostic.message)
      else
        return diagnostic.message
      end
    end,
  },
  signs = true,
  float = {
    header = 'Diagnostics',
    source = true,
    border = 'rounded',
  },
}

-- LuaSnip keymaps (deferred until LuaSnip is loaded)
vim.api.nvim_create_autocmd('User', {
  pattern = 'LazyLoad',
  callback = function(args)
    if args.data ~= 'LuaSnip' then
      return
    end
    local luasnip = require 'luasnip'
    vim.keymap.set({ 'i', 's' }, '<Tab>', function()
      if luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Tab>', true, false, true), 'n', false)
      end
    end, { silent = true })

    vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<S-Tab>', true, false, true), 'n', false)
      end
    end, { silent = true })
    return true -- remove this autocmd after firing
  end,
})

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
