#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the MBProgressHUD static library.
# |
# | https://github.com/matej/MBProgressHUD
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/MBProgressHUD"

# Variables describing the build
MBPROGRESSHUD_BUILD_CONFIGURATION="Release"
MBPROGRESSHUD_BUILDRESULT_FILENAME="libMBProgressHUD.a"

# These paths are relative to the root directory of the extracted source archive
MBPROGRESSHUD_HEADER_SRCDIR="."
MBPROGRESSHUD_XCODEPROJ_BASEDIR="."
MBPROGRESSHUD_XCODEPROJ_FILENAME="$MBPROGRESSHUD_XCODEPROJ_BASEDIR/MBProgressHUD.xcodeproj"
MBPROGRESSHUD_XCODEPROJ_BUILDDIR="$MBPROGRESSHUD_XCODEPROJ_BASEDIR/build"
MBPROGRESSHUD_XCODEPROJ_IPHONEOS_BUILDDIR="$MBPROGRESSHUD_XCODEPROJ_BUILDDIR/$MBPROGRESSHUD_BUILD_CONFIGURATION-$IPHONEOS_SDKPREFIX"
MBPROGRESSHUD_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$MBPROGRESSHUD_XCODEPROJ_BUILDDIR/$MBPROGRESSHUD_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_SDKPREFIX"

# These paths are relative to the destination PREFIXDIR
MBPROGRESSHUD_HEADER_DESTDIR="include/mbprogresshud"
MBPROGRESSHUD_LIB_DESTDIR="lib"

# xcodebuild flags
MBPROGRESSHUD_TARGET_NAME="MBProgressHUD Static Library"
MBPROGRESSHUD_COMMON_XCODEBUILDFLAGS="-configuration $MBPROGRESSHUD_BUILD_CONFIGURATION"
MBPROGRESSHUD_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_SDKNAME"
MBPROGRESSHUD_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_SDKNAME"


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
    xcodebuild $MBPROGRESSHUD_COMMON_XCODEBUILDFLAGS $MBPROGRESSHUD_IPHONEOS_XCODEBUILDFLAGS -target "$MBPROGRESSHUD_TARGET_NAME" -project "$MBPROGRESSHUD_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    xcodebuild $MBPROGRESSHUD_COMMON_XCODEBUILDFLAGS $MBPROGRESSHUD_IPHONE_SIMULATOR_XCODEBUILDFLAGS -target "$MBPROGRESSHUD_TARGET_NAME" -project "$MBPROGRESSHUD_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
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
    mkdir -p "$IPHONEOS_PREFIXDIR/$MBPROGRESSHUD_HEADER_DESTDIR"
    cp $MBPROGRESSHUD_HEADER_SRCDIR/*.h "$IPHONEOS_PREFIXDIR/$MBPROGRESSHUD_HEADER_DESTDIR"
    if test ! -d "$IPHONEOS_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"; then
      mkdir -p "$IPHONEOS_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"
    fi
    cp "$MBPROGRESSHUD_XCODEPROJ_IPHONEOS_BUILDDIR/$MBPROGRESSHUD_BUILDRESULT_FILENAME" "$IPHONEOS_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$MBPROGRESSHUD_HEADER_DESTDIR"
    cp $MBPROGRESSHUD_HEADER_SRCDIR/*.h "$IPHONE_SIMULATOR_PREFIXDIR/$MBPROGRESSHUD_HEADER_DESTDIR"
    if test ! -d "$IPHONE_SIMULATOR_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"; then
      mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"
    fi
    cp "$MBPROGRESSHUD_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR/$MBPROGRESSHUD_BUILDRESULT_FILENAME" "$IPHONE_SIMULATOR_PREFIXDIR/$MBPROGRESSHUD_LIB_DESTDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi
  return 0
}
