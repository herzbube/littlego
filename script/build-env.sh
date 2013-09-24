#!/usr/bin/env /bin/bash

# Different 3rd party software packages should be built using the same
# environment for a given platform (iOS Device, iPhone Simulator, Mac OS X),
# otherwise they won't work together. The build script of each 3rd party
# software package should therefore source this script and use the variables
# defined here to setup the software-specific build process.
#
# Software-specific build settings (e.g. CPPFLAGS)  must be defined in the
# software-specific build script.
#
# Preconditions for invoking this script:
# - The environment variable BUILD_BASEDIR must contain the absolute path to the
#   base directory from which all build activities will occur
# - The environment variable SOFTWARE_NAME must contain the name of the software
#   to build
# - It is expected that everything necessary for the build is located in the
#   path displayed by "xcode-select -print-path"
# - Some 3rd party software packages (notably Boost, possibly others as well)
#   require that the command line developer tools are also installed (e.g.
#   /usr/bin/gcc). They can be installed from within Xcode, under
#   Preferences > Downloads > Components.
#
# Notes:
# - If CXX is left undefined, configure will abort at some stage due to a linker
#   error (libgcc is not found). The reason for this is that, when CXX is not
#   defined, configure finds, and uses, a compiler in /usr/bin, but this
#   compiler does not work with the compiler flag -isysroot.
# - CXX must refer to a compiler whose name explicitly identifies as a C++
#   compiler (e.g. g++, clang++); if it refers to a compiler whose name
#   identifies is a C compiler (e.g. gcc), configure will abort at some stage
#   due to an "undefined symbol" linker error. The reason for this is that CXX
#   is used to compile C++ files; when a C++ file is compiled, a symbol is added
#   to the object file which requires the C++ Standard Library at link time
#   (libstdc++ by default, but may also be something else if the compiler/linker
#   option -stdlib is specified). A compiler whose name identifies it as a C++
#   compiler the C++ Standard Library automatically to the linker step, while
#   a C compiler does not.
# - To use the new C++ Standard Library from the LLVM project, both the compiler
#   AND the linker options must contain -stdlib=libc++. Since the purpose of
#   libc++ is to support the C++11 standard, it is probably advisable to also
#   use the compiler-only option -std=c++11.

# ----------------------------------------------------------------------
# Configurable settings
# Subsequent sections are based on settings in this section,
# you should not need to change anything in these other sections.
# ----------------------------------------------------------------------
# Disable a platform build by setting the platform-specific variable to 0, or by
# commenting out the platform-specific line so that the variable becomes
# undefined
IPHONEOS_BUILD_ENABLED=1
IPHONE_SIMULATOR_BUILD_ENABLED=1
# The Mac OS X build is no longer actively maintained and will probably fail.
# Its goal used to be to get a Fuego binary that is usable from the Mac OS X
# command line to test out things. These days I prefer to build Fuego manually,
# using a Boost build from MacPorts or some other package management system.
#MACOSX_BUILD_ENABLED=1

IPHONEOS_BASESDK_VERSION=6.1
IPHONE_SIMULATOR_BASESDK_VERSION=6.1
MACOSX_BASESDK_VERSION=10.8  # If you use 10.4u, set deployment target separately

# Deployment target variables are not exported because they are NOT used as
# environment variables that are passed on to the compiler. Instead, they are
# used further down to construct a compiler option (e.g. -miphoneos-version-min
# for iOS). This is noteworthy because llvm-gcc used to recognize
# IPHONEOS_DEPLOYMENT_TARGET and MACOSX_DEPLOYMENT_TARGET as environment
# variables. There was no separate deployment target for the simulator, llvm-gcc
# used IPHONEOS_DEPLOYMENT_TARGET for the simulator build. clang++ possibly
# still recognizes the environment variables, but we no longer depend on this.
IPHONEOS_DEPLOYMENT_TARGET=5.0
IPHONEOS_SIMULATOR_DEPLOYMENT_TARGET=5.0
MACOSX_DEPLOYMENT_TARGET=10.8

# These are converted to compiler flags later on via the MAKE_ARCH_CPPFLAGS
# function
IPHONEOS_ARCH="armv7"            # becomes IPHONEOS_ARCH_CPPFLAGS
IPHONEOS_SIMULATOR_ARCH="i386"   # becomes IPHONE_SIMULATOR_ARCH_CPPFLAGS
MACOSX_ARCH="i386"               # becomes MACOSX_ARCH_CPPFLAGS

