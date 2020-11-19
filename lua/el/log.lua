return require('plenary.log').new {
  -- Name of the plugin. Prepended to log messages
  plugin = 'el',

  -- Should print the output to neovim while running
  use_console = false,

  -- Should highlighting be used in console (using echohl)
  highlights = false,

  -- Should write to a file
  use_file = true,

  -- Any messages above this level will be logged.
  -- Log more stuff for TJ, everyone else can just get warnings :)
  level = (vim.loop.os_getenv("USER") == 'tj' and 'debug') or 'warn',

  -- Level configuration
  modes = {
    { name = "trace", hl = "Comment", },
    { name = "debug", hl = "Comment", },
    { name = "info",  hl = "None", },
    { name = "warn",  hl = "WarningMsg", },
    { name = "error", hl = "ErrorMsg", },
    { name = "fatal", hl = "ErrorMsg", },
  },

  -- Can limit the number of decimals displayed for floats
  float_precision = 0.01,
}
