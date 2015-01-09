SRCPATH=.
prefix=/Users/karimjimo/Downloads/linphone-iphone/submodules/build/..//../liblinphone-sdk/i386-apple-darwin
exec_prefix=${prefix}
bindir=${exec_prefix}/bin
libdir=${exec_prefix}/lib
includedir=${prefix}/include
ARCH=X86
SYS=MACOSX
CC=xcrun clang -std=c99  -arch i386  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions
CFLAGS=-Wshadow -O3 -ffast-math -m32  -Wall -I. -I$(SRCPATH)  -arch i386  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions  -falign-loops=16 -march=i686 -mfpmath=sse -msse -std=gnu99 -fPIC -fomit-frame-pointer -fno-tree-vectorize
DEPMM=-MM -g0
DEPMT=-MT
LD=xcrun clang -std=c99  -arch i386  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions -o 
LDFLAGS=-m32   -arch i386  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions -lm -lpthread
LIBX264=libx264.a
AR=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ar rc 
RANLIB=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/ranlib
STRIP=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/usr/bin/strip
AS=yasm
ASFLAGS= -O2 -f macho -DPREFIX -DPIC -DHIGH_BIT_DEPTH=0 -DBIT_DEPTH=8
RC=
RCFLAGS=
EXE=
HAVE_GETOPT_LONG=1
DEVNULL=/dev/null
PROF_GEN_CC=-fprofile-generate
PROF_GEN_LD=-fprofile-generate
PROF_USE_CC=-fprofile-use
PROF_USE_LD=-fprofile-use
default: cli
install: install-cli
default: lib-static
install: install-lib-static
LDFLAGSCLI = 
CLI_LIBX264 = $(LIBX264)
