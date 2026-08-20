vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0

vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2

vim.o.conceallevel = 1

vim.o.termguicolors = true

vim.opt.shortmess:append 'WcCS'

vim.o.hlsearch = false

vim.o.number = true
vim.o.relativenumber = true

vim.o.mouse = 'a'

vim.o.clipboard = 'unnamedplus'

vim.o.breakindent = true

vim.o.undofile = true

vim.o.swapfile = false

vim.o.ignorecase = true
vim.o.smartcase = true

vim.o.signcolumn = 'yes'

vim.o.updatetime = 250
vim.o.timeoutlen = 300

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local local_config = vim.fn.expand '~/.config/nvim/init-local.lua'
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end

require('lazy').setup('plugins', {
  rocks = { enabled = false },
})

vim.cmd.colorscheme 'tokyonight'

local auto_reload_group = vim.api.nvim_create_augroup('AutoReload', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'TermClose', 'TermLeave' }, {
  group = auto_reload_group,
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.bo.filetype ~= 'oil' then
      vim.cmd 'checktime'
    end
  end,
})

vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  pattern = '*',
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.diagnostic.config {
  virtual_text = {
    source = true,
    format = function(diagnostic)
      local code = diagnostic.code or (diagnostic.user_data or {}).code
      if code then
        return string.format('%s %s', code, diagnostic.message)
      end
      return diagnostic.message
    end,
  },
  float = {
    header = 'Diagnostics',
    source = true,
  },
}
