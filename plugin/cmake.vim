" cmake.vim - Vim plugin to make working with CMake a little nicer
" Maintainer:   Dirk Van Haerenborgh <http://vhdirk.github.com/>
" Version:      0.2

let s:cmake_plugin_version = '0.2'

if exists("loaded_cmake_plugin")
  finish
endif

" We set this variable here even though the plugin may not actually be loaded
" because the executable is not found. Otherwise the error message will be
" displayed more than once.
let loaded_cmake_plugin = 1

" Set option defaults
if !exists("g:cmake_export_compile_commands")
  let g:cmake_export_compile_commands = 0
endif
if !exists("g:cmake_ycm_symlinks")
  let g:cmake_ycm_symlinks = 0
endif

if !executable("cmake")
  echoerr "vim-cmake requires cmake executable. Please make sure it is installed and on PATH."
  finish
endif

" CMake error rudimentary parsing
let s:cmake_errors = []
let s:cmake_errors += ['%DCMake enter dir: %f']
let s:cmake_errors += ['%XCMake leave dir: %f']
let s:cmake_errors += ['CMake %trror at %f:%l (%m):']
let s:cmake_errors += ['CMake %trror at %f:%l:']
let s:cmake_errors += ['CMake %trror in %f:']
let s:cmake_errors += ['CMake %trror: %m']
let &errorformat .= ',' . join(s:cmake_errors, ',')

function! s:search_upward_for(name, in)
  " Searches upwards from "in" directory until a:name is found
  return finddir(a:name, a:in.';')
endfunction

function! s:create_compile_commands_symlink()
    if has("win32")
      silent echo system("mklink ../compile_commands.json " . b:build_dir . "/compile_commands.json")
    else
      silent echo system("ln -s " . s:fnameescape(b:build_dir) ."/compile_commands.json ../compile_commands.json")
    endif
endfunction

function! s:run_as_makeprg(cmd)
    " for restoring later
    let makeprg_backup = &makeprg

    " run our command as makeprg
    let &makeprg = a:cmd
    silent make

    " restore old makeprg command
    let &makeprg = makeprg_backup
endfunction

function! s:find_build_dir()
  " Do not overwrite already found build_dir, may be set explicitly
  " by user.
  if exists("b:build_dir") && b:build_dir != ""
    return 1
  endif

  if exists("g:cmake_build_dir_override")
    if exists("*mkdir")
      call mkdir(g:cmake_build_dir_override, "p", 0700)
    endif
    let b:build_dir = g:cmake_build_dir_override
    let b:proj_dir = fnamemodify(b:build_dir, ':h')
    return 1
  endif

  let g:cmake_build_dir = get(g:, 'cmake_build_dir', 'build')
  let b:build_dir = s:search_upward_for(g:cmake_build_dir, "")

  if b:build_dir == ""
    " Find build directory in path of current file
    let b:build_dir = s:search_upward_for(g:cmake_build_dir, s:fnameescape(expand("%:p:h")))
  endif

  if b:build_dir != ""
    " expand() would expand "" to working directory, but we need
    " this as an indicator that build was not found
    let tmp = b:build_dir
    let b:build_dir = fnamemodify(tmp, ':p:h')
    let b:proj_dir = fnamemodify(tmp, ':p:h:h')

    echom "Found cmake build directory: " . b:build_dir
    echom "Found cmake project directory: " . b:proj_dir

    return 1
  else
    unlet b:build_dir
    echom "Unable to find cmake build directory."
    return 0
  endif

endfunction

