package.loaded['luvjob'] = nil
local luvjob = require('luvjob')

el = {}

el.results = {}

el.blocks = {}

el.blocks.highlight = function(name, contents)
  return string.format('%s#%s#%s%%*', '%', name, contents)
end

el.new_extension = function(global)
end

el.extensions = {}

el.extensions.file = function()
  return '%f'
end

el.extensions.mode = function(win_id, bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  return el.blocks.highlight(
    (filetype == 'lua' and 'Function')
    or (filetype == 'vim' and 'PMenuSel')
    or 'Error',
    string.format('[ %%{mode()} ] ')
  )
end

el.extensions.display_win = function(win_id, _)
  return string.format(" Win ID: %s", win_id)
end

el.extensions.git_status = function(win_id, bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

  if filetype ~= 'lua' and filetype ~= 'python' then
    return
  end

  local j = luvjob:new({
    command = "git",
    args = {"status", "--porcelain"},
    cwd = vim.fn.fnamemodify(vim.fn.nvim_buf_get_name(bufnr), ":h"),
  })

  return j:start():co_wait()._raw_output
end

el.extensions.sleeper = function(wait_time)
  return function(win_id, bufnr)
    local j = luvjob:new({
      command = "sleep",
      args = {wait_time},
    })

    j:start():co_wait()
  end
end

el.set_statusline = function(win_id, coros)
  local bufnr = vim.api.nvim_win_get_buf(win_id)

  local coros_remaining = {}
  for _, v in ipairs(coros) do
    table.insert(coros_remaining, coroutine.create(v))
  end

  local statusline = {}
  table.foreach(coros_remaining, function() table.insert(statusline, '') end)

  local remaining = table.getn(coros_remaining)
  vim.fn.nvim_win_set_var(win_id, 'remaining', remaining)

  local completed = 0

  local start = os.time()
  while start + 2 > os.time() do
    if remaining == completed then
      break
    end

    for i = 1, remaining do
      local v = coros_remaining[i]

      if coroutine.status(v) ~= 'dead' then
        local status, res = coroutine.resume(v, win_id, bufnr)

        if res ~= nil then
          statusline[i] = statusline[i] .. res
        end

        if coroutine.status(v) == 'dead' then
          completed = completed + 1
        end
      end
    end
  end

  vim.fn.nvim_win_set_var(win_id, 'result', statusline)

  return table.concat(statusline, " ", 1, remaining)
end

el.test = function(win_id)
  return el.set_statusline(
    win_id
    , {
      el.extensions.mode,
      el.extensions.file,
      el.extensions.display_win,
      el.extensions.git_status,
      -- el.extensions.sleeper("0.01s"),
    }
    -- , el.extensions.sleeper("0.2s")
    -- , el.extensions.sleeper("0.1s")
  )
end

-- vim.wo.statusline = string.format('%%!v:lua.el.test(%s)', vim.api.nvim_win_get_number(0))
-- vim.cmd[[augroup ExpressLineAu]]
-- vim.cmd[[  au!]]
-- vim.cmd[[  autocmd BufEnter,BufWinEnter * :lua vim.wo.statusline = string.format('%%!v:lua.el.test(%s)', vim.fn.win_getid())]]
-- vim.cmd[[augroup END]]

return el
