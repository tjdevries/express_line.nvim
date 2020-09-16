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

--- Add highlight to some contents.
--@param higroup String|table: Name of the highlight group.
--                              If string, then always set to this highlight group
--                              If table, keys are `active` and `inactive` for different highlights
--@param contents String: The value of the contents
sections.highlight = function(higroup, contents)
  if type(higroup) == "string" then
    return string.format('%s#%s#%s%%*', '%', higroup, contents)
  elseif type(higroup) == "table" then
    return function(_, buffer)
      if buffer.is_active then
        return sections.highlight(higroup.active, contents)
      else
        return sections.highlight(higroup.inactive, contents)
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

return sections
