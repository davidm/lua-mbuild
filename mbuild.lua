--[[
mbuild.lua - see README for details and copyright.
--]]

local M = {_TYPE='module', _NAME='mbuild', _VERSION='0.1.20120121'}

local FS = require 'file_slurp' -- https://gist.github.com/1325400
local loadfile = (pcall(load,'') and _G or require 'compat_load').loadfile -- https://gist.github.com/1654007

-- Simple table serialize and unserialize from file.
require "DataDumper"
local DataDumper = _G.DataDumper  --  D:<
local function load_table(filename)
  local f, err = loadfile(filename, 't', {}); if not f then return f, err end
  local t = f()
  return t
end
local function save_table(filename, t, flags)
  FS.writefile(filename, DataDumper(t), flags)
end

-- MD5 file checksum support.
-- Note: For greater efficiency, use the "md5" module
--   <http://www.keplerproject.org/md5/> if available.
local sumhexa = pcall(require, 'md5') and require 'md5'.sumhexa
if not sumhexa then
  io.stderr:write('Warning: using md5sum command (slow) rather than md5 module.\n')
end
local function md5_file(filename)
  if sumhexa then
    local data = FS.readfile(filename, 's')
    if not data then return nil end
    return sumhexa(data)
  else
    if not FS.testfile(filename) then return nil end
    local res = FS.readfile('md5sum -b '..filename, 'p')
    local md5 = res:match('[a-f0-9]+') or error("md5sum output bad: filename="..filename)
    return md5
  end
end

-- Supports __gc metamethods on tables in Lua 5.1.
local function compat_finalizable(o)
  if _G._VERSION == 'Lua 5.1' then
    M._final = newproxy(true)
    getmetatable(M._final).__gc = function() o:__gc() end
  end
end

-- The Builder class.
local Builder = {}; Builder.__index = Builder

function Builder:initialize()
  io.stdout:write'Loading .deps...\n'
  self.deps = load_table(".deps", 's') or {}
end

function Builder:finalize()
  if self.deps then
    io.stdout:write'Saving .deps...\n'
    local ok, err = save_table('.deps', self.deps)
    if not ok then io.stderr:write(err, '\n') end
    self.deps = nil
  end
end

function Builder:execute(cmd)
  io.stdout:write(': ', cmd, '\n')
  local result = os.execute(cmd)
  assert(result == 0, cmd)
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
    local hash = md5_file(item)
    if hash ~= last_hash then return false end
  end

  return true -- pass
end

function Builder:update_deps(cmd, outputs, inputs)
  local dep = {}
  if inputs.defer then inputs = inputs:defer() end
  for _,item in ipairs(inputs) do dep[item] = md5_file(item) end
  for _,item in ipairs(outputs) do dep[item] = md5_file(item) end
  self.deps[cmd] = dep
end

function Builder:run(cmd, outputs, inputs)
  if not self:check_deps(cmd, outputs) then
    self:execute(cmd)
    self:update_deps(cmd, outputs, inputs)
  end
end

function Builder:__gc()
  self:finalize()
end

-- Constructor for Builder objects.
function M.Builder()
  local self = setmetatable({}, Builder)
  compat_finalizable(self)
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
