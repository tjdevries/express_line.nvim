local Job = require "plenary.job"

local modes = require("el.data").modes
local mode_highlights = require("el.data").mode_highlights
local sections = require "el.sections"

local extensions = {}

local git_insertions = vim.regex [[\(\d\+\)\( insertion\)\@=]]
local git_changed = vim.regex [[\(\d\+\)\( file changed\)\@=]]
local git_deletions = vim.regex [[\(\d\+\)\( deletion\)\@=]]

local parse_shortstat_output = function(s)
  local result = {}

  local insert = { git_insertions:match_str(s) }
  if not vim.tbl_isempty(insert) then
    table.insert(result, string.format("%s", string.sub(s, insert[1] + 1, insert[2])))
  end

  local changed = { git_changed:match_str(s) }
  if not vim.tbl_isempty(changed) then
    table.insert(result, string.format("%s", string.sub(s, changed[1] + 1, changed[2])))
  end

  local delete = { git_deletions:match_str(s) }
  if not vim.tbl_isempty(delete) then
    table.insert(result, string.format("%s", string.sub(s, delete[1] + 1, delete[2])))
  end

  if not vim.tbl_isempty(result) then
    return result
  end
end

local get_changes = function(_, buffer)
  if
    vim.api.nvim_buf_get_option(buffer.bufnr, "bufhidden") ~= ""
    or vim.api.nvim_buf_get_option(buffer.bufnr, "buftype") == "nofile"
  then
    return
  end

  if vim.fn.filereadable(buffer.name) ~= 1 then
    return
  end

  local j = Job:new {
    command = "git",
    args = { "diff", "--shortstat", buffer.name },
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  }

  return vim.trim(j:sync()[1])
end

extensions.git_changes = function(_, buffer)
  local ok, result = pcall(function()
    return parse_shortstat_output(get_changes(_, buffer))
  end)

  if ok then
    if result then
      return string.format("[+%s, ~%s, -%s]", result[1], result[2], result[3])
    end
  end
end

extensions.git_inserstions = function(_, buffer)
  local ok, result = pcall(function()
    return parse_shortstat_output(get_changes(_, buffer))
  end)

  if ok then
    if result[1] then
      return result[1]
    end
  end
end

extensions.git_modifications = function(_, buffer)
  local ok, result = pcall(function()
    return parse_shortstat_output(get_changes(_, buffer))
  end)
  if ok then
    if result[2] then
      return result[2]
    end
  end
end

extensions.git_deletions = function(_, buffer)
  local ok, result = pcall(function()
    return parse_shortstat_output(get_changes(_, buffer))
  end)

  if ok then
    if result[3] then
      return result[3]
    end
  end
end

extensions.git_branch = function(_, buffer)
  local j = Job:new {
    command = "git",
    args = { "branch", "--show-current" },
    cwd = vim.fn.fnamemodify(buffer.name, ":h"),
  }

  local ok, result = pcall(function()
    return vim.trim(j:sync()[1])
  end)

  if ok then
    return result
  end
end

local mode_dispatch = setmetatable({}, {
  __index = function(parent, format_string)
    local dispatcher = setmetatable({}, {
      __index = function(child, k)
        local higroup = mode_highlights[k]
        local inactive_higroup = higroup .. "Inactive"

        local display_name = modes[k][1]
        local contents = string.format(format_string, display_name)
        local highlighter = sections.gen_one_highlight(contents)

        local val = function(window, buffer)
          return highlighter(window, buffer, (window.is_active and higroup) or inactive_higroup)
        end

        rawset(child, k, val)
        return val
      end,
    })

    rawset(parent, format_string, dispatcher)
    return dispatcher
  end,
})

extensions.gen_mode = function(opts)
  opts = opts or {}

  local format_string = opts.format_string or "[%s]"

  return function(window, buffer)
    local mode = vim.api.nvim_get_mode().mode
    return mode_dispatch[format_string][mode](window, buffer)
  end
end

extensions.mode = extensions.gen_mode()

extensions.file_icon = function(_, buffer)
  local ok, icon = pcall(function()
    return require("nvim-web-devicons").get_icon(buffer.name, buffer.extension, { default = true })
  end)
  return ok and icon or ""
end

extensions.git_icon = function(_, _)
  local ok, icon = pcall(function()
    return require("nvim-web-devicons").get_icon ".gitattributes"
  end)
  return ok and icon or ""
end

return extensions
