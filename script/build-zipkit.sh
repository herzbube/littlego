#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the ZipKit static library.
# |
# | https://github.com/kolpanic/ZipKit/
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/ZipKit"

# Variables describing the build
ZIPKIT_BUILD_CONFIGURATION="Release"
ZIPKIT_BUILDRESULT_FILENAME="libtouchzipkit.a"

# These paths are relative to the root directory of the extracted source archive
ZIPKIT_HEADER_SRCDIR="ZipKit"
ZIPKIT_XCODEPROJ_BASEDIR="."
ZIPKIT_XCODEPROJ_FILENAME="$ZIPKIT_XCODEPROJ_BASEDIR/ZipKit.xcodeproj"
ZIPKIT_XCODEPROJ_BUILDDIR="$ZIPKIT_XCODEPROJ_BASEDIR/build"
ZIPKIT_XCODEPROJ_IPHONEOS_BUILDDIR="$ZIPKIT_XCODEPROJ_BUILDDIR/$ZIPKIT_BUILD_CONFIGURATION-$IPHONEOS_SDKPREFIX"
ZIPKIT_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$ZIPKIT_XCODEPROJ_BUILDDIR/$ZIPKIT_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_SDKPREFIX"

# These paths are relative to the destination PREFIXDIR
ZIPKIT_HEADER_DESTDIR="include/zipkit"
ZIPKIT_LIB_DESTDIR="lib"

# xcodebuild flags
ZIPKIT_COMMON_XCODEBUILDFLAGS="-configuration $ZIPKIT_BUILD_CONFIGURATION -target touchzipkit"
ZIPKIT_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_SDKNAME"
ZIPKIT_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_SDKNAME"


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
    xcodebuild $ZIPKIT_COMMON_XCODEBUILDFLAGS $ZIPKIT_IPHONEOS_XCODEBUILDFLAGS -project "$ZIPKIT_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    xcodebuild $ZIPKIT_COMMON_XCODEBUILDFLAGS $ZIPKIT_IPHONE_SIMULATOR_XCODEBUILDFLAGS -project "$ZIPKIT_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
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
    mkdir -p "$IPHONEOS_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp $ZIPKIT_HEADER_SRCDIR/*.h $ZIPKIT_HEADER_SRCDIR/MacFUSE/*.h "$IPHONEOS_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    if test ! -d "$IPHONEOS_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"; then
      mkdir -p "$IPHONEOS_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
    fi
    cp "$ZIPKIT_XCODEPROJ_IPHONEOS_BUILDDIR/$ZIPKIT_BUILDRESULT_FILENAME" "$IPHONEOS_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp $ZIPKIT_HEADER_SRCDIR/*.h $ZIPKIT_HEADER_SRCDIR/MacFUSE/*.h "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    if test ! -d "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"; then
      mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
    fi
    cp "$ZIPKIT_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR/$ZIPKIT_BUILDRESULT_FILENAME" "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi
  return 0
}
