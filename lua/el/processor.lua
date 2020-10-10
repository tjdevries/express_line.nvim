local meta = require('el.meta')

local processor = {}

function processor.new(items, window, buffer)
  local win_id = window.win_id

  return function()
    if not vim.fn.nvim_win_is_valid(win_id) then
      return
    end

    -- Gather up buffer info:
    buffer = meta.Buffer:new(buffer.bufnr)

    -- Start up variable referencers
    -- Start up coroutine dudes
    -- Collect functions
    -- Return strings

    local waiting = {}

    local statusline = {}
    for k, v in ipairs(items) do
      if type(v) == 'string' then
        statusline[k] = v
      elseif type(v) == 'function' then
        local ok, result = pcall(v, window, buffer)

        if not ok then
          statusline[k] = ''
        end

        if type(result) == 'thread' then
          table.insert(waiting, { index = k, thread = result })
        else
          statusline[k] = result
        end
      end
    end

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
end

return processor
