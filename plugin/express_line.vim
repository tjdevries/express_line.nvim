lua el = require("el")

augroup ExpressLineAutoSetup
  au!
  autocmd BufWinEnter * :lua vim.wo.statusline = string.format('%%!v:lua.el.run(%s)', vim.fn.win_getid())
augroup END

