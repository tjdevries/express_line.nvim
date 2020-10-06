local builtin = require('el.builtin')
local extensions = require('el.extensions')
local log = require('el.log')
local meta = require('el.meta')
local processor = require('el.processor')
local sections = require('el.sections')
local subscribe = require('el.subscribe')

local lsp_statusline = require('el.plugins.lsp_status')

local el = {}

-- Types of functions:
-- 0. Just a string.
-- 1. Just returns a string (built-in statusline stuff. Can't beat it)
-- 2. Just returns a function (calls some simple thing, fast enough to run in process)
-- 3. Returns a coroutine (calls something that might take short amount of time, so don't block if other stuff can run)
-- 4. Returns a variable reference, gets updated via timer / autocmds / other.

-- Stream goals:
--  1. Need to add color to the mode thingy.
--  2. Write some documentation.
--  3. Autocmd subscriber (subscribe to list of autocmds, one-shot update something, displayed in statusline)
--  4. on_exit provider for jobstart to set the value when you're done.

-- Long term goals:
--  tabline (shout out to @KD)


local get_new_windows_table = function()
  return setmetatable({}, {
    __index = function(self, win_id)
      log.debug("Generating statusline for:", win_id)

      if not el.statusline_generator then
        log.debug("No statusline_generator for now")
        return function() return '' end
      end

      -- Gather up functions to use when evaluating statusline
      local items = vim.tbl_flatten(el.statusline_generator(win_id))

      local window = meta.Window:new(win_id)

      self[win_id] = processor.new(items, window)

      return self[win_id]
    end,
  })
end

el._window_status_lines = get_new_windows_table()

el.reset_windows = function()
  subscribe._reload()

  el._window_status_lines = get_new_windows_table()
end

local default_statusline_generator = function(win_id)
  return {
    extensions.mode,
    sections.split,
    builtin.file,
    sections.collapse_builtin {
      ' ',
      builtin.modified_flag
    },
    sections.split,
    lsp_statusline.segment,
    lsp_statusline.current_function,
    subscribe.buf_autocmd(
      "el_git_status",
      "BufWritePost",
      function(window, buffer)
        return extensions.git_changes(window, buffer)
      end
    ),
    -- helper.async_buf_setter(
    --   win_id,
    --   'el_git_stat',
    --   extensions.git_changes,
    --   5000
    -- ),
    '[', builtin.line, ' : ',  builtin.column, ']',
    sections.collapse_builtin{
      '[',
      builtin.help_list,
      builtin.readonly_list,
      ']',
    },
    builtin.filetype,
  }
end

el.run = function(win_id)
  return el._window_status_lines[win_id]()
end

el.setup = function(opts)
  opts = opts or {}

  local generator = opts.generator or default_statusline_generator
  vim.validate { generator = { generator, 'f' } }

  el.statusline_generator = generator
  el.reset_windows()

  -- Setup autocmds to make sure 
  vim.cmd [=[augroup ExpressLineAutoSetup]=]
  vim.cmd [=[  au!]=]
  vim.cmd [=[  autocmd BufWinEnter,WinEnter * :lua vim.wo.statusline = string.format([[%%!luaeval('require("el").run(%s)')]], vim.fn.win_getid()) ]=]
  vim.cmd [=[augroup END]=]

  vim.cmd [[doautocmd BufWinEnter]]
end

el._test = function()
  require('plenary.reload').reload_module('el', true)

  require('el').setup()
end


return el
