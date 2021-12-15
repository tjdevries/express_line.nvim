local meta = require('el.meta')

local helper = {}

helper.nvim_buf_get_var = function(bufnr, var_name)
  local ok, result = pcall(function()
    return vim.api.nvim_buf_get_var(bufnr, var_name)
  end)

  if ok then
    return result
  end
end

helper.buf_var = function(var_name)
  return function(_, buffer)
    return helper.nvim_buf_get_var(buffer.bufnr, var_name)
  end
end

helper.nvim_win_get_var = function(win_id, var_name)
  local ok, result = pcall(function()
    return vim.api.nvim_win_get_var(win_id, var_name)
  end)

  if ok then
    return result
  end
end

helper.win_var = function(var_name)
  return function(window, _)
    return helper.nvim_win_get_var(window.win_id, var_name)
  end
end


--- { [win_id, buf_id, timer_name] = timer }
_ElRunningTimers = _ElRunningTimers or {}
function helper.__ClearElTimers()
  table.foreach(_ElRunningTimers, function(k, _)
    helper.__clear_timer(k)
  end)
end

function helper.__clear_timer(k)
  if _ElRunningTimers[k] == nil then
    return
  end

  local existing_timer = _ElRunningTimers[k].timer

  pcall(function()
    existing_timer:stop()
    existing_timer:close()
  end)

  -- Clear value
  _ElRunningTimers[k] = nil
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
      helper.__clear_timer(timer_index)
    end

    _ElRunningTimers[timer_index] = { started_at = vim.fn.strftime("%c"), timer = timer}

    timer:start(0, refresh_rate, vim.schedule_wrap(function()
      if not vim.api.nvim_win_is_valid(win_id) then
        helper.__clear_timer(timer_index)
        return
      end

      -- TODO: Find some way to share these w/ the rest of the calls.
      local window = meta.Window:new(win_id)
      local buffer = meta.Buffer:new(vim.api.nvim_win_get_buf(win_id))

      local ok, result = pcall(f, window, buffer)

      if ok then
        setter_func(window, buffer, var_name, result)
      else
        helper.__clear_timer(timer_index)
      end
    end))

    return helper_func(var_name)
  end
end

helper.async_win_setter = async_setter("win")
helper.async_buf_setter = async_setter("buf")

-- add trailing '/' to path if not already there
local path_add_trailing = function(path)
  if path:sub(-1) == '/' then
    return path
  end

  return path..'/'
end

--  replace - and . characters with %- and %. for lua to match paths properly
local path_to_matching_str = function(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end


-- returns path relative to relative_to
-- or the unmodified path if path is not under relative_to
helper.path_relative = function(path, relative_to)
  local p, _ = path:gsub("^" .. path_to_matching_str(path_add_trailing(relative_to)), "")
  return p
end

return helper
