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
        'rust',
        'scss',
        'toml',
        'typescript',
        'yaml',
      }

      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })

      require('treesitter_highlight').setup()
    end,
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