# Xcode 4.x supports llvm-gcc, a variant of GCC variant that integrates the new
# LLVM architecture. If llvm-gcc is to be used for compilation, compiler names
# such as "llvm-gcc-4.2" and "llvm-g++-4.2" can be defined. Different versions
# of Xcode use different compiler versions.
# Xcode 5.0 and later only supports clang, the pure LLVM implementation
# sponsored by Apple. If clang is to be used for compilation, the compiler names
# "clang" and "clang++ can be defined (even though the "clang" executable is
# just a frontend to the actual gcc/g++ compiler and other tools of the
# toolchain). Interestingly, the names no longer includes a version number.
IPHONEOS_GCC_NAME=clang
IPHONEOS_GPLUSPLUS_NAME=clang++
IPHONE_SIMULATOR_GCC_NAME=clang
IPHONE_SIMULATOR_GPLUSPLUS_NAME=clang++
MACOSX_GCC_NAME=clang
MACOSX_GPLUSPLUS_NAME=clang++

# -pipe = Use pipes rather than temporary files for communication between the
#         various stages of compilation.
# -Os = Optimize for size, but not at the expense of speed
# -gdwarf-2 = Produce debugging information in DWARF version 2 format
COMMON_CPPFLAGS="-pipe -Os -gdwarf-2"
IPHONEOS_CPPFLAGS="-miphoneos-version-min=$IPHONEOS_DEPLOYMENT_TARGET"
IPHONE_SIMULATOR_CPPFLAGS="-mios-simulator-version-min=$IPHONEOS_SIMULATOR_DEPLOYMENT_TARGET"
MACOSX_CPPFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

COMMON_LDLAGS=""
IPHONEOS_LDFLAGS="-miphoneos-version-min=$IPHONEOS_DEPLOYMENT_TARGET"
IPHONE_SIMULATOR_LDFLAGS="-mios-simulator-version-min=$IPHONEOS_SIMULATOR_DEPLOYMENT_TARGET"
MACOSX_LDFLAGS="-mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"

# Settings for builds based on bjam
BJAM_TOOLSET=darwin
COMMON_BJAMFLAGS="toolset=$BJAM_TOOLSET link=static"
IPHONEOS_BJAMFLAGS="architecture=arm target-os=iphone macosx-version=iphone-$IPHONEOS_BASESDK_VERSION"
IPHONE_SIMULATOR_BJAMFLAGS="architecture=x86 target-os=iphone macosx-version=iphonesim-$IPHONE_SIMULATOR_BASESDK_VERSION"
MACOSX_BJAMFLAGS="architecture=x86 target-os=darwin"

# Settings for builds based on configure/make
COMMON_CONFIGUREFLAGS="--disable-shared --enable-static"
IPHONEOS_CONFIGUREFLAGS="--host=arm-apple-darwin10"
IPHONE_SIMULATOR_CONFIGUREFLAGS="--host=i386-apple-darwin10"
# possibly new:
#IPHONE_SIMULATOR_CONFIGUREFLAGS="--host=i686-apple-darwin10"
MACOSX_CONFIGUREFLAGS=""
# possibly new:
#MACOSX_CONFIGUREFLAGS="--host=i686-apple-darwin11"

# ----------------------------------------------------------------------
# Locations
#
# Directory structure defined here looks like this:
#   BUILD_BASEDIR
#     +-- src
#     |    +-- software1
#     |    |    +-- source code archive file 1 (e.g. SOFTWARE_NAME-0.7.tar.gz)
#     |    |    +-- source code directory 1 (extracted archive file 1)
#     |    |    +-- source code archive file 2 (e.g. SOFTWARE_NAME-1.2.tar.gz)
#     |    |    +-- source code directory 2 (extracted archive file 1)
#     |    |    [...]
#     |    +-- software2
#     |    [...]
#     +-- install
#         +-- Xcode.app/Contents/Developer/Platforms
#              +-- iPhoneOS.platform/Developer/SDKs/iPhoneOS6.0.sdk
#              |    +-- bin
#              |    +-- include
#              |    +-- lib
#              |    [...]
#              +-- iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.0.sdk
#              |    +-- bin
#              |    +-- include
#              |    +-- lib
#              |    [...]
#              +-- MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk
#              |    +-- bin
#              |    +-- include
#              |    +-- lib
#              |    [...]
# ----------------------------------------------------------------------
if test -z "$BUILD_BASEDIR"; then
  echo "Environment variable BUILD_BASEDIR is not set"
  exit 1
fi
if test -z "$SOFTWARE_NAME"; then
  echo "Environment variable SOFTWARE_NAME is not set"
  exit 1
fi
DOWNLOAD_DIR="$BUILD_BASEDIR/src/$SOFTWARE_NAME"  # source archives are downloaded here
SRC_BASEDIR="$DOWNLOAD_DIR"                       # sources are extracted and built here
PREFIX_BASEDIR="$BUILD_BASEDIR/install"           # build results are installed here; platform-specific prefixes
                                                  # are constructed later on by adding the base SDK path

# ----------------------------------------------------------------------
# All platforms
# ----------------------------------------------------------------------
XCODE_SELECT_PATH="$(xcode-select -print-path)"
PLATFORMS_BASEDIR="$XCODE_SELECT_PATH/Platforms"

