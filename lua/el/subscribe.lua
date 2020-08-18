local meta = require('el.meta')
local helper = require('el.helper')

-- TODO:
-- Should not error when the variable doesn't exist
-- Options to not get called for hidden files / etc.

local subscribe = {}

local _current_subscriptions = {}

-- Set to a global to prevent the subscriptions from accidentally getting
-- cleared during hot reloading of the plugin...
--
-- Can probably remove this once the plugin is much more stable.
_ElBufSubscriptions = _ElBufSubscriptions or setmetatable({}, {
  __index = function(t, k)
    rawset(t, k, {})
    return rawget(t, k)
  end
})

local _current_callbacks = {}

--[[

table.insert(el_segment, subsribe.buf_autocmd(
  -- Sets b:el_git_status to the result
  "el_git_status",
  -- Events to fire on
  "BufWritePost",
  -- Function to run
  function(window, buffer)
    return extensions.git_changes(window, buffer)
  end
))


--]]

-- TODO: This doesn't work yet
subscribe.autocmd = function(identifier, name, pattern, callback)
  error()

  if _current_subscriptions[identifier] ~= nil then
    return
  end

  table.insert(_current_callbacks, callback)

  vim.cmd(string.format(
    [[autocmd %s %s :lua require("el.subscribe")._process_callback(%s)]]<
    name,
    pattern,
    table.getn(_current_callbacks)
  ))
end

--- Subscribe to a buffer autocmd with a lua callback.
--
--@param identifier String: name of the variable we'll save to b:
--@param au_events String: The events to subscribe to
--@param callback Callable: A function that takes the (_, Buffer) style callback and returns a value
subscribe.buf_autocmd = function(identifier, au_events, callback)
  return function(_, buffer)
    if _ElBufSubscriptions[buffer.bufnr][identifier] == nil then
      vim.cmd [[augroup ElBufSubscriptions]]
      -- TODO: When we add native lua callbacks to neovim for autocmds, we can make this prettier.
      vim.cmd(string.format(
        [[autocmd %s <buffer=%s> :lua require("el.subscribe")._process_buf_callback(%s, "%s")]],
        au_events, buffer.bufnr, buffer.bufnr, identifier
      ))
      vim.cmd [[augroup END]]

      _ElBufSubscriptions[buffer.bufnr][identifier] = callback

      vim.api.nvim_buf_set_var(buffer.bufnr, identifier, callback(nil, buffer) or '')
    end

    return helper.nvim_buf_get_var(buffer.bufnr, identifier)
  end
end

subscribe._process_callbacks = function(identifier)
end

subscribe._process_buf_callback = function(bufnr, identifier)
  local cb = _ElBufSubscriptions[bufnr][identifier]
  if cb == nil then
    -- TODO: Figure out how this can happen.
    return
  end

  vim.api.nvim_buf_set_var(
    bufnr,
    identifier,
    cb(nil, meta.Buffer:new(bufnr)) or ''
  )
end

subscribe.option_set = function()
end

--[==[
local option_callbacks = setmetatable({}, {
  -- TODO: Could probably use v here.
  __mode = "v"
})

el.option_set_subscribe = function(group, option_pattern, callback)
  table.insert(option_callbacks, callback)
  local callback_number = #option_callbacks

  vim.cmd(string.format([[augroup %s]], group))
  vim.cmd(string.format([[  autocmd OptionSet %s lua el.option_process("<amatch>", %s)]], option_pattern, callback_number))
  vim.cmd               [[augroup END]]
end

el.option_process = function(name, callback_number)
  local option_type = vim.v.option_type
  local option_new = vim.v.option_new

  local opts = {
    option_type = option_type,
    option_new = option_new,
  }

  return option_callbacks[callback_number](name, opts)
end
--]==]

return subscribe
