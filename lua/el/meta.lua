package.loaded['el.meta'] = nil

-- General Idea:
--
-- Buffer
--  Wrapper around common buffer operations
--  Should make it super speedy fast, and not have to re-evaluate all the time
--
--  For example,
--
--      local buffer = Buffer:new(bufnr)
--      buffer.bufnr == bufnr
--      if buffer.filetype == 'lua' then print("Yo, it's lua") end
--
--  The thing is, `filetype` gets looked up only once and we pass the buffer object around to the calls.
--


-- Other TODO:
--  Should be possible to attach your own "lookups" to buffer,
--      so that you can get the same (sometimes expensive) behavior.
--
--      For example, whether this buffer contains a file in a git directory.
--          buffer.is_git => function(buffer) return can_find_dot_git(buffer.path) end
local meta = {}

local buf_lookups = {
  filetype = function(buffer)
    return vim.api.nvim_buf_get_option(buffer.bufnr, 'filetype')
  end
}


local Buffer = {}

local buf_mt = {
  __index = function(t, k)
    local result = nil

    if Buffer[k] ~= nil then
      result = Buffer[k]
    elseif buf_lookups[k] ~= nil then
      result = buf_lookups[k](t)
    end

    t[k] = result
    return t[k]
  end
}


function Buffer:new(bufnr)
  return setmetatable({
      bufnr = bufnr,
    },
    buf_mt
  )
end

meta.Buffer = Buffer

return meta
