local builtin = {}

-- TODO: It's a bit annoying that we don't know the length of
-- some of these items until "too late".
--
-- This puts us in not as good situations when we want do something
-- with the actual result itself (like an effect).

--- <pre>
---   f S   Path to the file in the buffer, as typed or relative to current
---         directory.
--- </pre>
builtin.file = function(_, buffer)
  if buffer.name == "" then
    return "[No Name]"
  end

  return buffer.name
end

--- relative file
builtin.file_relative = function(_, buffer)
  if buffer.name == "" then
    return builtin.file(_, buffer)
  end

  return vim.fn.bufname(buffer.bufnr)
end

--- <pre>
---   F S   Full path to the file in the buffer.
--- </pre>
builtin.full_file = function(_, buffer)
  return vim.fn.fnamemodify(buffer.name, ":p")
end

--- Shortened file name, via |pathshorten|
builtin.shortened_file = function(_, buffer)
  if buffer.name == "" then
    return builtin.file(_, buffer)
  end

  return vim.fn.pathshorten(vim.fn.fnamemodify(buffer.name, ":."))
end

--- Tail of the file name
builtin.tail_file = function(_, buffer)
  return vim.fn.fnamemodify(buffer.name, ":t")
end

---   t S   File name (tail) of file in the buffer.
builtin.tail = "%t"

---   m F   Modified flag, text is "[+]"; "[-]" if 'modifiable' is off.
builtin.modified = "%m"
builtin.modified_flag = "%m"

---   M F   Modified flag, text is ",+" or ",-".
builtin.modified_list = "%M"

---   r F   Readonly flag, text is "[RO]".
builtin.readonly = "%r"

---   r F   Readonly flag, text is "[RO]".
builtin.readonly_flag = "%r"

---   R F   Readonly flag, text is ",RO".
builtin.readonly_list = "%R"

---   h F   Help buffer flag, text is "[help]".
builtin.help = "%h"

---   h F   Help buffer flag, text is "[help]".
builtin.help_flag = "%h"

---   H F   Help buffer flag, text is ",HLP".
builtin.help_list = "%H"

---   w F   Preview window flag, text is "[Preview]".
builtin.preview = "%w"

---   w F   Preview window flag, text is "[Preview]".
builtin.preview_flag = "%w"

---   W F   Preview window flag, text is ",PRV".
builtin.preview_list = "%W"

---   y F   Type of file in the buffer, e.g., "[vim]".  See 'filetype'.
builtin.filetype = "%y"

---   y F   Type of file in the buffer, e.g., "[vim]".  See 'filetype'.
builtin.filetype_flag = "%y"

---   Y F   Type of file in the buffer, e.g., ",VIM".  See 'filetype'.
builtin.filetype_list = "%Y"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.quickfix = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.quickfix_flag = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.locationlist = "%q"

---   q S   "[Quickfix List]", "[Location List]" or empty.
builtin.locationlist_flag = "%q"

---   k S   Value of "b:keymap_name" or 'keymap' when |:lmap| mappings are being used: "<keymap>"
builtin.keymap = "%k"

---   n N   Buffer number.
builtin.bufnr = "%n"

---   n N   Buffer number.
builtin.buffer_number = "%n"

---   b N   Value of character under cursor.
builtin.character = "%b"

---   b N   Value of character under cursor.
builtin.character_decimal = "%b"

---   B N   As above, in hexadecimal.
builtin.character_hex = "%B"

--- <pre>
---   o N   Byte number in file of byte under cursor, first byte is 1.
---         Mnemonic: Offset from start of file (with one added)
--- </pre>
builtin.byte_number = "%o"
builtin.byte_number_decimal = "%o"

---   O N   As above, in hexadecimal.
builtin.byte_number_hex = "%O"

---   N N   Printer page number.  (Only works in the 'printheader' option.)
builtin.printer_page = "%N"

---   l N   Line number.
builtin.line = "%l"

---   l N   Line number.
builtin.line_number = builtin.line

--- TODO: Document
builtin.line_with_width = function(width)
  return "%-0" .. width .. "l"
end

---   L N   Number of lines in buffer.
builtin.number_of_lines = "%L"

---   c N   Column number.
builtin.column = "%c"

---   c N   Column number.
builtin.column_number = builtin.column

--- TODO: Document
builtin.column_with_width = function(width)
  return "%-0" .. width .. "c"
end

---   v N   Virtual column number.
builtin.virtual_column = "%v"

---   v N   Virtual column number.
builtin.virtual_column_number = "%v"

---   V N   Virtual column number as -{num}.  Not displayed if equal to 'c'.
--- TODO: This isn't a good name.
builtin.virtual_column_number_long = "V"

---   p N   Percentage through file in lines as in |CTRL-G|.
builtin.percentage_through_file = "%3p"

--- <pre>
---   P S   Percentage through file of displayed window.  This is like the
---         percentage described for 'ruler'.  Always 3 in length, unless
---         translated.
--- </pre>
builtin.percentage_through_window = "%P"

--- <pre>
---   a S   Argument list status as in default title.  ({current} of {max})
---         Empty if the argument file count is zero or one.
--- </pre>
builtin.argument_list_status = "%a"

--- A responsive file that is useful for optionally shortening a filepath
---@param shortened_transition number: When to transition to shortened path
---@param tail_transition number: When to transition to tail of path
---@param relative boolean: Whether to have the path be relative to cwd or not, default true
---@return el.Item: Must be called to return an item
builtin.make_responsive_file = function(shortened_transition, tail_transition, relative)
  if tail_transition == nil then
    tail_transition = 0
  end

  if relative == nil then
    relative = true
  end

  return function(window, buffer)
    if window.width < tail_transition then
      return builtin.tail_file(window, buffer)
    elseif window.width < shortened_transition then
      return builtin.shortened_file(window, buffer)
    else
      return relative and builtin.file_relative(window, buffer) or builtin.file(window, buffer)
    end
  end
end

builtin.responsive_file = function(...)
  vim.notify "[el] el.builtin.responsive_file is deprecated. Use builtin.make_responsive_file"
  return builtin.make_responsive_file(...)
end

return builtin
