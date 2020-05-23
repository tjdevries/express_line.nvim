-- TODO: Comment out later when stablized
package.loaded['el'] = nil
package.loaded['el.builtin'] = nil
package.loaded['el.sections'] = nil
package.loaded['luvjob'] = nil

local luvjob = require('luvjob')

local builtin = require('el.builtin')
local sections = require('el.sections')

local el = {}

-- Types of functions:
-- 1. Just returns a string (built-in statusline stuff. Can't beat it)
-- 2. Just returns a function (calls some simple thing, fast enough to run in process)
-- 3. Returns a coroutine (calls something that might take short amount of time, so don't block if other stuff can run)
-- 4. Returns a variable reference, gets updated via timer / autocmds / other.
--
-- TODO:
-- Autocmd subscriber (subscribe to list of autocmds, one-shot update something, displayed in statusline)
-- on_exit provider for jobstart to set the value when you're done.

-- builtin.file,
-- builtin.modified,
-- builtin.filetype,
-- builtin.filetype_list,
-- el.helper.buf_var('el_tester'),
-- el.helper.win_var('el_win_tester'),
-- el.helper.async_win_setter(
--   win_id,
--   'el_current_time',
--   function() return vim.fn.localtime() end,
--   5000
-- ),
-- el.helper.async_buf_setter(
--   win_id,
--   'el_git_status',
--   el.extensions.git_checker,
--   1000
-- ),
-- }

-- Default status line setter.
local status_line_setter = function(win_id)
  return {
    el.extensions.mode,
    sections.split,
    'This is in the center',
    sections.split,
    builtin.modified,
    builtin.filetype,
  }
end

el.set_statusline_generator = function(item_generator)
  vim.validate { item_generator = { item_generator, 'f' } }

  status_line_setter = item_generator
end

el._window_status_lines = setmetatable({}, {
  __index = function(self, win_id)
    -- Gather up functions to use when evaluating statusline
    local items = status_line_setter(win_id)

    self[win_id] = function()
      -- Gather up buffer info:
      local bufnr = vim.api.nvim_win_get_buf(win_id)

      -- Start up variable referencers
      -- Start up coroutine dudes
      -- Collect functions
      -- Return strings

      local waiting = {}

      local statusline = {}
      table.foreach(items, function(k, v)
        if type(v) == 'string' then
          statusline[k] = v
        elseif type(v) == 'function' then
          local result = v(win_id, bufnr)

          if type(result) == 'thread' then
            table.insert(waiting, { index = k, thread = result })
          else
            statusline[k] = result
          end
        end
      end)

      local remaining = table.getn(waiting)
      local completed = 0

      local start = os.time()
      while start + 2 > os.time() do
        if remaining == completed then
          break
        end

        for i = 1, remaining do
          local wait_val = waiting[i]

          if wait_val ~= nil then
            local index, thread = wait_val.index, wait_val.thread
            local _, res = coroutine.resume(thread, win_id, bufnr)

            if coroutine.status(thread) == 'dead' then
              statusline[index] = res

              -- Remove
              completed = completed + 1
              waiting[i] = nil
            end
          end
        end
      end

      -- Filter out nil values and do fast concat
      local final = {}
      table.foreach(statusline, function(_, v)
        if v == nil then
          return
        end

        table.insert(final, v)
      end)

      return table.concat(final, " | ")
    end

    return self[win_id]
  end,
})

el.results = {}

el.blocks = {}

el.blocks.highlight = function(name, contents)
  return string.format('%s#%s#%s%%*', '%', name, contents)
end

el.new_extension = function(global)
end


el.extensions = {}

el.extensions.mode = function(win_id, bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  return el.blocks.highlight(
    (filetype == 'lua' and 'Function')
    or (filetype == 'vim' and 'PMenuSel')
    or 'Error',
    string.format(' [ %%{mode()} ] ')
  )
end

el.extensions.display_win = function(win_id, _)
  return string.format(" Win ID: %s", win_id)
end

el.extensions.git_status = function(win_id, bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  if filetype ~= 'lua' and filetype ~= 'python' then
    return
  end

  local j = luvjob:new({
    command = "git",
    args = {"diff", "--shortstat"},
    cwd = vim.fn.fnamemodify(vim.fn.nvim_buf_get_name(bufnr), ":h"),
  })

  return vim.trim(j:start():co_wait()._raw_output)
end


el.extensions.git_checker = function(win_id, bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  if filetype ~= 'lua' and filetype ~= 'python' then
    return
  end

  local j = luvjob:new({
    command = "git",
    args = {"diff", "--shortstat"},
    cwd = vim.fn.fnamemodify(vim.fn.nvim_buf_get_name(bufnr), ":h"),
  })

  return vim.trim(j:start():wait()._raw_output)
end

el.extensions.sleeper = function(wait_time)
  return function(win_id, bufnr)
    local j = luvjob:new({
      command = "sleep",
      args = {wait_time},
    })

    j:start():co_wait()
  end
end


el.helper = {}

el.helper.buf_var = function(var_name)
  return function(_, bufnr)
    local ok, result = pcall(function() return vim.api.nvim_buf_get_var(bufnr, var_name) end)

    if ok then
      return result
    end
  end
end

el.helper.win_var = function(var_name)
  return function(win_id)
    local ok, result = pcall(function() return vim.api.nvim_win_get_var(win_id, var_name) end)

    if ok then
      return result
    end
  end
end


--- { [win_id, buf_id, timer_name] = timer }
_ElRunningTimers = _ElRunningTimers or {}
function ClearElTimers()
  table.foreach(_ElRunningTimers, function(k, v)
    v.timer:stop()
    v.timer:close()

    _ElRunningTimers[k] = nil
  end)
end

local async_setter = function(association)
  local setter_func
  if association == 'win' then
    setter_func = function(win_id, _, var_name, result)
      return vim.api.nvim_win_set_var(win_id, var_name, result)
    end
  elseif association == 'buf' then
    setter_func = function(_, bufnr, var_name, result)
      return vim.api.nvim_buf_set_var(bufnr, var_name, result)
    end
  else
    error(string.format("Unsupported associated: ", association))
  end

  local helper_func
  if association == 'win' then
    helper_func = el.helper.win_var
  elseif association == 'buf' then
    helper_func = el.helper.buf_var
  else
    error(string.format("Unsupported associated: ", association))
  end

  return function(win_id, var_name, f, refresh_rate)
    local timer_index = string.format("%s:%s:%s", association, win_id, var_name)
    local timer = vim.loop.new_timer()

    -- Clear any existing timers that exist for this.
    if _ElRunningTimers[timer_index] ~= nil then
      local existing_timer = _ElRunningTimers[timer_index].timer

      existing_timer:stop()
      existing_timer:close()

      -- Clear value
      _ElRunningTimers[timer_index] = nil
    end

    _ElRunningTimers[timer_index] = { started_at = vim.fn.strftime("%c"), timer = timer}

    timer:start(0, refresh_rate, vim.schedule_wrap(function()
      local bufnr = vim.api.nvim_win_get_buf(win_id)

      local ok, result = pcall(f, win_id, bufnr)

      if ok then
        setter_func(win_id, bufnr, var_name, result)
      else
        timer:stop()
        timer:close()

        _ElRunningTimers[timer_index] = nil
      end
    end))

    return helper_func(var_name)
  end
end

el.helper.async_win_setter = async_setter("win")
el.helper.async_buf_setter = async_setter("buf")

el.helper.cacher = function(win_id, var, f, refresh_rate)
  local timer = nil

  return function()
    if timer == nil then
      timer = vim.loop.new_timer()
      timer:start(1, refresh_rate, vim.schedule_wrap(function()
        local ok, result = pcall(f)

        if not ok then
          timer:stop()
          timer:close()

          -- TODO: Log errors
          vim.api.nvim_win_set_var(win_id, '_el_error', result)

          return
        end


        local current_cache = vim.api.nvim_win_get_var(win_id, '_el_cache')
        current_cache[var] = result

        vim.api.nvim_win_set_var(win_id, '_el_cache', current_cache)
      end))
    end

    return vim.w._el_cache[var]
  end
end

el.set_statusline = function(win_id, items)
  local bufnr = vim.api.nvim_win_get_buf(win_id)

  local items_remaining = {}
  for _, v in ipairs(items) do
    if vim.is_callable(v) then
      table.insert(items_remaining, coroutine.create(v))
    else
      table.insert(items_remaining, v)
    end
  end

  local completed = 0
  local remaining = table.getn(items_remaining)

  local statusline = {}
  table.foreach(
    items_remaining,
    function(k, v)
      if type(v) == 'thread' then
        table.insert(statusline, '')
      else
        table.insert(statusline, v)
        items_remaining[k] = nil

        completed = completed + 1
      end
    end
  )

  vim.fn.nvim_win_set_var(win_id, 'remaining', remaining)

  local start = os.time()
  while start + 2 > os.time() do
    if remaining == completed then
      break
    end

    for i = 1, remaining do
      local v = items_remaining[i]

      if v ~= nil then
        if coroutine.status(v) ~= 'dead' then
          local status, res = coroutine.resume(v, win_id, bufnr)

          if res ~= nil then
            statusline[i] = statusline[i] .. res
          end

          if coroutine.status(v) == 'dead' then
            completed = completed + 1

            -- Remove
            items_remaining[i] = nil
          end
        end
      end
    end
  end

  vim.fn.nvim_win_set_var(win_id, 'result', statusline)

  local final = {}
  table.foreach(statusline, function(k, v)
    if v == nil then
      return
    end

    final[k] = v
  end)

  return table.concat(final, " ")
end

el.run = function(win_id)
  return el._window_status_lines[win_id]()
end


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

el.option_set_subscribe("filetype", function(opts) print(vim.inspect(opts)) end)

if false then
  vim.wo.statusline = string.format([[%%!luaeval('require("el").run(%s)')]], vim.fn.win_getid())
end
-- vim.cmd[[augroup ExpressLineAu]]
-- vim.cmd[[  au!]]
-- vim.cmd[[  autocmd BufEnter,BufWinEnter * :lua vim.wo.statusline = string.format('%%!v:lua.el.test(%s)', vim.fn.win_getid())]]
-- vim.cmd[[augroup END]]

return el
