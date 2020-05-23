local meta = require('el.meta')

local helper = {}

helper.buf_var = function(var_name)
  return function(_, buffer)
    local ok, result = pcall(function()
      return vim.api.nvim_buf_get_var(buffer.bufnr, var_name)
    end)

    if ok then
      return result
    end
  end
end

helper.win_var = function(var_name)
  return function(window)
    local ok, result = pcall(function()
      return vim.api.nvim_win_get_var(window.win_id, var_name)
    end)

    if ok then
      return result
    end
  end
end


--- { [win_id, buf_id, timer_name] = timer }
_ElRunningTimers = _ElRunningTimers or {}
function helper.__ClearElTimers()
  table.foreach(_ElRunningTimers, function(k, v)
    v.timer:stop()
    v.timer:close()

    _ElRunningTimers[k] = nil
  end)
end

local async_setter = function(association)
  local setter_func
  if association == 'win' then
    setter_func = function(window, _, var_name, result)
      return vim.api.nvim_win_set_var(window.win_id, var_name, result)
    end
  elseif association == 'buf' then
    setter_func = function(_, buffer, var_name, result)
      return vim.api.nvim_buf_set_var(buffer.bufnr, var_name, result)
    end
  else
    error(string.format("Unsupported associated: ", association))
  end

  local helper_func
  if association == 'win' then
    helper_func = helper.win_var
  elseif association == 'buf' then
    helper_func = helper.buf_var
  else
    error(string.format("Unsupported associated: ", association))
  end

  return function(win_id, var_name, f, refresh_rate)
    local timer_index = string.format("%s:%s:%s", association, win_id, var_name)
    local timer = vim.loop.new_timer()

    -- Clear any existing timers that exist for this.
    if _ElRunningTimers[timer_index] ~= nil then
      local existing_timer = _ElRunningTimers[timer_index].timer

      pcall(function()
        existing_timer:stop()
        existing_timer:close()
      end)

      -- Clear value
      _ElRunningTimers[timer_index] = nil
    end

    _ElRunningTimers[timer_index] = { started_at = vim.fn.strftime("%c"), timer = timer}

    timer:start(0, refresh_rate, vim.schedule_wrap(function()
      -- TODO: Find some way to share these w/ the rest of the calls.
      local window = meta.Window:new(win_id)
      local buffer = meta.Buffer:new(vim.api.nvim_win_get_buf(win_id))

      local ok, result = pcall(f, window, buffer)

      if ok then
        setter_func(window, buffer, var_name, result)
      else
        timer:stop()
        timer:close()

        _ElRunningTimers[timer_index] = nil
      end
    end))

    return helper_func(var_name)
  end
end

helper.async_win_setter = async_setter("win")
helper.async_buf_setter = async_setter("buf")

return helper
