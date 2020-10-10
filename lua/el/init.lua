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
      local val = setmetatable({}, {
        __index = function(win_table, bufnr)
          log.debug("Generating statusline for:", win_id, bufnr)

          if not el.statusline_generator then
            log.debug("No statusline_generator for now")
            return function() return '' end
          end

          -- Gather up functions to use when evaluating statusline
          local window = meta.Window:new(win_id)
          local buffer = meta.Buffer:new(bufnr)
          local items = vim.tbl_flatten(el.statusline_generator(window, buffer))

          local p = processor.new(items, window, buffer)

          rawset(win_table, bufnr, p)
          return p
        end,
      })

      rawset(self, win_id, val)
      return val
    end,
  })
end

el._window_status_lines = get_new_windows_table()

el.reset_windows = function()
  subscribe._reload()

  el._window_status_lines = get_new_windows_table()
end

el.regenerate = function(win_id, bufnr)
  if not win_id or win_id == 0 then
    win_id = vim.api.nvim_get_current_win()
  end

  if not bufnr then
    -- Clear everything for the window
    el._window_status_lines[win_id] = nil
    return
  end

  if bufnr == 0 then
    bufnr = vim.api.nvim_win_get_buf(win_id)
  end
  el._window_status_lines[win_id][bufnr] = nil
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
  if not vim.api.nvim_win_is_valid(win_id) then
    return
  end

  local bufnr = vim.api.nvim_win_get_buf(win_id)

  return el._window_status_lines[win_id][bufnr]()
end

el.setup = function(opts)
  opts = opts or {}

  local generator = opts.generator or default_statusline_generator
  vim.validate { generator = { generator, 'f' } }

  -- TODO: In the future, probably want some easier ways to give users to regenerate their statusline based on some
  -- events. For now, they can write their own autocmds or just call `require('el').regenerate(win_id, bufnr)`
  local regenerate_autocmds = opts.regenerate_autocmds or {} 

  el.statusline_generator = generator
  el.reset_windows()

  -- Setup autocmds to make sure
  vim.cmd [=[augroup ExpressLineAutoSetup]=]
  vim.cmd [=[  au!]=]
  vim.cmd [=[  autocmd BufWinEnter,WinEnter * :lua vim.wo.statusline = string.format([[%%!luaeval('require("el").run(%s)')]], vim.api.nvim_get_current_win()) ]=]

  for _, event in ipairs(regenerate_autocmds) do
    vim.cmd(string.format(
          [=[  autocmd %s * :lua require('el').regenerate(vim.api.nvim_get_current_win())]=],
          event
    ))
  end

  vim.cmd [=[augroup END]=]

  vim.cmd [[doautocmd BufWinEnter]]
end

el._test = function()
  require('plenary.reload').reload_module('el', true)

  require('el').setup()
end


return el
