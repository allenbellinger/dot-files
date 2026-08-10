-- Highlight, edit, and navigate code
return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install {
        'angular',
        'css',
        -- Diff buffers (diffview, gitsigns diffthis, `git diff` output).
        'diff',
        'git_config',
        'git_rebase',
        'gitcommit',
        'html',
        'java',
        'javascript',
        'json',
        'lua',
        'markdown',
        'markdown_inline',
        'python',
        'rust',
        'scss',
        'toml',
        'typescript',
        'yaml',
      }

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('TreesitterStart', { clear = true }),
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
    keys = {
      { '<leader>ti', vim.treesitter.inspect_tree, desc = '[T]reesitter [I]nspect tree' },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      local function select_textobject(capture)
        require('nvim-treesitter-textobjects.select').select_textobject(capture, 'textobjects')
      end

      require('nvim-treesitter-textobjects').setup {
        select = {
          lookahead = true,
        },
      }

      vim.keymap.set({ 'x', 'o' }, 'af', function()
        select_textobject '@function.outer'
      end)
      vim.keymap.set({ 'x', 'o' }, 'if', function()
        select_textobject '@function.inner'
      end)
    end,
  },
}
