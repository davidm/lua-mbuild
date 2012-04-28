--[[
mbuild.lua - see README for details.

(c) 2012 David Manura.  See README for details.
--]]

local M = {_TYPE='module', _NAME='mbuild', _VERSION='0.1.20120125'}

local UTIL = require 'mbuild_util'

-- os.execute like function, with partial Lua 5.1/5.2 compatiblity.
local function execute(cmd)
  local result, err, code = os.execute(cmd)
  if type(result) == 'number' then  -- Lua 5.1
    return (result == 0 or nil), 'exit', result
  else
    return result, err, code
  end
end


-- The Builder class.
local Builder = {}; Builder.__index = Builder

function Builder:initialize()
  io.stdout:write'Loading .deps...\n'
  self.deps = UTIL.load_table(".deps", 's') or {}
end

function Builder:finalize()
  if self.deps then
    io.stdout:write'Saving .deps...\n'
    local ok, err = UTIL.save_table('.deps', self.deps)
    if not ok then io.stderr:write(err, '\n') end
    self.deps = nil
  end
end

function Builder:execute(cmd)
  io.stdout:write(': ', cmd, '\n')
  local result, err, code = execute(cmd)
  assert(result, 'failed: cmd='..('%q'):format(cmd)..' [code='..code..']')
end

function Builder:check_deps(cmd, outputs)
   -- Fail if an output lacks a known hash.
  for _,item in ipairs(outputs) do
    if not (self.deps[cmd] or {})[item] then
      return false
    end
  end
  
  -- Fail if a known hash does not match.
  for item, last_hash in pairs(self.deps[cmd] or {}) do
    local hash = UTIL.md5_file(item)
    if hash ~= last_hash then return false end
  end
  
  -- Fail if no info known.
  if not next(self.deps[cmd] or {}) then return false end

  return true -- pass
end

function Builder:update_deps(cmd, outputs, inputs)
  local dep = {}
  if inputs.defer then inputs = inputs:defer() end
  for _,item in ipairs(inputs) do dep[item] = UTIL.md5_file(item) end
  for _,item in ipairs(outputs) do dep[item] = UTIL.md5_file(item) end
  self.deps[cmd] = dep
end

function Builder:run(cmd, outputs, inputs, exec)
  outputs = outputs or {}
  inputs = inputs or {}
  if not self:check_deps(cmd, outputs) then
    local more_outputs, more_inputs = {},{}
    if exec then
      more_outputs, more_inputs = exec(cmd)
    else
      self:execute(cmd)
    end
    local outputs = UTIL.concat_lists(outputs, more_outputs)
    local inputs = UTIL.concat_lists(inputs, more_inputs)
    self:update_deps(cmd, outputs, inputs)
  end
end

function Builder:__gc()
  self:finalize()
end

-- Constructor for Builder objects.
function M.Builder()
  local self = setmetatable({}, Builder)
  UTIL.compat_finalizable(self)
  self:initialize()
  return self
end

-- Optional global builder object for convenience.
M.builder = nil
local function make_global_builder()
  if not M.builder then M.builder = M.Builder() end
  return M.builder
end

-- invokes `run` on global builder object.
function M.run(...)
  local builder = make_global_builder()
  builder:run(...)
end

return M
