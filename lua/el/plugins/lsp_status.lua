local helper = require('el.helper')

local get_current_function = helper.buf_var('lsp_current_function')

local el_lsp_status = {}

el_lsp_status.segment = function(_, buffer)
  if not buffer.lsp then
    return ''
  end

  local ok, result = pcall(function() return require('lsp-status').status() end)
  return ok and result or ''
end

el_lsp_status.current_function = function(_, buffer)
  if not buffer.lsp then
    return ''
  end

  local ok, current_func = pcall(function() return get_current_function(_, buffer) end)
  if ok and current_func then
    return string.format('[ %s ]', current_func)
  end

  return ''
end

return el_lsp_status
