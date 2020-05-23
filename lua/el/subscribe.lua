local subscribe = {}

local _current_subscriptions = {}
local _current_callbacks = {}

subscribe.autocmd = function(identifier, name, pattern, callback)
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

subscribe._process_callbacks

subscribe.option_set = function()
end

return subscribe
