# vim-cmake
[![Travis (Linux)](https://travis-ci.org/Squareys/vim-cmake.svg?branch=master)](https://travis-ci.org/Squareys/vim-cmake)
[![AppVeyor (Windows)](https://ci.appveyor.com/api/projects/status/8x1tk0wbu4564m43?svg=true)](https://ci.appveyor.com/project/Squareys/vim-cmake)

[vim-cmake](https://github.com/Squareys/vim-cmake) is a Vim plugin to make working with CMake a lot more convenient.
This project was originally forked from [vhdirk/vim-cmake](https://github.com/vhdirk/vim-cmake).

## Usage

### Commands

 * `:CMake` searches for the closest directory named as specified by `g:cmake_build_dir`.
The directory is searched for upwards from the current directory. If that does not lead to a result it tries again from the directory of the current file.
When a dir is found, it runs the cmake command there, assuming the CMakeLists.txt
file in `..` relative to the build dir.
Any arguments given to :CMake will be directly passed on to the cmake command.
Finally, this command sets `makeprg` to (effectively) `cmake --build <build-dir> --target ` for you to simply compile the project using `:make <target>`.

 * `:CMakeClean` deletes all files in the build directory. You can think of this as a CMake version of make clean.

 * `:CMakeFindBuildDir` resets the build directory path set for the current buffer and then tries to find a new one. Useful if it previously found a wrong path to then reset it after a new build folder has been created for example.

### Variables

 * `g:cmake_install_prefix` same as `-DCMAKE_INSTALL_PREFIX`

 * `g:cmake_build_type` same as `-DCMAKE_BUILD_TYPE`

 * `g:cmake_cxx_compiler` same as `-DCMAKE_CXX_COMPILER`. Changes will have no effect until you run :CMakeClean and then :CMake.

 * `g:cmake_c_compiler` same as `-DCMAKE_C_COMPILER`. Changes will have no effect until you run :CMakeClean and then :CMake.

 * `g:cmake_build_shared_libs` same as `-DBUILD_SHARED_LIBS`

 * `g:cmake_project_generator` same as `-G`. Changes will have no effect until you run :CMakeClean and then :CMake.

 * `g:cmake_export_compile_commands` same as `-DCMAKE_EXPORT_COMPILE_COMMANDS`.

 * `g:cmake_ycm_symlinks` create symlinks to the generated compilation database for use with [YouCompleteMe](https://github.com/Valloric/YouCompleteMe/).

 * `b:build_dir` is the path to the cmake build directory for the current buffer. This variable is set with the first :CMake or :CMakeFindBuildDir call. Once found, it will not be searched for again unless you call :CMakeFindBuildDir. If automatic finding is not sufficient you can set this variable manually to the build dir of your choice.

 * `g:cmake_build_dir_override` can be used to override the complete build directory path.  If the directory does not exist and `mkdir()` is supported it will be automatically created.

## Installation


### Vim-pathogen

With [pathogen.vim](https://github.com/tpope/vim-pathogen) simply copy and paste:

    cd ~/.vim/bundle
    git clone git://github.com/Squareys/vim-cmake.git

Once help tags have been generated, you can view the manual with
`:help cmake`.

### Vundle

With [Vundle.vim](https://github.com/VundleVim/Vundle.vim) simply add this repository to your plugins list:

    Plugin 'Squareys/vim-cmake'

## Contributing

If you find bugs or annoyances while using vim-cmake, go ahead and open an [issue](https://github.com/Squareys/vim-cmake/issues), or fix it yourself and open a [pullrequest](https://github.com/Squareys/vim-cmake/pulls).

### Running tests

vim-cmake uses [vader.vim](https://github.com/junegunn/vader.vim) for testing. To run the tests you will need to clone the repository into the root of this project:

```
# Clone the repo, note: on unix make sure the created folder is lowercase!
git clone https://github.com/junegunn/vader.vim

# Run tests
vim -Nu 'test/.vimrc' -c 'Vader! test/cmake.vader'
vim -Nu 'test/.vimrc' -c 'Vader! test/cmake_quickfix.vader'
```

For test file syntax highlighting, add vader.vim as a plugin to your .vimrc.

## Acknowledgements

 * Thanks to [Tim Pope](http://tpo.pe/), his plugins are really awesome.
 * Thanks to [Junegunn Choi](https://junegunn.kr/), for [vader.vim](https://github.com/junegunn/vader.vim), which is the testing framework used for this plugin.
 * Also thanks to
    * @SteveDeFacto for extending this with more fine grained control.
    * @snikulov for enhancing makeprg.
    * @dapicester for allowing specifying targets.
    * @thomasgubler for the build dir option.
    * @antmd for fixing a bug with handing of spaces in directory names.
    * @jmirabel for fixing concatenation of cmake arguments.
    * @T4ng10r for the project generator option.
    * @Squareys for a small overhaul of the project, the initial test and travis setup.
    * @darth for fixing passing arguments to CMake command.
    * @richteraj for the initial support for opening configure errors during `:CMake` in the quickfix list.

## License

Copyright (c) Dirk Van Haerenborgh, @SteveDeFacto. Distributed under the same terms as Vim itself.
Copyright (c) Jonathan Hale, @Squareys. Distributed under the same terms as Vim itself.

See `:help license`.
