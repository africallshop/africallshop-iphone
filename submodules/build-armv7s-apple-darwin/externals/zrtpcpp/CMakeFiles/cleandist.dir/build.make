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

# Utility rule file for cleandist.

# Include the progress variables for this target.
include CMakeFiles/cleandist.dir/progress.make

CMakeFiles/cleandist:
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp[-_]*.gz
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp_*.dsc
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp-*.rpm
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp[-_]*.deb
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp[-_]*.changes
	rm -f /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/libzrtpcpp-*.zip

cleandist: CMakeFiles/cleandist
cleandist: CMakeFiles/cleandist.dir/build.make
.PHONY : cleandist

# Rule to build all files generated by this target.
CMakeFiles/cleandist.dir/build: cleandist
.PHONY : CMakeFiles/cleandist.dir/build

CMakeFiles/cleandist.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/cleandist.dir/cmake_clean.cmake
.PHONY : CMakeFiles/cleandist.dir/clean

CMakeFiles/cleandist.dir/depend:
	cd /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /Users/karimjimo/Downloads/linphone-iphone/submodules/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp /Users/karimjimo/Downloads/linphone-iphone/submodules/build-armv7s-apple-darwin/externals/zrtpcpp/CMakeFiles/cleandist.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/cleandist.dir/depend

