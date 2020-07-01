package.loaded['el.plugins.lsp_status'] = nil

local helper = require('el.helper')

local get_current_function = helper.buf_var('lsp_current_function')

local el_lsp_status = {}

el_lsp_status.segment = function(_, buffer)
  if not buffer.lsp then
    return ''
  end

  return require('lsp-status').status()
end

el_lsp_status.current_function = function(_, buffer)
  if not buffer.lsp then
    return ''
  end

  local current_func = get_current_function(_, buffer)
  if current_func then
    return string.format('[ %s ]', current_func)
  end

  return ''
end

return el_lsp_status
