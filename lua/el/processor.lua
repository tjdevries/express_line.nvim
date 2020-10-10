local meta = require('el.meta')

local processor = {}

function processor.new(items, window, buffer)
  local win_id = window.win_id

  return function()
    if not vim.api.nvim_win_is_valid(win_id) then
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
    local effects = {}
    for k, v in ipairs(items) do
      local ok, result, effect = processor.resolve(v, window, buffer)

      if not ok then
        statusline[k] = ''
      else
        if type(result) == 'thread' then
          table.insert(waiting, {
            index = k,
            thread = result,
            effect = effect
          })
        else
          statusline[k], effects[k] = result, effect
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
    for k, v in ipairs(statusline) do
      if v == nil then
        return
      end

      if effects[k] then
        v = effects[k](v)
      end

      table.insert(final, v)
    end

    return table.concat(final, "")
  end
end

processor.resolve = function(value, window, buffer)
  if type(value) == 'string' then
    return true, value
  elseif type(value) == 'function' then
    return pcall(value, window, buffer)
  else
    -- error("Unsupported type")
    return false
  end
end

return processor
