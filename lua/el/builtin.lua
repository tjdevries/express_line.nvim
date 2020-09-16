local builtin = {}

--   f S   Path to the file in the buffer, as typed or relative to current
--         directory.
builtin.file = '%f'
builtin.file_relative = '%f'

--   F S   Full path to the file in the buffer.
builtin.full_file = '%F'

builtin.shortened_file = function(_, buffer)
  return vim.fn.pathshorten(buffer.name)
end

builtin.tail_file = function(_, buffer)
  return vim.fn.fnamemodify(buffer.name, ':t')
end

builtin.responsive_file = function(shortened_transition, tail_transition)
  if tail_transition == nil then
    tail_transition = 0
  end

  return function(window, buffer)
    if window.width  < tail_transition then
      return builtin.tail_file(window, buffer)
    elseif window.width < shortened_transition then
      return builtin.shortened_file(window, buffer)
    else
      return builtin.file
    end
  end
end

--   t S   File name (tail) of file in the buffer.
builtin.tail = '%t'

--   m F   Modified flag, text is "[+]"; "[-]" if 'modifiable' is off.
builtin.modified = '%m'
builtin.modified_flag = '%m'

--   M F   Modified flag, text is ",+" or ",-".
builtin.modified_list = '%M'

--   r F   Readonly flag, text is "[RO]".
builtin.readonly = '%r'
builtin.readonly_flag = '%r'

--   R F   Readonly flag, text is ",RO".
builtin.readonly_list = '%R'

--   h F   Help buffer flag, text is "[help]".
builtin.help = '%h'
builtin.help_flag = '%h'

--   H F   Help buffer flag, text is ",HLP".
builtin.help_list = '%H'

--   w F   Preview window flag, text is "[Preview]".
builtin.preview = '%w'
builtin.preview_flag = '%w'

--   W F   Preview window flag, text is ",PRV".
builtin.preview_list = '%W'

--   y F   Type of file in the buffer, e.g., "[vim]".  See 'filetype'.
builtin.filetype = '%y'
builtin.filetype_flag = '%y'

--   Y F   Type of file in the buffer, e.g., ",VIM".  See 'filetype'.
builtin.filetype_list = '%Y'

--   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.quickfix = '%q'
builtin.quickfix_flag = '%q'

builtin.locationlist = '%q'
builtin.locationlist_flag = '%q'

--   k S   Value of "b:keymap_name" or 'keymap' when |:lmap| mappings are being used: "<keymap>"
builtin.keymap = '%k'

--   n N   Buffer number.
builtin.bufnr = '%n'
builtin.buffer_number = '%n'

--   b N   Value of character under cursor.
builtin.character = '%b'
builtin.character_decimal = '%b'

--   B N   As above, in hexadecimal.
builtin.character_hex = '%B'

--   o N   Byte number in file of byte under cursor, first byte is 1.
--         Mnemonic: Offset from start of file (with one added)
builtin.byte_number = '%o'
builtin.byte_number_decimal = '%o'

--   O N   As above, in hexadecimal.
builtin.byte_number_hex = '%O'

--   N N   Printer page number.  (Only works in the 'printheader' option.)
builtin.printer_page = '%N'

--   l N   Line number.
builtin.line = '%l'
builtin.line_number = builtin.line

--   L N   Number of lines in buffer.
builtin.number_of_lines = '%L'

--   c N   Column number.
builtin.column = '%c'
builtin.column_number = builtin.column

--   v N   Virtual column number.
builtin.virtual_column = '%v'
builtin.virtual_column_number = '%v'

--   V N   Virtual column number as -{num}.  Not displayed if equal to 'c'.
-- TODO: This isn't a good name.
builtin.virtual_column_number_long = 'V'

--   p N   Percentage through file in lines as in |CTRL-G|.
builtin.percentage_through_file = '%p'

--   P S   Percentage through file of displayed window.  This is like the
--         percentage described for 'ruler'.  Always 3 in length, unless
--         translated.
builtin.percentage_through_window = '%P'

--   a S   Argument list status as in default title.  ({current} of {max})
--         Empty if the argument file count is zero or one.
builtin.argument_list_status = '%a'


return builtin
