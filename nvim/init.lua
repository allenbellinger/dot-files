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
  performance = {
    rtp = {
      disabled_plugins = {
      },
    },
  },
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

-- Disable swap files and always continue when stale swaps exist
vim.o.swapfile = false
vim.api.nvim_create_autocmd('SwapExists', {
  callback = function()
    vim.v.swapchoice = 'e'
  end,
})

local function delete_old_swap_files(days, notify_result)
  local cutoff = os.time() - (days * 24 * 60 * 60)

  local dirs = {
    vim.fn.stdpath('state') .. '/swap',
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

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    delete_old_swap_files(3, false)
  end,
})

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

-- Auto-reload files changed outside of Neovim
vim.o.autoread = true
local auto_reload_group = vim.api.nvim_create_augroup('AutoReload', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
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
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
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

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
