lua el = require("el")

highlight default link ElNormal Function
highlight default link ElInsert MsgSeparator
highlight default link ElCommand Constant

augroup ExpressLineAutoSetup
  au!
  autocmd BufWinEnter * :lua vim.wo.statusline = string.format('%%!v:lua.el.run(%s)', vim.fn.win_getid())
augroup END

