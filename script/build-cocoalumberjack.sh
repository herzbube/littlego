#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to download and extract the files of the Cocoa
# | Lumberjack logging framework.
# |
# | https://github.com/robbiehanson/CocoaLumberjack
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/CocoaLumberjack"

# Variables describing the build
LUMBERJACK_BUILD_CONFIGURATION="Release"
LUMBERJACK_BUILDRESULT_FILENAME="libLumberjack.a"

# These paths are relative to the root directory of the extracted source archive
LUMBERJACK_HEADER_SRCDIR="Lumberjack"
LUMBERJACK_XCODEPROJ_BASEDIR="Xcode/LumberjackFramework/Mobile"
LUMBERJACK_XCODEPROJ_FILENAME="$LUMBERJACK_XCODEPROJ_BASEDIR/Lumberjack.xcodeproj"
LUMBERJACK_XCODEPROJ_BUILDDIR="$LUMBERJACK_XCODEPROJ_BASEDIR/build"
LUMBERJACK_XCODEPROJ_IPHONEOS_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONEOS_SDKPREFIX"
LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_SDKPREFIX"
LUMBERJACK_XCODEPROJ_MACOSX_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION"

# These paths are relative to the destination PREFIXDIR
LUMBERJACK_HEADER_DESTDIR="include/lumberjack"
LUMBERJACK_LIB_DESTDIR="lib"

# xcodebuild flags
LUMBERJACK_COMMON_XCODEBUILDFLAGS="-configuration $LUMBERJACK_BUILD_CONFIGURATION -target Lumberjack"
LUMBERJACK_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_SDKNAME"
LUMBERJACK_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_SDKNAME"
LUMBERJACK_MACOSX_XCODEBUILDFLAGS="-sdk $MACOSX_SDKNAME"


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
    mkdir -p "$IPHONEOS_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    cp $LUMBERJACK_HEADER_SRCDIR/*.h "$IPHONEOS_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    cp "$LUMBERJACK_XCODEPROJ_IPHONEOS_BUILDDIR/$LUMBERJACK_BUILDRESULT_FILENAME" "$IPHONEOS_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    cp $LUMBERJACK_HEADER_SRCDIR/*.h "$IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    if test ! -d "IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"; then
      mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
    fi
    cp "$LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR/$LUMBERJACK_BUILDRESULT_FILENAME" "$IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
  fi
  return 0
}
