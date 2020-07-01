
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

return data 