# ----------------------------------------------------------------------
# iPhoneOS platform
# ----------------------------------------------------------------------
IPHONEOS_SDKPREFIX="iphoneos"
IPHONEOS_SDKNAME="${IPHONEOS_SDKPREFIX}${IPHONEOS_BASESDK_VERSION}"
IPHONEOS_PREFIX="iPhoneOS"
IPHONEOS_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONEOS_PREFIX.platform"
IPHONEOS_BASESDK_DIR="$IPHONEOS_PLATFORMDIR/Developer/SDKs/${IPHONEOS_PREFIX}${IPHONEOS_BASESDK_VERSION}.sdk"
IPHONEOS_CC="$(xcrun -sdk $IPHONEOS_SDKNAME -find $IPHONEOS_GCC_NAME)"
IPHONEOS_CXX="$(xcrun -sdk $IPHONEOS_SDKNAME -find $IPHONEOS_GPLUSPLUS_NAME)"
IPHONEOS_PREFIXDIR="${PREFIX_BASEDIR}${IPHONEOS_BASESDK_DIR}"

# ----------------------------------------------------------------------
# iPhone Simulator platform
# ----------------------------------------------------------------------
IPHONE_SIMULATOR_SDKPREFIX="iphonesimulator"
IPHONE_SIMULATOR_SDKNAME="${IPHONE_SIMULATOR_SDKPREFIX}${IPHONE_SIMULATOR_BASESDK_VERSION}"
IPHONE_SIMULATOR_PREFIX="iPhoneSimulator"
IPHONE_SIMULATOR_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONE_SIMULATOR_PREFIX.platform"
IPHONE_SIMULATOR_BASESDK_DIR="$IPHONE_SIMULATOR_PLATFORMDIR/Developer/SDKs/${IPHONE_SIMULATOR_PREFIX}${IPHONE_SIMULATOR_BASESDK_VERSION}.sdk"
IPHONE_SIMULATOR_CC="$(xcrun -sdk $IPHONE_SIMULATOR_SDKPREFIX -find $IPHONE_SIMULATOR_GCC_NAME)"
IPHONE_SIMULATOR_CXX="$(xcrun -sdk $IPHONE_SIMULATOR_SDKPREFIX -find $IPHONE_SIMULATOR_GPLUSPLUS_NAME)"
IPHONE_SIMULATOR_PREFIXDIR="${PREFIX_BASEDIR}${IPHONE_SIMULATOR_BASESDK_DIR}"

# ----------------------------------------------------------------------
# Mac OS X platform
# ----------------------------------------------------------------------
MACOSX_SDKPREFIX="macosx"
MACOSX_SDKNAME="${MACOSX_SDKPREFIX}${MACOSX_BASESDK_VERSION}"
MACOSX_PREFIX="MacOSX"
MACOSX_PLATFORMDIR="$PLATFORMS_BASEDIR/$MACOSX_PREFIX.platform"
MACOSX_BASESDK_DIR="$MACOSX_PLATFORMDIR/Developer/SDKs/${MACOSX_PREFIX}${MACOSX_BASESDK_VERSION}.sdk"
MACOSX_CC="$(xcrun -sdk $MACOSX_SDKNAME -find $MACOSX_GCC_NAME)"
MACOSX_CXX="$(xcrun -sdk $MACOSX_SDKNAME -find $MACOSX_GPLUSPLUS_NAME)"
MACOSX_PREFIXDIR="${PREFIX_BASEDIR}${MACOSX_BASESDK_DIR}"

# +------------------------------------------------------------------------
# | Converts a space-separated list of architectures to a series of compiler
# | flags, like this: "-arch <foo> -arch <bar> [...]".
# |
# | The compiler flags are stored in the global environment variable
# | ARCH_CPPFLAGS. If the variable is not empty, the flags are appended.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Space-separated list of architectures
# +------------------------------------------------------------------------
# | Return values:
# |  None
# +------------------------------------------------------------------------
MAKE_ARCH_CPPFLAGS()
{
  typeset ARCHITECTURES="$1"
  if test -z "$ARCHITECTURES"; then
    return
  fi

  typeset ARCHITECTURE
  for ARCHITECTURE in $ARCHITECTURES; do
    ARCH_CPPFLAGS="$ARCH_CPPFLAGS -arch $ARCHITECTURE"
  done
}
MAKE_ARCH_CPPFLAGS "$IPHONEOS_ARCH"
IPHONEOS_ARCH_CPPFLAGS="$ARCH_CPPFLAGS"
unset ARCH_CPPFLAGS
MAKE_ARCH_CPPFLAGS "$IPHONEOS_SIMULATOR_ARCH"
IPHONE_SIMULATOR_ARCH_CPPFLAGS="$ARCH_CPPFLAGS"
unset ARCH_CPPFLAGS
MAKE_ARCH_CPPFLAGS "$MACOSX_ARCH"
MACOSX_ARCH_CPPFLAGS="$ARCH_CPPFLAGS"
unset ARCH_CPPFLAGS
