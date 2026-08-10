--Set <space> as the leader key See `:help mapleader` NOTE: Must happen before
--plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable unused remote providers
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: options are set *before* lazy.nvim loads plugins, so that things like
-- `termguicolors` are already in effect when a colorscheme is applied.

-- Default indentation (vim-sleuth will override per-buffer based on file contents)
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.shiftwidth = 2
vim.o.textwidth = 0

vim.o.conceallevel = 1

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- Suppress common messages that noice used to filter
vim.opt.shortmess:append 'WcCS'

-- Set highlight on search
vim.o.hlsearch = false

-- Line numbers
vim.o.number = true
vim.o.relativenumber = true

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

-- Disable swap files and always continue when stale swaps exist
vim.o.swapfile = false

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Auto-reload files changed outside of Neovim
vim.o.autoread = true

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

local local_config = vim.fn.expand '~/.config/nvim/init-local.lua'
if vim.fn.filereadable(local_config) == 1 then
  dofile(local_config)
end

require('lazy').setup('plugins', {
  rocks = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {},
    },
  },
})

-- [[ Treesitter node-under-cursor highlight ]]
require('ts_node_highlight').setup()

-- [[ Swap files ]]
local swap_group = vim.api.nvim_create_augroup('SwapHandling', { clear = true })
vim.api.nvim_create_autocmd('SwapExists', {
  group = swap_group,
  callback = function()
    vim.v.swapchoice = 'e'
  end,
})

-- `swapfile` is off, so Neovim never writes swaps itself; this only reaps files
-- left behind by other editors or by older configs. Runs automatically on
-- VeryLazy, and on demand via `:DeleteOldSwapFiles [days]`.
local function delete_old_swap_files(days, notify_result)
  local cutoff = os.time() - (days * 24 * 60 * 60)

  local dirs = {
    vim.fn.stdpath 'state' .. '/swap',
    '/tmp',
    '/var/tmp',
  }

  for _, entry in ipairs(vim.split(vim.o.directory, ',', { trimempty = true })) do
    local dir = vim.fn.expand(entry)
    if dir ~= '.' then
      table.insert(dirs, dir)
    end
  end

  local seen = {}
  local deleted = 0

  for _, dir in ipairs(dirs) do
    if vim.fn.isdirectory(dir) == 1 then
      local patterns = {
        dir .. '/.*.sw?',
        dir .. '/*.sw?',
      }

      for _, pattern in ipairs(patterns) do
        for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
          if not seen[path] then
            seen[path] = true
            local stat = vim.uv.fs_stat(path)
            if stat and stat.type == 'file' and stat.mtime and stat.mtime.sec <= cutoff then
              local ok = vim.uv.fs_unlink(path)
              if ok then
                deleted = deleted + 1
              end
            end
          end
        end
      end
    end
  end

  if notify_result or deleted > 0 then
    vim.notify(string.format('Deleted %d swap file(s) older than %d day(s)', deleted, days), vim.log.levels.INFO)
  end
end

vim.api.nvim_create_user_command('DeleteOldSwapFiles', function(opts)
  local days = tonumber(opts.args) or 1
  delete_old_swap_files(days, true)
end, {
  nargs = '?',
  desc = 'Delete stale swap files older than N days (default: 1)',
})

-- Sweep once the UI is up rather than on VimEnter, so it never sits on the
-- startup path. Silent unless it actually deletes something.
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  group = swap_group,
  once = true,
  callback = function()
    delete_old_swap_files(3, false)
  end,
})

-- [[ Auto-reload files changed outside of Neovim ]]
local auto_reload_group = vim.api.nvim_create_augroup('AutoReload', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'TermClose', 'TermLeave' }, {
  group = auto_reload_group,
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.bo.filetype ~= 'oil' then
      vim.cmd 'checktime'
    end
  end,
})

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- [[ Highlight on yank ]]
-- See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
  pattern = '*',
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Diagnostic display configuration ]]
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
  signs = true,
  float = {
    header = 'Diagnostics',
    source = true,
    border = 'rounded',
  },
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
