--[[
*nix strace [1] handler.
 
This is used for automatically determining the files read and written
during a command execution.
The basic technique is described in [2]
 
Warning: this is very preliminary.
 
[1] http://en.wikipedia.org/wiki/Strace
[2] http://code.google.com/p/fabricate/
 
D.Manura, 2012
--]]

local M = {}

local FS = require 'file_slurp'

local DEBUG = false

local tmpfile = 'tmp.txt' -- TODO: generalize location

local function trace_exec(cmd)
  io.stdout:write(': ', cmd, '\n')
  os.remove(tmpfile)
  local cmd2 = 'strace -f -o '..tmpfile..' -e "trace=file" -e "verbose=" '..cmd
  local res = os.execute(cmd2)
  local text = (res == 0) and FS.readfile('tmp.txt', 'T') or nil
  os.remove(tmpfile)  
  return res, text
end

local function hash_to_list(t)
  local tt = {}
  for k in pairs(t) do tt[#tt+1] = k end
  return tt
end

local function parse(text)
  local inputs = {}
  local outputs = {}

  for line in text:gmatch'[^\r\n]+' do
    local filename, flags = line:match'^%d+ open%("([^"]+)", ([^%)]+)'
    if filename then
      local is_write = not flags:match'O_RDONLY'
      ;(is_write and outputs or inputs)[filename] = true
    end
  end
  -- TODO: handle other calls, including chdir (which requires
  -- keeping track of the current working directory for each PID).
  
  -- ignore these files [TODO: generalize]
  inputs['/proc/meminfo'] = nil
  
  return hash_to_list(outputs), hash_to_list(inputs)
end

function M.exec(cmd)
  local res, text = trace_exec(cmd)
  assert(res == 0, 'command failed: '..cmd)
  local outputs, inputs = parse(text)
  if DEBUG then
    for _,v in ipairs(outputs) do print('TRACE_OUT', v) end
    for _,v in ipairs(inputs) do print('TRACE_IN', v) end
  end
  return outputs, inputs
end

return M
