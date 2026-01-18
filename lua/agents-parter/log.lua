local has_plenary, plenary_log = pcall(require, "plenary.log")

if not has_plenary then
  -- Fallback to a dummy logger if plenary is not available
  local dummy = function(...) end
  return {
    debug = dummy,
    info = dummy,
    warn = dummy,
    error = dummy,
    trace = dummy,
  }
end

local log = plenary_log.new({
  plugin = "agents-parter",
  level = "debug",
})

return log
