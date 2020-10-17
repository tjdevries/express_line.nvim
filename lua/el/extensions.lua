local Job = require('plenary.job')

local modes = require('el.data').modes
local mode_highlights = require('el.data').mode_highlights
local sections = require('el.sections')

local extensions = {}

local git_changed = vim.regex([[\(\d\+\)\( file changed\)\@=]])
local git_insertions = vim.regex([[\(\d\+\)\( insertions\)\@=]])
local git_deletions = vim.regex([[\(\d\+\)\( deletions\)\@=]])

local parse_shortstat_output = function(s)
  local result = {}

  local changed = {git_changed:match_str(s)}
  if not vim.tbl_isempty(changed) then
    table.insert(result, string.format('+%s', string.sub(s, changed[1] + 1, changed[2])))
  end

  local insert = {git_insertions:match_str(s)}
  if not vim.tbl_isempty(insert) then
    table.insert(result, string.format('~%s', string.sub(s, insert[1] + 1, insert[2])))
  end

  local delete = {git_deletions:match_str(s)}
  if not vim.tbl_isempty(delete) then
    table.insert(result, string.format('-%s', string.sub(s, delete[1] + 1, delete[2])))
  end

  if vim.tbl_isempty(result) then
    return nil
  end

  return string.format("[%s]", table.concat(result, ", "))
end

extensions.git_changes = function(_, buffer)
  if vim.api.nvim_buf_get_option(buffer.bufnr, 'bufhidden') ~= ""
      or vim.api.nvim_buf_get_option(buffer.bufnr, 'buftype') == 'nofile' then
    return
  end

  if vim.fn.filereadable(buffer.name) ~= 1 then
    return
  end

  local j = Job:new({
    command = "git",
    args = {"diff", "--shortstat", buffer.name},
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  })

  local ok, result = pcall(function()
    return parse_shortstat_output(vim.trim(j:sync()[1]))
  end)

  if ok then
    return result
  end
end


extensions.git_branch = function(_, buffer)
  local j = Job:new({
    command = "git",
    args = {"branch", "--show-current"},
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  })

  local ok, result = pcall(function()
    return vim.trim(j:sync()[1])
  end)

  if ok then
    return result
  end
end


local _dispatcher = setmetatable({}, {
  __index = function(child, k)
    local higroup = mode_highlights[k]
    local inactive_higroup = higroup .. "Inactive"

    local display_name = modes[k][1]
    local contents = string.format(format_string, display_name)
    local highlighter = sections.gen_one_highlight(contents)

    local previous_value

    local val = function(window, buffer)
      local is_active = vim.api.nvim_get_current_win() == window.win_id
      if is_active ~= window.is_active then
        print("UHHH>>>>>>>")
      end

      if not window.is_active and previous_value then
        return previous_value
      end

      previous_value = highlighter(
        window,
        buffer,
        (window.is_active and higroup) or inactive_higroup
      )

      return previous_value
    end

    rawset(child, k, val)
    return val
  end
})

local get_dispatcher = function()
  local count = 0

  return coroutine.wrap(function(mode, window, buffer)
    local previous_value = nil

    while true do
      if not window.is_active and previous_value then
        coroutine.yield(previous_value)
      end

      previous_value = count
      count = count + 1
      coroutine.yield(tostring(count))
    end
  end)
end

local mode_dispatch = setmetatable({}, {
  __index = function(parent, format_string)
    local window_table = setmetatable({}, {
      __index = function(format_table, win_id)
        local dispatcher = get_dispatcher()

        rawset(format_table, win_id, dispatcher)
        return dispatcher
      end
    })

    rawset(parent, format_string, window_table)
    return window_table
  end
})

extensions.gen_mode = function(opts)
  opts = opts or {}

  local format_string = opts.format_string or '[%s]'

  return function(window, buffer)
    local mode = vim.api.nvim_get_mode().mode
    return mode_dispatch[format_string][window.win_id](mode, window, buffer)
  end
end

extensions.mode = extensions.gen_mode()

extensions.file_icon = function(_, buffer)
  local ok, icon = pcall(function()
    return require('nvim-web-devicons').get_icon(
      buffer.name,
      buffer.extension,
      {default = true}
    )
  end)
  return ok and icon or ''
end

extensions.git_icon = function(_, buffer)
  local ok, icon = pcall(function()
    return require('nvim-web-devicons').get_icon(
      '.gitattributes'
    )
  end)
  return ok and icon or ''
end

return extensions
