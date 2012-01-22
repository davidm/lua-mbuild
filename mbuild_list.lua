--[[
  List implementation.
  With Perl-like `qw` operator.
--]]

local M = {}

local List = {}; List.__index = List
function List.__add(a, b)
  local t = {}
  for _,v in ipairs(a) do t[#t+1] = v end
  for _,v in ipairs(b) do t[#t+1] = v end
  return setmetatable(t, List)
end
function List:iter()
  local i = 0
  return function()
    i=i+1
    return self[i]
  end
end
function List:string()
  return table.concat(self, ' ')
end

function M.qw(s)
  local t = {}
  for v in s:gmatch('%S+') do t[#t+1] = v end
  return setmetatable(t, List)
end

return M
