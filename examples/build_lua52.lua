#!/usr/bin/env lua
-- Example mbuild for Lua 5.2.0.

local MB = require 'mbuild'
local gcc_deps = require 'mbuild_gcc'.gcc_deps
local qw = require 'mbuild_list'.qw

local CORE_O = qw[[
	lapi.o lcode.o lctype.o ldebug.o ldo.o ldump.o lfunc.o lgc.o llex.o
	lmem.o lobject.o lopcodes.o lparser.o lstate.o lstring.o ltable.o
	ltm.o lundump.o lvm.o lzio.o
]]
local LIB_O = qw[[
	lauxlib.o lbaselib.o lbitlib.o lcorolib.o ldblib.o liolib.o
	lmathlib.o loslib.o lstrlib.o ltablib.o loadlib.o linit.o
]]
local BASE_O = CORE_O + LIB_O + qw'lua.c'

for obj in (BASE_O + qw'lua.o luac.o'):iter() do
  local src = obj:gsub('%.o$', '%.c')
  MB.run('gcc -c '..src, {obj}, {src, defer=gcc_deps})
end
MB.run('ar rcu liblua.a '..BASE_O:string(), {'liblua.a'}, BASE_O)
MB.run('gcc -o lua lua.o liblua.a -lm', {'lua'}, {'lua.o', 'liblua.a'})
MB.run('gcc -o luac luac.o liblua.a -lm', {'luac'}, {'luac.o', 'liblua.a'})
