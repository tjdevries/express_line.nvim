
local data = {}

data.modes = {
   n      = {'Normal', 'N', 'NormalMode'},
   no     = {'N·OpPd', '?', 'OpPending' },
   v      = {'Visual', 'V', 'VisualMode'},
   V      = {'V·Line', 'Vl', 'VisualLineMode'},
   [''] = {'V·Blck', 'Vb' },
   s      = {'Select', 'S' },
   S      = {'S·Line', 'Sl' },
   [''] = {'S·Block', 'Sb' },
   i      = {'Insert', 'I', 'InsertMode'},
   ic     = {'ICompl', 'Ic', 'ComplMode'},
   R      = {'Rplace', 'R', 'ReplaceMode'},
   Rv     = {'VRplce', 'Rv' },
   c      = {'Cmmand', 'C', 'CommandMode'},
   cv     = {'Vim Ex', 'E' },
   ce     = {'Ex (r)', 'E' },
   r      = {'Prompt', 'P' },
   rm     = {'More  ', 'M' },
   ['r?'] = {'Cnfirm', 'Cn'},
   ['!']  = {'Shell ', 'S'},
   t      = {'Term  ', 'T', 'TerminalMode'},
}

data.mode_highlights = {
  n      = 'ElNormal',
  no     = 'ElNormalOperatorPending',
  v      = 'ElVisual',
  V      = 'ElVisualLine',
  [''] = 'ElVisualBlock',
  s      = 'ElSelect',
  S      = 'ElSLine',
  [''] = 'ElSBlock',
  i      = 'ElInsert',
  ic     = 'ElInsertCompletion',
  R      = 'ElReplace',
  Rv     = 'ElVirtualReplace',
  c      = 'ElCommand',
  cv     = 'ElCommandCV',
  ce     = 'ElCommandEx',
  r      = 'ElPrompt',
  rm     = 'ElMore',
  ['r?'] = 'ElConfirm',
  ['!']  = 'ElShell',
  t      = 'ElTerm',
}

return data
