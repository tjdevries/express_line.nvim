-- vim.diagnostic wrappers for el

---@tag el.diagnostic
---@config { module = 'el.diagnostic' }

local severity = vim.diagnostic.severity

local subscribe = require "el.subscribe"

local diagnostic = {}

local get_counts = function(diags)
  local errors, warnings, infos, hints = 0, 0, 0, 0
  for _, d in ipairs(diags) do
    if d.severity == severity.ERROR then
      errors = errors + 1
    elseif d.severity == severity.WARN then
      warnings = warnings + 1
    elseif d.severity == severity.INFO then
      infos = infos + 1
    else
      hints = hints + 1
    end
  end

  return {
    errors = errors,
    warnings = warnings,
    infos = infos,
    hints = hints,
  }
end

local get_buffer_counts = function(_, buffer)
  return get_counts(vim.diagnostic.get(buffer.bufnr))
end

--- An item generator, used to create an item that shows diagnostic information
--- for the current buffer
---@param formatter function: Optional, function(window, buffer, counts) -> string. Counts keys: ["errors", "warnings", "infos", "hints"]
diagnostic.make_buffer = function(formatter)
  if not formatter then
    formatter = function(_, _, counts)
      local items = {}
      if counts.errors > 0 then
        table.insert(items, string.format("E:%s", counts.errors))
      end

      if counts.warnings > 0 then
        table.insert(items, string.format("W:%s", counts.warnings))
      end

      if counts.infos > 0 then
        table.insert(items, string.format("I:%s", counts.infos))
      end

      if counts.hints > 0 then
        table.insert(items, string.format("H:%s", counts.hints))
      end

      return table.concat(items, " ")
    end
  end

  return subscribe.buf_autocmd("el_buf_diagnostic", "DiagnosticChanged", function(window, buffer)
    return formatter(window, buffer, get_buffer_counts(window, buffer))
  end)
end

return diagnostic
