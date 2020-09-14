local helper = require('el.helper')

local get_current_function = helper.buf_var('lsp_current_function')
local has_lsp_status, lsp_status = pcall(require, 'lsp-status')

local el_lsp_status = {}

el_lsp_status.segment = function(_, buffer)
  if not buffer.lsp or not has_lsp_status then
    return ''
  end

  local ok, result = pcall(lsp_status.status)
  return ok and result or ''
end

el_lsp_status.current_function = function(_, buffer)
  if not buffer.lsp or not has_lsp_status then
    return ''
  end

  local ok, current_func = pcall(get_current_function, _, buffer)
  if ok and current_func and #current_func > 0 then
    return string.format('[ %s ]', current_func)
  end

  return ''
end

el_lsp_status.server_progress = function(_, buffer)
  if not buffer.lsp or not has_lsp_status then
    return ''
  end

  local buffer_clients = vim.lsp.buf_get_clients(buffer.bufnr)
  local buffer_client_set = {}
  for _, v in pairs(buffer_clients) do
    buffer_client_set[v.name] = true
  end

  local all_messages = lsp_status.messages()

  for _, msg in ipairs(all_messages) do
    if msg.name and buffer_client_set[msg.name] then
      local contents = ''
      if msg.progress then
        contents = msg.title
        if msg.message then
          contents = contents .. ' ' .. msg.message
        end

        if msg.percentage then
          contents = contents .. ' (' .. msg.percentage .. ')'
        end

--         if msg.spinner then
--           contents = config.spinner_frames[(msg.spinner % #config.spinner_frames) + 1] .. ' ' .. contents
--         end
      elseif msg.status then
        contents = msg.content
      else
        contents = msg.content
      end

      return ' ' .. contents .. ' '
    end
  end

  return ''
end

return el_lsp_status
