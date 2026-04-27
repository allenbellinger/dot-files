local M = {}

local scope_ns = vim.api.nvim_create_namespace 'ts_scope_highlight'

local function named_node_at_cursor()
  local node = vim.treesitter.get_node { ignore_injections = false }
  while node and not node:named() do
    node = node:parent()
  end
  return node
end

local function skip_scope_highlight(node)
  local node_type = node:type():lower()
  if node_type == 'program' or node_type == 'source_file' then
    return true
  end

  local sr, _, er, _ = node:range()
  if node_type:find('string', 1, true) and er > sr then
    return true
  end

  return false
end

local function highlight_scope()
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, scope_ns, 0, -1)

  local node = named_node_at_cursor()
  if not node or skip_scope_highlight(node) then
    return
  end

  local sr, sc, er, ec = node:range()
  vim.api.nvim_buf_set_extmark(buf, scope_ns, sr, sc, {
    end_row = er,
    end_col = ec,
    hl_group = 'CursorLine',
    hl_eol = false,
    priority = 1,
  })
end

local function is_identifier_like(node)
  local node_type = node:type():lower()
  if node_type:find('identifier', 1, true) then
    return true
  end

  return node_type == 'this' or node_type == 'super'
end

local function should_highlight_refs()
  local node = named_node_at_cursor()
  if not node then
    return false
  end
  return is_identifier_like(node)
end

local function setup_lsp_reference_highlight()
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local bufnr = args.buf
      local supports_highlight = #vim.lsp.get_clients {
        bufnr = bufnr,
        method = 'textDocument/documentHighlight',
      } > 0

      if not supports_highlight then
        return
      end

      local group = vim.api.nvim_create_augroup('LspDocumentHighlight' .. bufnr, { clear = true })
      local last_symbol_key = nil

      local function clear_refs()
        last_symbol_key = nil
        vim.lsp.buf.clear_references()
      end

      local function current_symbol_key()
        local node = named_node_at_cursor()
        if not node or not is_identifier_like(node) then
          return nil
        end

        local sr, sc, er, ec = node:range()
        local tick = vim.api.nvim_buf_get_changedtick(bufnr)
        return table.concat({ bufnr, tick, sr, sc, er, ec }, ':')
      end

      local function refresh_refs()
        local key = current_symbol_key()

        if not key then
          if last_symbol_key ~= nil then
            clear_refs()
          end
          return
        end

        if key == last_symbol_key then
          return
        end

        last_symbol_key = key
        vim.lsp.buf.clear_references()
        vim.lsp.buf.document_highlight()
      end

      vim.api.nvim_create_autocmd('CursorMoved', {
        group = group,
        buffer = bufnr,
        callback = refresh_refs,
      })

      vim.api.nvim_create_autocmd({ 'InsertEnter', 'BufLeave' }, {
        group = group,
        buffer = bufnr,
        callback = clear_refs,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = group,
        buffer = bufnr,
        callback = function()
          clear_refs()
          pcall(vim.api.nvim_del_augroup_by_id, group)
        end,
      })
    end,
  })
end

function M.setup()
  for _, group in ipairs { 'LspReferenceText', 'LspReferenceRead', 'LspReferenceWrite' } do
    vim.api.nvim_set_hl(0, group, { link = 'CursorLine' })
  end

  vim.api.nvim_create_autocmd('CursorMoved', {
    callback = highlight_scope,
  })

  setup_lsp_reference_highlight()
end

return M
