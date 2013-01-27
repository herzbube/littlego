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


# Variables describing the build
LUMBERJACK_BUILD_CONFIGURATION="Release"
LUMBERJACK_BUILDRESULT_FILENAME="libCocoaLumberjack.a"

# These paths are relative to the root directory of the extracted source archive
LUMBERJACK_HEADER_SRCDIR="Lumberjack"
LUMBERJACK_XCODEPROJ_BASEDIR="Xcode/CocoaLumberjack"
LUMBERJACK_XCODEPROJ_FILENAME="$LUMBERJACK_XCODEPROJ_BASEDIR/CocoaLumberjack.xcodeproj"
LUMBERJACK_XCODEPROJ_BUILDDIR="$LUMBERJACK_XCODEPROJ_BASEDIR/build"
LUMBERJACK_XCODEPROJ_IPHONEOS_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONEOS_XCODEBUILD_SDKPREFIX"
LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION-$IPHONE_SIMULATOR_XCODEBUILD_SDKPREFIX"
LUMBERJACK_XCODEPROJ_MACOSX_BUILDDIR="$LUMBERJACK_XCODEPROJ_BUILDDIR/$LUMBERJACK_BUILD_CONFIGURATION"

# These paths are relative to the destination PREFIXDIR
LUMBERJACK_HEADER_DESTDIR="include/cocoalumberjack"
LUMBERJACK_LIB_DESTDIR="lib"

# Variables for downloading/extracting the source archive
LUMBERJACK_VERSION="1.2.1"
ARCHIVE_FILE="robbiehanson-CocoaLumberjack-1.2.1-0-g0d3c95b.tar.gz"
ARCHIVE_URL="$ARCHIVE_BASEURL/$ARCHIVE_FILE"
ARCHIVE_CHECKSUM="952f565b6aa5f1faf7046c411ed361d7023567b738431dc94393f28899317e45"

# xcodebuild flags
LUMBERJACK_COMMON_XCODEBUILDFLAGS="-configuration $LUMBERJACK_BUILD_CONFIGURATION -target CocoaLumberjack"
LUMBERJACK_IPHONEOS_XCODEBUILDFLAGS="-sdk $IPHONEOS_XCODEBUILD_SDKNAME"
LUMBERJACK_IPHONE_SIMULATOR_XCODEBUILDFLAGS="-sdk $IPHONE_SIMULATOR_XCODEBUILD_SDKNAME"
LUMBERJACK_MACOSX_XCODEBUILDFLAGS="-sdk $MACOSX_XCODEBUILD_SDKNAME"


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
  PATCH_GUARD_FILE="$SOFTWARE_NAME.has.already.been.patched"
  if test -f "$PATCH_GUARD_FILE"; then
    echo "It appears that patches have already been applied; skipping pre-build patch step"
    return 0
  fi

  if test ! -d "$PATCH_BASEDIR/$SOFTWARE_NAME"; then
    return 1
  fi

  for PATCH_FILE in $PATCH_BASEDIR/$SOFTWARE_NAME/*.patch; do
    echo "Applying patch file $PATCH_FILE..."
    # Try to prevent any accidents here that render the source code unusable
    # --forward ignores patches that seem to be already applied
    # --fuzz=0 causes a patch to fail if the context doesn't match 100% (i.e.
    # fuzz factor is 0)
    patch --forward -p1 <"$PATCH_FILE"
    if test $? -ne 0; then
      echo "Error applying patch file $PATCH_FILE"
      return 1
    fi
  done
  echo "Successfully applied all patches"

  touch "$PATCH_GUARD_FILE"
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

  if test "$MACOSX_BUILD_ENABLED" = "1"; then
    xcodebuild $LUMBERJACK_COMMON_XCODEBUILDFLAGS $LUMBERJACK_MACOSX_XCODEBUILDFLAGS -project "$LUMBERJACK_XCODEPROJ_FILENAME" $BUILDACTION_CLEAN $BUILDACTION_BUILD
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
    cp "$LUMBERJACK_XCODEPROJ_IPHONE_SIMULATOR_BUILDDIR/$LUMBERJACK_BUILDRESULT_FILENAME" "$IPHONE_SIMULATOR_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
  fi

  if test "$MACOSX_BUILD_ENABLED" = "1"; then
    mkdir -p "$MACOSX_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    cp $LUMBERJACK_HEADER_SRCDIR/*.h "$MACOSX_PREFIXDIR/$LUMBERJACK_HEADER_DESTDIR"
    cp "$LUMBERJACK_XCODEPROJ_MACOSX_BUILDDIR/$LUMBERJACK_BUILDRESULT_FILENAME" "$MACOSX_PREFIXDIR/$LUMBERJACK_LIB_DESTDIR"
  fi
}
