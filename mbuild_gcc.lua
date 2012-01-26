--[[
gcc support.
  
Note: could use either gcc -MM or gcc -M
  
(c) 2012 David Manura.  See README for details.
--]]

local M = {}

local FS = require 'file_slurp'

-- Expand dependencies for inputs.
function M.gcc_deps(inputs_orig)
  local cmd = 'gcc -M '..table.concat(inputs_orig, ' ')

  io.stdout:write('+ ', cmd, '\n')
  local info = FS.readfile(cmd, 'p')
  info = info:gsub('\\\n', '')
  
  local output, more = info:match('^([^:]+): *(.*)')
  assert(output, 'fail: '..cmd..' '..info)  
  local inputs = {}
  for _,item in ipairs(inputs_orig) do inputs[#inputs+1] = item end
  for item in more:gmatch('%S+') do
    inputs[#inputs+1] = item
  end
  return inputs
end

return M
