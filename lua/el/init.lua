-- TODO: Comment out later when stablized
package.loaded['el'] = nil
package.loaded['el.builtin'] = nil
package.loaded['el.sections'] = nil
package.loaded['el.extensions'] = nil
package.loaded['el.meta'] = nil
package.loaded['el.helper'] = nil
package.loaded['luvjob'] = nil

local luvjob = require('luvjob')

local builtin = require('el.builtin')
local extensions = require('el.extensions')
local helper = require('el.helper')
local sections = require('el.sections')
local meta = require('el.meta')

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
-- builtin.modified_tag,
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
    sections.left_subsection {
      highlight = 'Error',
      items = {
        el.extensions.display_win,
      },
    },
    sections.split,
    'This is in the center',
    sections.split,
    helper.async_buf_setter(
      win_id,
      'el_git_stat',
      extensions.git_checker,
      1000
    ),
    sections.collapse_builtin{
      '[',
      builtin.modified_list,
      builtin.help_list,
      builtin.readonly_list,
      ']',
    },
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
    local items = vim.tbl_flatten(status_line_setter(win_id))

    local window = meta.Window:new(win_id)

    self[win_id] = function()
      if not vim.fn.nvim_win_is_valid(win_id) then
        return
      end

      -- Gather up buffer info:
      local buffer = meta.Buffer:new(vim.api.nvim_win_get_buf(win_id))

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
          local result = v(window, buffer)

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
            local _, res = coroutine.resume(thread, window, buffer)

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

      return table.concat(final, "")
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

el.extensions.mode = function(_, buffer)
  local filetype = buffer.filetype

  return el.blocks.highlight(
    (filetype == 'lua' and 'Function')
    or (filetype == 'vim' and 'PMenuSel')
    or 'Error',
    string.format(' [ %%{mode()} ] ')
  )
end

el.extensions.display_win = function(window, _)
  return string.format(" Win ID: %s", window.win_id)
end

el.extensions.git_status = function(_, buffer)
  local filetype = buffer.filetype

  if filetype ~= 'lua' and filetype ~= 'python' then
    return
  end

  local j = luvjob:new({
    command = "git",
    args = {"diff", "--shortstat"},
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  })

  return vim.trim(j:start():co_wait()._raw_output)
end



el.extensions.sleeper = function(wait_time)
  return function(_, _)
    local j = luvjob:new({
      command = "sleep",
      args = {wait_time},
    })

    j:start():co_wait()
  end
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

-- el.option_set_subscribe("filetype", function(opts) print(vim.inspect(opts)) end)

if false then
  vim.wo.statusline = string.format([[%%!luaeval('require("el").run(%s)')]], vim.fn.win_getid())
end

return el
