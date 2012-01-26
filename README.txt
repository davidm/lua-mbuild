NAME

  mbuild.lua - Lua-based memoized build system.

DESCRIPTION

  This is an initial implementation of a "memoized build system" in Lua.
  For background on memoized build systems, see [1] and "Related Work" below.

STATUS

  This implementation is an initial proof of concept of creating a
  memoized build system in Lua.  Perhaps it's usable as is, but the
  code will likely need to be expanded in practice.
  
USAGE

  A very basic usage is as follows.  Create a Lua file like this and run it:
  
    local MB = require 'mbuild'
    MB.run('gcc -c t1.c', {'t1.o'}, {'t1.c', 't1.h', 't2.h'})
    MB.run('gcc -c t2.c', {'t2.o'}, {'t2.c', 't2.h'})
    MB.run('gcc -o t t1.c t2.c', {'t'}, {'t1.o', 't2.o'})

  This will compile files "t1.c" and "t2.c" and then link them into a program
  "t".  Inputs and outputs must be listed explicitly (although there are ways
  to implicitly infer them as discussed later below).
  
  If you rerun the program, nothing will happen.  If you edit a dependency and
  rerun the program, the necessary files will be rebuilt.  Checksums will be
  stored in a temporary file called ".deps" (like in fabricate [1]).
  
  You could write wrapper commands that avoid the duplication, like perhaps
  
    c_program('t', {'t1.c', 't2.c'})
  
  You may also wish to put commands in functions:
  
    function program_t()
      MB.run('gcc -c t1.c', {'t1.o'}, {'t1.c', 't1.h', 't2.h'})
      MB.run('gcc -c t2.c', {'t2.o'}, {'t2.c', 't2.h'})
      MB.run('gcc -o t t1.c t2.c', {'t'}, {'t1.o', 't2.o'})
    end
    function program_tt()
      MB.run('gcc -c tt.c', {'tt.o'}, {'tt.c', 'tt.h'})
      MB.run('gcc -o t tt.c', {'t'}, {'tt.o'})
    end
    function all()
      program_t()
      program_tt()
    end
    local name = arg[1] or 'all'
    _G[name]()
  
  Implicit dependencies
  
    Some memoized build systems can invoke "gcc -M" or "gcc -MM"
    to determine dependencies (e.g. [6]).
    An external module is provided for doing this:

      local gcc_deps = require 'mbuild_gcc'.gcc_deps
      MB.run('gcc -c t1.c', {'t1.o'}, {'t1.c', defer=gcc_deps})
      MB.run('gcc -c t2.c', {'t2.c'}, {'t2.c', defer=gcc_deps})
      MB.run('gcc -o t1 t1.c t2.c', {'t1'}, {'t1.o', 't2.o'})
  
    Some memoized builds systems support "strace" (a Linux/*nix command
    not available on Windows) to automatically determine files read and
    written by commands executed. There is a preliminary implementation
    of this via the "mbuild_strace" module:

      local strace = require 'mbuild_strace'
      MB.run('gcc -c t1.c', nil, nil, strace.exec)
      MB.run('gcc -c t2.c', nil, nil, strace.exec)
      MB.run('gcc -o t1 t1.o t2.o', nil, nil, strace.exec)
      
    The strace.exec will build outputs and dependencies based on the
    system calls observed when running the commands.
    
    You can check what dependencies are being inferred by
    examining the ".deps" file that mbuild creates:
    
     ["gcc -c t1.c"]={
      ["/lib/i386-linux-gnu/libc.so.6"]="fae28f0c80586f2b712b191d82a51cbd",
      ["/lib/i386-linux-gnu/libdl.so.2"]="6e2aaea7226f46f38ab50432afd4245d",
      ["t1.c"]="38c4ebbcd1f502ed3f87ae5ec7e6b95b",
      ["t1.h"]="d784fa8b6d98d27699781bd9a7cf19f0",
      . . .
     }

  Change detection
  
    Currently, files are considered "changed" if their MD5 checksums change.
    Alternate possibilities include time-stamp changes.
    
  List utilities
  
    The mbuild_list module provides convenient list manipulation functionality:
    
      local qw = require 'mbuild_list'.qw
      local OBJ = qw'a.o b.o c.o'
      for item in SRC:iter() do
        MB.run('gcc '..item, {item:gsub('%.o$', '.c')}, {item})
      end
      MB.run('gcc -o prog '..OBJ:string(), 'prog', OBJ)
    
EXAMPLES

  examples/build_lua.lua is an example of building Lua 5.2.
    
INSTALLATION / DEPENDENCIES

  Download mbuild.lua and dependencies (file_slurp.lua, compat_load, and
  DataDumper).
  
    Download all mbuild*.lua files from github.com/davidm/lua-mbuild
    wget https://raw.github.com/gist/1325400/file_slurp.lua
    wget https://raw.github.com/gist/1654007/compat_load.lua  # omit in Lua5.2
    wget https://raw.github.com/gist/1255382/DataDumper.lua
    
  Put these in your LUA_PATH.
    
  Either the "md5" module <http://www.keplerproject.org/md5/manual.html> or
  the system "md5sum" command will be used.  The later is used if the former
  is not installed.

RELATED WORK

  Other memoized build systems include [1-5].

DESIGN NOTES

  The core implementation is not aware of particular toolchain, but it does
  support toolchain specific convenience modules like the provided
  mbuild_gcc.lua.  Higher level build rules could be added that abstract
  away the user's toolchain specific code.  This implementation is also
  cross-platform.  (The optional strace support requires
  a Linux/*nix compatible OS.)

REFERENCES

  [1] Fabricate, http://code.google.com/p/fabricate/
  [2] Bill McCloskey's memoize.py.
        Broken link: http://www.eecs.berkeley.edu/~billm/memoize.html .
        Alternate links: http://benno.id.au/memoize.py ;
          http://benno.id.au/blog/2008/06/06/memoize-build-framework
  [3] fbuild - https://github.com/felix-lang/fbuild
        (by Erick Tryzelaar, author of felix-lang)
  [4] mem - http://srp.github.com/mem/getting-started.html
  [5] wonderbuild -
        http://retropaganda.info/~bohan/work/psycle/branches/bohan/wonderbuild/wonderbuild/ ;
        http://psycle.svn.sourceforge.net/viewvc/psycle/branches/bohan/wonderbuild/benchmarks/time.xml
  [6] http://code.google.com/p/fabricate/wiki/HowtoMakeYourOwnRunner
  [7] http://en.wikipedia.org/wiki/Strace
	
COPYRIGHT

(c) 2012 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