" Configure the cmake project in the currently set build dir.
"
" This will override any of the following variables if the
" corresponding vim variable is set:
"   * CMAKE_INSTALL_PREFIX
"   * CMAKE_BUILD_TYPE
"   * CMAKE_BUILD_SHARED_LIBS
" If the project is not configured already, the following variables will be set
" whenever the corresponding vim variable for the following is set:
"   * CMAKE_CXX_COMPILER
"   * CMAKE_C_COMPILER
"   * The generator (-G)
function! s:cmake_configure(...)

  let l:argument = []
  " Only change values of variables, if project is not configured
  " already, otherwise we overwrite existing configuration.
  let l:configured = filereadable(b:build_dir ."CMakeCache.txt")

  if !l:configured
    if exists("g:cmake_project_generator")
        let l:argument += [ "-G \"" . g:cmake_project_generator . "\"" ]
    endif
    if exists("g:cmake_cxx_compiler")
        let l:argument += [ "-DCMAKE_CXX_COMPILER:FILEPATH="     . g:cmake_cxx_compiler ]
    endif
    if exists("g:cmake_c_compiler")
        let l:argument += [ "-DCMAKE_C_COMPILER:FILEPATH="       . g:cmake_c_compiler ]
    endif
  endif

  if exists("g:cmake_install_prefix")
    let l:argument += [ "-DCMAKE_INSTALL_PREFIX:FILEPATH="  . g:cmake_install_prefix ]
  endif
  if exists("g:cmake_build_type" )
    let l:argument += [ "-DCMAKE_BUILD_TYPE:STRING="         . g:cmake_build_type ]
  endif
  if exists("g:cmake_build_shared_libs")
    let l:argument += [ "-DBUILD_SHARED_LIBS:BOOL="          . g:cmake_build_shared_libs ]
  endif
  if g:cmake_export_compile_commands
    let l:argument += [ "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ]
  endif

  let l:argumentstr = join(l:argument, " ")

  exec 'cd '.s:fnameescape(b:proj_dir)

  " This makes use of "cmake -Hproj_dir -Bbuild_dir" as a substitute for
  " "cmake ..", similar to Ninja's "rebuild_cache.util" command inside
  " `build.ninja`.
  " Those options are internal command line options of CMake and therefore
  " *undocumented* (working with CMake v3.7.2)
  let s:cmd = 'cmake -H"'. b:proj_dir .'" -B"'. b:build_dir .'" '
  let s:cmd .= l:argumentstr . ' ' . join(a:000)
  echo s:cmd
  call s:run_as_makeprg(s:cmd)

  exec 'cd -'

  " If there were make errors another buffer might get opened, therefore
  " setting "b:build_dir" again
  if !s:find_build_dir()
      return
  endif

  exec 'cd '.s:fnameescape(b:build_dir)

  " Create symbolic link to compilation database for use with YouCompleteMe
  if g:cmake_ycm_symlinks && filereadable("compile_commands.json")
    call s:create_compile_commands_symlink()
    echom "Created symlink to compilation database"
  endif

  exec 'cd -'
endfunction

" Utility function
" Thanks to tpope/vim-fugitive
function! s:fnameescape(file) abort
  " Because of https://github.com/vim/vim/issues/541, we escape manually on
  " windows.
  if exists('*fnameescape') && !has("win32")
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

" Public Interface:
command! -nargs=? CMake call s:cmake(<f-args>)
command! CMakeClean call s:cmakeclean()
command! CMakeFindBuildDir call s:cmake_find_build_dir()

command! -nargs=? CMakeCDMake call s:cd_make(<f-args>)

function! s:cmake_find_build_dir()
  if exists("b:build_dir")
      unlet b:build_dir
  endif
  call s:find_build_dir()
endfunction

function! s:cmake(...)
  if !s:find_build_dir()
    return
  endif

  " CMake outputs errors relative to project directory. We therefore tell
  let &makeprg = '((echo CMake enter dir: ' . b:proj_dir . ')'
  let &makeprg .= '&& cmake --build "' . b:build_dir . '" --target $*)'
  call call('s:cmake_configure', a:000)
endfunction

function! s:cmakeclean()
  if !s:find_build_dir()
    return
  endif

  silent echo system("rm -r '" . b:build_dir. "/*'")
  echom "Build directory has been cleaned."
endfunction

function! s:cd_make(...)
  if !s:find_build_dir()
    return
  endif

  exec 'cd' b:proj_dir
  exec 'make '. join(a:000)
  exec 'cd -'
endfunction
" vim: set tabstop=2 softtabstop=0 expandtab shiftwidth=2:
