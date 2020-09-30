# express_line.nvim

Life in the fast lane. Don't wait around. Life's too short for you to wait on your statusline.

![Express Line screen](https://raw.githubusercontent.com/tjdevries/media.repo/master/express_line.nvim/rocker_express.png)

## Installation

Requires master branch of Neovim.

```vim
" Note: This used to be luvjob, but plenary is required now.
Plug 'nvim-lua/plenary.nvim'

Plug 'tjdevries/express_line.nvim'
```

## Basic Usage

```lua
-- require this lua file somewhere in your `init.vim`, or use `:lua`

require('el').setup {
  -- An example generator can be seen in `Setup`.
  -- A default one is supplied if you do not want to customize it.
  generator = function(win_id)
    ...
  end
}
```

(At some point I will add some ways to easily configure the defaults.)

## Setup

```lua

local generator = function()
    local el_segments = {}

    -- Statusline options can be of several different types.
    -- Option 1, just a string.

    table.insert(el_segments, '[literal_string]')

    -- Keep in mind, these can be the builtin strings,
    -- which are found in |:help statusline|
    table.insert(el_segments, '%f')

    -- expresss_line provides a helpful wrapper for these.
    -- You can check out el.builtin
    local builtin = require('el.builtin')
    table.insert(el_segments, builtin.file)

    -- Option 2, just a function that returns a string.
    local extensions = require('el.extensions')
    table.insert(el_segments, extensions.mode) -- mode returns the current mode.

    -- Option 3, returns a function that takes in a Window and a Buffer. See |:help el.Window| and |:help el.Buffer|
    --
    -- With this option, you don't have to worry about escaping / calling the function in the correct way to get the current buffer and window.
    local file_namer = function(_window, buffer)
      return buffer.name
    end
    table.insert(el_segments, file_namer)

    -- Option 4, you can return a coroutine.
    --  In lua, you can cooperatively multi-thread.
    --  You can use `coroutine.yield()` to yield execution to another coroutine.
    --
    -- For example, in luvjob.nvim, there is `co_wait` which is a coroutine version of waiting for a job to complete. So you can start multiple jobs at once and wait for them to all be done.
    table.insert(el_segments, extensions.git_changes)

    -- Option 5, there are several helper functions provided to asynchronously
    --  run timers which update buffer or window variables at a certain frequency.
    --
    --  These can be used to set infrequrently updated values without waiting.
    local helper = require("el.helper")
    table.insert(el_segments, helper.async_buf_setter(
      win_id,
      'el_git_stat',
      extensions.git_changes,
      5000
    ))

    return el_segments
end

-- And then when you're all done, just call
require('el').setup { generator = generator }
```

## Extensions

`express_line.nvim` comes with some built-in extensions. You can use them inside your custom generator function.

Taking the following skeleton code as starting point:

```lua
local extensions = require('el.extensions')
local subscribe = require('el.subscribe')
local generator = function(_window, buffer)
   local segments = {}
end
require('el').setup({generator = generator})
```
These are the current extensions you can use in your custom generator function

### Git changes

Outputs a git shortstat output if you are in a git project.

```lua
   -- ...
   table.insert(segments,
    subscribe.buf_autocmd(
      "el_git_status",
      "BufWritePost",
      function(window, buffer)
        return extensions.git_changes(window, buffer)
      end
    ))
    -- ...
```
### Git branch

Outputs a git branch info if you are in a git project.

```lua
   -- ...
   table.insert(segments,
    subscribe.buf_autocmd(
      "el_git_branch",
      "BufEnter",
      function(window, buffer)
        return extensions.git_branch(window, buffer)
      end
    ))
   -- ...
```
### Mode

Mode returns the current mode

```lua
   -- ...
   table.insert(segments, extensions.mode)
    -- ...
```

### File Icon

Depends on [`nvim-web-devicons`](https://github.com/kyazdani42/nvim-web-devicons)

Outputs the ascii icon for the current file based on its filetype

```lua
   -- ...
   table.insert(segments,
    subscribe.buf_autocmd(
      "el_file_icon",
      "BufRead",
      function(_, buffer)
        return extensions.file_icon(_, buffer)
      end
    ))
```
