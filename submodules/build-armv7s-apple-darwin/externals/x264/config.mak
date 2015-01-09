SRCPATH=.
prefix=/Users/karimjimo/Downloads/linphone-iphone/submodules/build/..//../liblinphone-sdk/armv7s-apple-darwin
exec_prefix=${prefix}
bindir=${exec_prefix}/bin
libdir=${exec_prefix}/lib
includedir=${prefix}/include
ARCH=ARM
SYS=MACOSX
CC=xcrun clang -std=c99  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions
CFLAGS=-Wshadow -O3 -fno-fast-math  -Wall -I. -I$(SRCPATH)  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions  -mfpu=neon -mfloat-abi=softfp -falign-loops=16 -std=gnu99 -fPIC -fomit-frame-pointer -fno-tree-vectorize
DEPMM=-MM -g0
DEPMT=-MT
LD=xcrun clang -std=c99  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions -o 
LDFLAGS=  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions -lm -lpthread
LIBX264=libx264.a
AR=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ar rc 
RANLIB=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/ranlib
STRIP=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/usr/bin/strip
AS=extras/gas-preprocessor.pl xcrun clang -std=c99  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions
ASFLAGS= -DPREFIX -DPIC  -Wall -I. -I$(SRCPATH)  -arch armv7s  -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.0.sdk -miphoneos-version-min=4.0 -DTARGET_OS_IPHONE=1 -D__IOS -fms-extensions  -mfpu=neon -mfloat-abi=softfp -falign-loops=16 -std=gnu99 -c -DPIC -DHIGH_BIT_DEPTH=0 -DBIT_DEPTH=8
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
