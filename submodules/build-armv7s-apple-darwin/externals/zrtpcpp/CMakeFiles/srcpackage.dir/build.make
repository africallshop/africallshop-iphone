# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 2.8

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list

# Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /opt/local/bin/cmake

# The command to remove a file.
RM = /opt/local/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The program to use to edit the cache.
CMAKE_EDIT_COMMAND = /opt/local/bin/ccmake

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /Users/karimjimo/Downloads/linphone-iphone/submodules/externals/zrtpcpp

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp

# Utility rule file for srcpackage.

# Include the progress variables for this target.
include CMakeFiles/srcpackage.dir/progress.make

CMakeFiles/srcpackage:
	/opt/local/bin/gmake svncheck
	/opt/local/bin/cmake -E remove /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/package/*.tar.bz2
	/opt/local/bin/gmake package_source
	/opt/local/bin/cmake -E copy libzrtpcpp-2.3.4.tar.bz2 /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/package
	/opt/local/bin/cmake -E remove libzrtpcpp-2.3.4.tar.bz2

srcpackage: CMakeFiles/srcpackage
srcpackage: CMakeFiles/srcpackage.dir/build.make
.PHONY : srcpackage

# Rule to build all files generated by this target.
CMakeFiles/srcpackage.dir/build: srcpackage
.PHONY : CMakeFiles/srcpackage.dir/build

CMakeFiles/srcpackage.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/srcpackage.dir/cmake_clean.cmake
.PHONY : CMakeFiles/srcpackage.dir/clean

CMakeFiles/srcpackage.dir/depend:
	cd /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/karimjimo/Downloads/linphone-iphone/submodules/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/CMakeFiles/srcpackage.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/srcpackage.dir/depend

