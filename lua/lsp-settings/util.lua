local Config = require("lsp-settings.config")

local M = {}

function M.merge(...)
  local function can_merge(v)
    return type(v) == "table" and (vim.tbl_isempty(v) or not vim.tbl_islist(v))
  end

  local values = { ... }
  local ret = values[1]
  for i = 2, #values, 1 do
    local value = values[i]
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = M.merge(ret[k], v)
      end
    else
      ret = value
    end
  end
  return ret
end

function M.path(str)
  local f = debug.getinfo(1, "S").source:sub(2)
  return M.fqn(vim.fn.fnamemodify(f, ":h:h:h") .. "/" .. (str or ""))
end

function M.schema(name)
  return M.path("schemas/" .. name .. ".json")
end

function M.read_file(file)
  local fd = io.open(file)
  if not fd then
    error(("Could not open file %s for writing"):format(file))
  end
  local data = fd:read("*a")
  fd:close()
  return data
end

function M.write_file(file, data)
  local fd = io.open(file, "w+")
  if not fd then
    error(("Could not open file %s for writing"):format(file))
  end
  fd:write(data)
  fd:close()
end

function M.json_decode(json)
  json = vim.trim(json)
  if json == "" then
    json = "{}"
  end
  ---@diagnostic disable-next-line: missing-parameter
  json = require("lsp-settings.json").json_strip_comments(json)
  return vim.fn.json_decode(json)
end

function M.fqn(fname)
  fname = vim.fn.fnamemodify(fname, ":p")
  return vim.loop.fs_realpath(fname) or fname
end

---@param patterns table|string
---@param fn fun(pattern: string, file: string|nil)
function M.for_each(patterns, fn, root_dir)
  if type(patterns) == "string" then
    patterns = { patterns }
  end

  for _, pattern in ipairs(patterns) do
    fn(pattern, root_dir and root_dir .. "/" .. pattern)
  end
end

function M.for_each_local(fn, root_dir)
  M.for_each(Config.options.local_settings, fn, root_dir)
end

function M.for_each_global(fn)
  M.for_each(Config.options.global_settings, fn, vim.fn.stdpath("config"))
end

function M.fetch(url)
  local fd = io.popen(string.format("curl -s -k %q", url))
  if not fd then
    error(("Could not download %s"):format(url))
  end
  local ret = fd:read("*a")
  fd:close()
  return ret
end

function M.mtime(fname)
  local stat = vim.loop.fs_stat(fname)
  return (stat and stat.type) and stat.mtime.sec or 0
end

function M.exists(fname)
  local stat = vim.loop.fs_stat(fname)
  return (stat and stat.type) or false
end

function M.log(msg, hl)
  vim.notify(msg, vim.log.levels.INFO, { title = "Lsp Settings" })
end

function M.warn(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "Lsp Settings" })
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "Lsp Settings" })
end

function M.info(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "Lsp Settings" })
end

return M