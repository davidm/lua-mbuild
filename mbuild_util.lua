--[[
 Various utility functions for mbuild.
 
 (c) 2012 David Manura.  See README for details.
--]]

local M = {}

local FS = require 'file_slurp' -- https://gist.github.com/1325400
local loadfile = (pcall(load,'') and _G or require 'compat_env').loadfile -- https://gist.github.com/1654007

-- Simple table serialize and unserialize from file.
local function dump_string(o, space)
  space = space or ''
  if type(o) == 'string' then
    return ("%q"):format(o)
  elseif type(o) ~= 'table' then
    return tostring(o)
  else
    local ts = {}
    for k,v in pairs(o) do
      ts[#ts+1] = space..'  ['..dump_string(k)..'] = '..dump_string(v, space..'  ')..';\n'
    end
    return '{\n'..table.concat(ts)..space..'}'
  end
end
function M.load_table(filename)
  local f, err = loadfile(filename, 't', {}); if not f then return f, err end
  local t = f()
  return t
end
function M.save_table(filename, t, flags)
  FS.writefile(filename, 'return '..dump_string(t)..'\n', flags)
end

-- MD5 file checksum support.
-- Note: For greater efficiency, use the "md5" module
--   <http://www.keplerproject.org/md5/> if available.
local sumhexa = pcall(require, 'md5') and require 'md5'.sumhexa
if not sumhexa then
  io.stderr:write('Warning: using md5sum command (slow) rather than md5 module.\n')
end
function M.md5_file(filename)
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

function M.concat_lists(t1, t2)
  if #t1 == 0 then return t2 end  -- optimization
  if #t2 == 0 then return t1 end
  local t = {}
  for _,v in ipairs(t1) do t[#t+1] = v end
  for _,v in ipairs(t2) do t[#t+1] = v end
  return t
end

-- Supports __gc metamethods on tables in Lua 5.1.
function M.compat_finalizable(o)
  if _G._VERSION == 'Lua 5.1' then
    M._final = newproxy(true)
    getmetatable(M._final).__gc = function() o:__gc() end
  end
end

return M
