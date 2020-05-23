
--   { NF  Evaluate expression between '%{' and '}' and substitute result.
--         Note that there is no '%' before the closing '}'.
--   ( -   Start of item group.  Can be used for setting the width and
--         alignment of a section.  Must be followed by %) somewhere.
--   ) -   End of item group.  No width fields allowed.

--   < -   Where to truncate line if too long.  Default is at the start.
--         No width fields allowed.

--   = -   Separation point between alignment sections. Each section will
--         be separated by an equal number of spaces.
--         No width fields allowed.


-- Highlights
--   # -   Set highlight group.  The name must follow and then a # again.
--         Thus use %#HLname# for highlight group HLname.  The same
--         highlighting is used, also for the statusline of non-current
--         windows.
--   * -   Set highlight group to User{N}, where {N} is taken from the
--         minwid field, e.g. %1*.  Restore normal highlight with %* or %0*.
--         The difference between User{N} and StatusLine  will be applied
--         to StatusLineNC for the statusline of non-current windows.
--         The number N must be between 1 and 9.  See |hl-User1..9|


-- Remove this?
_ = [[
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
]]
