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
# - It is expected that the Developer Tools (Xcode, SDKs etc.) are located in
#   /Developer
#
# Notes:
# - If CXX is left undefined, configure will abort at some stage due to a linker
#   error (libgcc is not found). The reason for this is that configure finds,
#   and uses, a compiler in /usr/bin, but this compiler does not work with the
#   compiler flag -isysroot.
# - CXX must refer to a compiler named g++-something; if it refers to a compiler
#   named gcc-something, configure will abort at some stage due to a linker
#   error (undefined symbol). The reason for this is that CXX is used to
#   compile C++ files; when a C++ file is compiled, a symbol is added to the
#   object file which requires libstdc++ at link time. A compiler named
#   g++-something adds libstdc++ automatically to the linker step, while
#   gcc-something does not.


# ----------------------------------------------------------------------
# Configurable settings
# Subsequent sections are based on settings in this section,
# you should not need to change anything in these other sections.
# ----------------------------------------------------------------------
IPHONEOS_BASESDK_VERSION=4.2
IPHONE_SIMULATOR_BASESDK_VERSION=4.2
MACOSX_BASESDK_VERSION=10.6  # If you use 10.4u, set deployment target separately

# Deployment target variables must be exported because they are actually
# used as environment variables, not just as input for constructing a command
# line.
# Note: There is no deployment target for the simulator, it uses the one for
# iPhoneOS
export IPHONEOS_DEPLOYMENT_TARGET=$IPHONEOS_BASESDK_VERSION
export MACOSX_DEPLOYMENT_TARGET=$MACOSX_BASESDK_VERSION

# These are converted to compiler flags later on via the MAKE_ARCH_CPPFLAGS
# function
IPHONEOS_ARCH="armv7"            # becomes IPHONEOS_ARCH_CPPFLAGS
IPHONEOS_SIMULATOR_ARCH="i386"   # becomes IPHONE_SIMULATOR_ARCH_CPPFLAGS
MACOSX_ARCH="i386"               # becomes MACOSX_ARCH_CPPFLAGS

IPHONEOS_GCC_VERSION=4.2
IPHONE_SIMULATOR_GCC_VERSION=4.2
MACOSX_GCC_VERSION=4.2

# -pipe = Use pipes rather than temporary files for communication between the
#         various stages of compilation.
# -Os = Optimize for size, but not at the expense of speed
# -gdwarf-2 = Produce debugging information in DWARF version 2 format
# -thumb-interwork = Generate code which supports calling between the ARM and
#                    Thumb instruction sets.
COMMON_CPPFLAGS="-pipe -Os -gdwarf-2"
IPHONEOS_CPPFLAGS="-mthumb-interwork"
IPHONE_SIMULATOR_CPPFLAGS=""
MACOSX_CPPFLAGS=""

COMMON_LDLAGS=""
IPHONEOS_LDFLAGS=""
IPHONE_SIMULATOR_LDFLAGS=""
MACOSX_LDFLAGS=""

# Settings for builds based on bjam
BJAM_TOOLSET=darwin
COMMON_BJAMFLAGS="toolset=$BJAM_TOOLSET link=static"
IPHONEOS_BJAMFLAGS="architecture=arm target-os=iphone macosx-version=iphone-$IPHONEOS_BASESDK_VERSION"
IPHONE_SIMULATOR_BJAMFLAGS="architecture=x86 target-os=iphone macosx-version=iphone-$IPHONEOS_BASESDK_VERSION"
MACOSX_BJAMFLAGS="architecture=x86 target-os=darwin"

# Settings for builds based on configure/make
COMMON_CONFIGUREFLAGS="--disable-shared --enable-static"
IPHONEOS_CONFIGUREFLAGS="--host=arm-apple-darwin10"
IPHONE_SIMULATOR_CONFIGUREFLAGS="--host=i386-apple-darwin10"
MACOSX_CONFIGUREFLAGS=""

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
#         +-- iPhoneOS
#         |    +-- bin
#         |    +-- include
#         |    +-- lib
#         |    [...]
#         +-- iPhoneSimulator
#         +-- MacOSX
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
PREFIX_BASEDIR="$BUILD_BASEDIR/install"           # build results are installed here; platform-specific prefixes are defined later on

# ----------------------------------------------------------------------
# All platforms
# ----------------------------------------------------------------------
PLATFORMS_BASEDIR="/Developer/Platforms"

# ----------------------------------------------------------------------
# iPhoneOS platform
# ----------------------------------------------------------------------
IPHONEOS_PREFIX="iPhoneOS"
IPHONEOS_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONEOS_PREFIX.platform"
IPHONEOS_BASESDK_DIR="$IPHONEOS_PLATFORMDIR/Developer/SDKs/${IPHONEOS_PREFIX}${IPHONEOS_BASESDK_VERSION}.sdk"
IPHONEOS_BINDIR="$IPHONEOS_PLATFORMDIR/Developer/usr/bin"
IPHONEOS_CC="$IPHONEOS_BINDIR/gcc-$IPHONEOS_GCC_VERSION"
IPHONEOS_CXX="$IPHONEOS_BINDIR/g++-$IPHONEOS_GCC_VERSION"
IPHONEOS_PREFIXDIR="$PREFIX_BASEDIR/install-$IPHONEOS_PREFIX"

# ----------------------------------------------------------------------
# iPhone Simulator platform
# ----------------------------------------------------------------------
IPHONE_SIMULATOR_PREFIX="iPhoneSimulator"
IPHONE_SIMULATOR_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONE_SIMULATOR_PREFIX.platform"
IPHONE_SIMULATOR_BASESDK_DIR="$IPHONE_SIMULATOR_PLATFORMDIR/Developer/SDKs/${IPHONE_SIMULATOR_PREFIX}${IPHONE_SIMULATOR_BASESDK_VERSION}.sdk"
IPHONE_SIMULATOR_BINDIR="$IPHONE_SIMULATOR_PLATFORMDIR/Developer/usr/bin"
IPHONE_SIMULATOR_CC="$IPHONE_SIMULATOR_BINDIR/gcc-$IPHONE_SIMULATOR_GCC_VERSION"
IPHONE_SIMULATOR_CXX="$IPHONE_SIMULATOR_BINDIR/g++-$IPHONE_SIMULATOR_GCC_VERSION"
IPHONE_SIMULATOR_PREFIXDIR="$PREFIX_BASEDIR/install-$IPHONE_SIMULATOR_PREFIX"

# ----------------------------------------------------------------------
# Mac OS X platform
# ----------------------------------------------------------------------
MACOSX_PREFIX="MacOSX"
MACOSX_PLATFORMDIR="/."   # there is no real platform directory for Mac OS X
MACOSX_BASESDK_DIR="$MACOSX_PLATFORMDIR/Developer/SDKs/${MACOSX_PREFIX}${MACOSX_BASESDK_VERSION}.sdk"
MACOSX_BINDIR="$MACOSX_PLATFORMDIR/Developer/usr/bin"
MACOSX_CC="$MACOSX_BINDIR/gcc-$MACOSX_GCC_VERSION"
MACOSX_CXX="$MACOSX_BINDIR/g++-$MACOSX_GCC_VERSION"
MACOSX_PREFIXDIR="$PREFIX_BASEDIR/install-$MACOSX_PREFIX"

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
