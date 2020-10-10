local log = require('el.log')
local processor = require('el.processor')

local sections = {}

sections.split = '%='

sections.collapse_builtin = function(items)
  return {'%(', items, '%)'}
end

sections.left_subsection = function(config)
  vim.validate {
    items = { config.items, 't' },

    highlight = { config.highlight, 's', true },
    divider = { config.divider, 's', true },
    builtin_only = { config.builtin_only, 'b', true },
  }

  local divider = config.divider or '>>'
  local highlight = config.highlight or nil
  local builtin_only = config.builtin_only or nil

  local to_insert = {}

  if highlight ~= nil then
    table.insert(to_insert, string.format('%%#%s#', highlight))
  end

  table.insert(to_insert, config.items)
  table.insert(to_insert, string.format(' %s ', divider))

  if highlight ~= nil then
    table.insert(to_insert, '%*')
  end

  if builtin_only then
    to_insert = sections.collapse_builtin(to_insert)
  end

  return to_insert
end


sections.gen_one_highlight = function(contents)
  if type(contents) == "string" then
    return function(_, _, higroup)
      return string.format('%s#%s#%s%%*', '%', higroup, contents)
    end
  elseif type(contents) == "function" then
    return function(window, buffer, higroup)
      return string.format('%s#%s#%s%%*', '%', higroup, contents(window, buffer))
    end
  --[[
  elseif type(contents) == "table" then
    -- TODO: This might not work with nested tables ? 
    return function()
      -- return table.concat(vim.tbl_flatten(contents), '')
      return '<tbl>'
    end
  --]]
  else
    error(debug.traceback("Invalid type: " .. type(contents) .. vim.inspect(contents)))
  end
end

--- Add highlight to some contents.
--@param higroup String|table: Name of the highlight group.
--                              If string, then always set to this highlight group
--                              If table, keys are `active` and `inactive` for different highlights
--@param contents String: The value of the contents
sections.highlight = function(higroup, contents)
  if type(higroup) == "string" then
    if type(contents) == "table" then
      local resolved = {}
      for _, highlighted_item in ipairs(contents) do
        table.insert(resolved, sections.gen_one_highlight(highlighted_item))
      end

      return function(window, buffer)
        local highlights = {}
        for _, v in ipairs(resolved) do
          table.insert(highlights, v(higroup, window, buffer))
        end

        return table.concat(highlights, '')
      end
    else
      local resolved = sections.gen_one_highlight(contents)
      return function(window, buffer)
        return resolved(window, buffer, higroup)
      end
    end
  elseif type(higroup) == "table" then
    local resolved = sections.gen_one_highlight(contents)

    return function(window, buffer)
      local is_active
      if window then
        is_active = window.is_active
      elseif buffer then
        is_active = buffer.is_active
      end

      if is_active then
        return resolved(window, buffer, higroup.active)
      else
        return resolved(window, buffer, higroup.inactive)
      end
    end
  else
    error("unexpected higroup: " .. tostring(higroup))
  end
end

--- Filetype only sections.
---@param filetypes string|table If string, then only the name of the filetype
---                              If table, then list of filetypes
---@param contents string|function  If string, return it.
---                                 If function, call function(win, buf)
sections.filetype = function(filetypes, contents)
  local acceptable_fts = {}
  if type(filetypes) == 'string' then
    acceptable_fts[filetypes] = true
  else
    for _, ft in ipairs(filetypes) do
      acceptable_fts[ft] = true
    end
  end

  return function(window, buffer)
    if not acceptable_fts[buffer.filetype] then
      return
    end

    if type(contents) == 'string' then
      return contents
    else
      return contents(window, buffer)
    end
  end
end

--- Maximum width sections
--- max_width:
---     - percentage of window
---     - absolute number of characters
---     - generic function of your choosing
sections.maximum_width = function(contents, max_width, opts)
  assert(max_width, "max_width is required")

  opts = opts or {}

  local trailing = opts.trailing or '…'
  if not trailing then
    trailing = ''
  end

  local get_cutoff
  if type(max_width) == 'number' then
    if max_width < 1 then
      get_cutoff = function(window)
        return math.ceil(max_width * vim.api.nvim_win_get_width(window.win_id))
      end
    else
      get_cutoff = function() return max_width end
    end
  elseif type(max_width) == 'function' then
    get_cutoff = max_width
  end

  local truncate_right = opts.truncate_right

  return function(window, buffer)
    local ok, value = processor.resolve(contents, window, buffer)

    if not ok then
      return nil
    end

    local cutoff = get_cutoff(window, buffer)

    return value, function(result)
      local len = #result
      if len > cutoff then
        if truncate_right then
          return string.sub(result, 1, cutoff + 1) .. trailing
        else
          return trailing .. string.sub(result, len - cutoff, len)
        end
      end

      return result
    end
  end
end

return sections
