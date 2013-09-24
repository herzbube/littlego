#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to download and extract the files of the ZipKit
# | framework.
# |
# | https://bitbucket.org/kolpanic/zipkit/
# |
# | See the main build script for more information.
# =========================================================================


# Variables describing the build
ZIPKIT_BUILD_CONFIGURATION="Release"
ZIPKIT_BUILDRESULT_FILENAME="libtouchzipkit.a"

# These paths are relative to the root directory of the extracted source archive
ZIPKIT_HEADER_SRCDIR="."
ZIPKIT_XCODEPROJ_BASEDIR="."
ZIPKIT_XCODEPROJ_FILENAME="$ZIPKIT_XCODEPROJ_BASEDIR/ZipKit.xcodeproj"
ZIPKIT_XCODEPROJ_BUILDDIR="$ZIPKIT_XCODEPROJ_BASEDIR/build"
ZIPKIT_XCODEPROJ_IPHONEOS_BUILDDIR="$ZIPKIT_XCODEPROJ_BUILDDIR/$ZIPKIT_BUILD_CONFIGURATION-$IPHONEOS_SDKPREFIX"
ZIPKIT_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$ZIPKIT_XCODEPROJ_BUILDDIR/$ZIPKIT_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_SDKPREFIX"
ZIPKIT_XCODEPROJ_MACOSX_BUILDDIR="$ZIPKIT_XCODEPROJ_BUILDDIR/$ZIPKIT_BUILD_CONFIGURATION"

# These paths are relative to the destination PREFIXDIR
ZIPKIT_HEADER_DESTDIR="include/zipkit"
ZIPKIT_LIB_DESTDIR="lib"

# Variables for downloading/extracting the source archive
ZIPKIT_VERSION="531cd75fef32"
ARCHIVE_FILE="kolpanic-zipkit-531cd75fef32.tar.gz"
ARCHIVE_URL="$ARCHIVE_BASEURL/$ARCHIVE_FILE"
ARCHIVE_CHECKSUM="c2837a1f9f9e748f6ae2d67eb2a2415ed6169f73c1c406c90571f75b49a80208"

# xcodebuild flags
ZIPKIT_COMMON_XCODEBUILDFLAGS="-configuration $ZIPKIT_BUILD_CONFIGURATION -target touchzipkit"
ZIPKIT_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_SDKNAME"
ZIPKIT_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_SDKNAME"
ZIPKIT_MACOSX_XCODEBUILDFLAGS="-sdk $MACOSX_SDKNAME"


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
  : # nothing to do
}

# +------------------------------------------------------------------------
# | Builds and installs the software package.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  * 0|1 = Whether or not to clean the results of a previous build
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS_SOFTWARE()
{
  typeset CLEAN_BUILD="$1"

  typeset BUILDACTION_BUILD="build"
  typeset BUILDACTION_CLEAN=""
  if test "$CLEAN_BUILD" = "1"; then
    BUILDACTION_CLEAN="clean"
  fi

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

  if test "$MACOSX_BUILD_ENABLED" = "1"; then
    xcodebuild $ZIPKIT_COMMON_XCODEBUILDFLAGS $ZIPKIT_MACOSX_XCODEBUILDFLAGS -project "$ZIPKIT_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
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
    cp "$ZIPKIT_XCODEPROJ_IPHONEOS_BUILDDIR/$ZIPKIT_BUILDRESULT_FILENAME" "$IPHONEOS_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    mkdir -p "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp $ZIPKIT_HEADER_SRCDIR/*.h $ZIPKIT_HEADER_SRCDIR/MacFUSE/*.h "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp "$ZIPKIT_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR/$ZIPKIT_BUILDRESULT_FILENAME" "$IPHONE_SIMULATOR_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
  fi

  if test "$MACOSX_BUILD_ENABLED" = "1"; then
    mkdir -p "$MACOSX_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp $ZIPKIT_HEADER_SRCDIR/*.h "$MACOSX_PREFIXDIR/$ZIPKIT_HEADER_DESTDIR"
    cp "$ZIPKIT_XCODEPROJ_MACOSX_BUILDDIR/$ZIPKIT_BUILDRESULT_FILENAME" "$MACOSX_PREFIXDIR/$ZIPKIT_LIB_DESTDIR"
  fi
}
