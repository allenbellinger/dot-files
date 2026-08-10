-- Highlights the innermost named treesitter node under the cursor, similar to
-- `:InspectTree`'s source-buffer highlight and the old (now archived)
-- nvim-treesitter-refactor `highlight_current_scope` module.
--
-- Reference/definition highlighting is NOT handled here -- see
-- lua/plugins/illuminate.lua.
local M = {}

local ns = vim.api.nvim_create_namespace 'ts_node_highlight'

local function named_node_at_cursor()
  local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
  if not ok then
    return nil
  end
  while node and not node:named() do
    node = node:parent()
  end
  return node
end

local function skip(node)
  local node_type = node:type():lower()
  if node_type == 'program' or node_type == 'source_file' then
    return true
  end

  -- Multi-line strings are almost always noise: the whole block lights up.
  local sr, _, er, _ = node:range()
  if node_type:find('string', 1, true) and er > sr then
    return true
  end

  return false
end

local function clear(buf)
  vim.api.nvim_buf_clear_namespace(buf or 0, ns, 0, -1)
end

local function highlight()
  local buf = vim.api.nvim_get_current_buf()

  -- Bail before touching the namespace so we do not pay a clear on every
  -- cursor move in buffers that can never be highlighted anyway.
  if vim.bo[buf].buftype ~= '' then
    return
  end
  if not vim.treesitter.highlighter.active[buf] then
    return
  end

  clear(buf)

  local node = named_node_at_cursor()
  if not node or skip(node) then
    return
  end

  local sr, sc, er, ec = node:range()
  vim.api.nvim_buf_set_extmark(buf, ns, sr, sc, {
    end_row = er,
    end_col = ec,
    hl_group = 'CursorLine',
    hl_eol = false,
    priority = 1,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup('TsNodeHighlight', { clear = true })

  vim.api.nvim_create_autocmd('CursorMoved', {
    group = group,
    callback = highlight,
  })

  -- The old implementation left the highlight painted while typing.
  vim.api.nvim_create_autocmd({ 'InsertEnter', 'BufLeave' }, {
    group = group,
    callback = function(args)
      clear(args.buf)
    end,
  })
end

return M
