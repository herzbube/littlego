#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the Cocoa Lumberjack logging framework.
# |
# | https://github.com/CocoaLumberjack/CocoaLumberjack
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/CocoaLumberjack"

# Variables describing the build
LUMBERJACK_BUILD_CONFIGURATION="Release"
LUMBERJACK_BUILD_TARGET="CocoaLumberjack-iOS-Static"
LUMBERJACK_BUILDRESULT_FILENAME="libCocoaLumberjack.a"

# These paths are relative to the root directory of the extracted source archive
LUMBERJACK_XCODEPROJ_FILENAME="Lumberjack.xcodeproj"
LUMBERJACK_XCODEPROJ_BUILDDIR="build"
LUMBERJACK_XCODEPROJ_IPHONEOS_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONEOS_SDKPREFIX"
LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_SDKPREFIX"
LUMBERJACK_HEADER_SRCDIR="Classes"

# These paths are relative to the destination PREFIXDIR
LUMBERJACK_HEADER_DESTDIR="include/CocoaLumberjack"
LUMBERJACK_LIB_DESTDIR="lib"

# xcodebuild flags
LUMBERJACK_COMMON_XCODEBUILDFLAGS="-configuration $LUMBERJACK_BUILD_CONFIGURATION -target $LUMBERJACK_BUILD_TARGET"
LUMBERJACK_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_SDKNAME"
LUMBERJACK_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_SDKNAME"


# +------------------------------------------------------------------------
# | Performs pre-build steps.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  None
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
PRE_BUILD_STEPS_SOFTWARE()
{
  echo "Cleaning up Git repository ..."
  # Remove everything not under version control...
  git clean -dfx
  if test $? -ne 0; then
    return 1
  fi
  # Throw away local changes
  git reset --hard
  if test $? -ne 0; then
    return 1
  fi
  return 0
}

# +------------------------------------------------------------------------
# | Builds and installs the software package.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  None
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS_SOFTWARE()
{
  typeset BUILDACTION_BUILD="build"
  typeset BUILDACTION_CLEAN="clean"

  if test "$IPHONEOS_BUILD_ENABLED" = "1"; then
    xcodebuild $LUMBERJACK_COMMON_XCODEBUILDFLAGS $LUMBERJACK_IPHONEOS_XCODEBUILDFLAGS -project "$LUMBERJACK_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    xcodebuild $LUMBERJACK_COMMON_XCODEBUILDFLAGS $LUMBERJACK_IPHONE_SIMULATOR_XCODEBUILDFLAGS -project "$LUMBERJACK_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
    if test $? -ne 0; then
      return 1
    fi
  fi

  return 0
}

# +------------------------------------------------------------------------
# | Performs steps to install the software for a specific platform.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Source BUILDDIR for the platform
# |  * Destination PREFIXDIR for the platform
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
INSTALL_STEPS_SOFTWARE_PLATFORM()
{
  typeset BUILDDIR="$1"
  typeset PREFIXDIR="$2"

  # Copy header files
  rm -rf "$PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
  mkdir -p "$PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
  cp $LUMBERJACK_HEADER_SRCDIR/*.h "$PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi

  # Copy static library
  if test ! -d "$PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"; then
    mkdir -p "$PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi
  cp "$BUILDDIR/$LUMBERJACK_BUILDRESULT_FILENAME" "$PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
}

# +------------------------------------------------------------------------
# | Performs steps to install the software.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  None
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
INSTALL_STEPS_SOFTWARE()
{
  if test "$IPHONEOS_BUILD_ENABLED" = "1"; then
    INSTALL_STEPS_SOFTWARE_PLATFORM "$LUMBERJACK_XCODEPROJ_IPHONEOS_BUILDDIR" "$IPHONEOS_PREFIXDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    INSTALL_STEPS_SOFTWARE_PLATFORM "$LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR" "$IPHONE_SIMULATOR_PREFIXDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  return 0
}
