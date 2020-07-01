package.loaded['el._log'] = nil

local log = {}
local function do_log(level, fmt, ...)
  local file = io.open(vim.fn.stdpath('data') .. '/expressline.log', 'a')

  file:write(string.format(
    "%s : %s\n",
    level,
    string.format(fmt, ...)
  ))

  file:close()
end

log.info = function(fmt, ...)
  do_log('info', fmt, ...)
end

return log
