#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the Fuego library.
# |
# | http://fuego.sourceforge.net/
# |
# | See the main build script for more information.
# =========================================================================

# Variables for downloading/extracting the source archive
FUEGO_VERSION="uec-cup-2013"
ARCHIVE_FILE="fuego-$FUEGO_VERSION.tar.gz"
ARCHIVE_URL="$ARCHIVE_BASEURL/$ARCHIVE_FILE"
ARCHIVE_CHECKSUM="43097a2d904110bac2a220d45ffe79e1f40b305fa514b348e1860d53664d3e94"

# Compiler flags
FUEGO_COMMON_CPPFLAGS="-fvisibility=hidden -fvisibility-inlines-hidden"
FUEGO_IPHONEOS_CPPFLAGS="-isysroot $IPHONEOS_BASESDK_DIR -I$IPHONEOS_PREFIXDIR/include"
FUEGO_IPHONE_SIMULATOR_CPPFLAGS="-isysroot $IPHONE_SIMULATOR_BASESDK_DIR -I$IPHONE_SIMULATOR_PREFIXDIR/include"
FUEGO_MACOSX_CPPFLAGS="-isysroot $MACOSX_BASESDK_DIR -I$MACOSX_PREFIXDIR/include"

# Linker flags
# Notes:
# - If the configure flag --with-boost-libdir is used, there is no need for
#   the -L linker flag. It is included here for completeness sake, and because
#   in a future version of fuego the need for --with-boost-libdir might go away.
# - Apple's documentation (SDK Compatibility Guide) specifies that -syslibroot
#   should be used for the linker to specify the base SDK. This does not work
#   with gcc 4.2.1, however.
FUEGO_COMMON_LDFLAGS=""
FUEGO_IPHONEOS_LDFLAGS="-isysroot $IPHONEOS_BASESDK_DIR -L$IPHONEOS_PREFIXDIR/lib"
FUEGO_IPHONE_SIMULATOR_LDFLAGS="-isysroot $IPHONE_SIMULATOR_BASESDK_DIR -L$IPHONE_SIMULATOR_PREFIXDIR/lib"
FUEGO_MACOSX_LDFLAGS="-isysroot $MACOSX_BASESDK_DIR -L$MACOSX_PREFIXDIR/lib"

# configure flags
# Note: At the moment, configure will not work without --with-boost-libdir.
# If this flag is not specified, configure fails when it tries to detect
# boost_thread in $BOOSTLIBDIR (at line 4375 for Fuego 1.0). The environment
# variable is empty, probably because of some mis-configuration in Fuego's
# autoconf process.
FUEGO_COMMON_CONFIGUREFLAGS=""
FUEGO_IPHONEOS_CONFIGUREFLAGS="--with-boost-libdir=$IPHONEOS_PREFIXDIR/lib"
FUEGO_IPHONE_SIMULATOR_CONFIGUREFLAGS="--with-boost-libdir=$IPHONE_SIMULATOR_PREFIXDIR/lib"
FUEGO_MACOSX_CONFIGUREFLAGS="--with-boost-libdir=$MACOSX_PREFIXDIR/lib"

# +------------------------------------------------------------------------
# | Creates a single unified static library with the merged content from all
# | the other static libraries found in the current directory and its
# | sub-directories.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Full path to the installation base directory (the "prefix" directory)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_AND_INSTALL_SINGLE_LIB()
{
  typeset PREFIX_DIR="$1"
  typeset SINGLELIB_TEMPDIR="singlelib-tempdir"
  typeset SINGLELIB_NAME="libfuego.a"

  echo "Creating single unified library..."

  mkdir "$SINGLELIB_TEMPDIR"
  if test $? -ne 0; then
    echo "Could not create temporary directory"
    return 1
  fi
  cd "$SINGLELIB_TEMPDIR"
  find ../ -name libfuego\*.a | xargs -n 1 ar x
  if test $? -ne 0; then
    echo "Error extracting content from other static libraries"
    return 1
  fi
  ar cru "$SINGLELIB_NAME" *.o
  if test $? -ne 0; then
    echo "Error merging content from other static libraries"
    return 1
  fi
  ranlib "$SINGLELIB_NAME"
  if test $? -ne 0; then
    echo "Error running ranlib on unified library"
    return 1
  fi
  cp "$SINGLELIB_NAME" "$PREFIX_DIR/lib"
  if test $? -ne 0; then
    echo "Error installing unified library"
    return 1
  fi
  cd ..
  rm -rf "$SINGLELIB_TEMPDIR"

  return 0
}

# +------------------------------------------------------------------------
# | Backend function that is invoked once for each architecture.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Name that describes the architecture to be built. This name is used for
# |    messages displayed to the user
# |  * Full path to the C++ compiler
# |  * Full path to the C compiler
# |  * List of compiler flags
# |  * List of linker flags
# |  * List of configure flags
# |  * Full path to the installation base directory (the "prefix" directory)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_ARCHITECTURE()
{
  typeset ARCH_PREFIX="$1"
  typeset ARCH_CXX="$2"
  typeset ARCH_CC="$3"
  typeset ARCH_CPPFLAGS="$4"
  typeset ARCH_LDFLAGS="$5"
  typeset ARCH_CONFIGUREFLAGS="$6"
  typeset ARCH_PREFIXDIR="$7"

  export CXX="$ARCH_CXX"
  export CC="$ARCH_CC"
  # Deployment target already set
  export CPPFLAGS="$ARCH_CPPFLAGS"
  export LDFLAGS="$ARCH_LDFLAGS"
  echo "Configuring Fuego for $ARCH_PREFIX"
  if test -f Makefile; then
    make distclean
    if test $? -ne 0; then
      return 1
    fi
  fi
  ./configure $ARCH_CONFIGUREFLAGS
  if test $? -ne 0; then
    return 1
  fi
  echo "Building Fuego for $ARCH_PREFIX"
  make
  if test $? -ne 0; then
    return 1
  fi
  # Must install immediately, otherwise the next build will overwrite the
  # results of this build
  make install
  if test $? -ne 0; then
    return 1
  fi
  BUILD_AND_INSTALL_SINGLE_LIB "$ARCH_PREFIXDIR"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}

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

  echo "Running autoreconf..."
  which autoreconf >/dev/null
  if test $? -ne 0; then
    echo "autoreconf not found, maybe you need to provide this through fink or macports?"
    return 1
  fi
  which aclocal >/dev/null
  if test $? -ne 0; then
    echo "automake not found, maybe you need to provide this through fink or macports?"
    return 1
  fi
  autoreconf -i
  if test $? -ne 0; then
    echo "Error running autoreconf"
    return 1
  fi

  touch "$PATCH_GUARD_FILE"
}

# +------------------------------------------------------------------------
# | Builds the software package.
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
  if test "$CLEAN_BUILD" -eq 0; then
    cat << EOF
Ignoring the "don't clean" request. The Fuego build must always clean because
it builds for multiple architectures, and configure/make cannot handle this
inside the same directory.
EOF
  fi

  if test "$IPHONEOS_BUILD_ENABLED" = "1"; then
    BUILD_ARCHITECTURE \
      "$IPHONEOS_PREFIX" \
      "$IPHONEOS_CXX" \
      "$IPHONEOS_CC" \
      "$IPHONEOS_ARCH_CPPFLAGS $COMMON_CPPFLAGS $FUEGO_COMMON_CPPFLAGS $IPHONEOS_CPPFLAGS $FUEGO_IPHONEOS_CPPFLAGS" \
      "$IPHONEOS_ARCH_CPPFLAGS $COMMON_LDFLAGS $FUEGO_COMMON_LDFLAGS $IPHONEOS_LDFLAGS $FUEGO_IPHONEOS_LDFLAGS" \
      "--prefix=$IPHONEOS_PREFIXDIR $COMMON_CONFIGUREFLAGS $FUEGO_COMMON_CONFIGUREFLAGS $IPHONEOS_CONFIGUREFLAGS $FUEGO_IPHONEOS_CONFIGUREFLAGS" \
      "$IPHONEOS_PREFIXDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$IPHONE_SIMULATOR_BUILD_ENABLED" = "1"; then
    BUILD_ARCHITECTURE \
      "$IPHONE_SIMULATOR_PREFIX" \
      "$IPHONE_SIMULATOR_CXX" \
      "$IPHONE_SIMULATOR_CC" \
      "$IPHONE_SIMULATOR_ARCH_CPPFLAGS $COMMON_CPPFLAGS $FUEGO_COMMON_CPPFLAGS $IPHONE_SIMULATOR_CPPFLAGS $FUEGO_IPHONE_SIMULATOR_CPPFLAGS" \
      "$IPHONE_SIMULATOR_ARCH_CPPFLAGS $COMMON_LDFLAGS $FUEGO_COMMON_LDFLAGS $IPHONE_SIMULATOR_LDFLAGS $FUEGO_IPHONE_SIMULATOR_LDFLAGS" \
      "--prefix=$IPHONE_SIMULATOR_PREFIXDIR $COMMON_CONFIGUREFLAGS $FUEGO_COMMON_CONFIGUREFLAGS $IPHONE_SIMULATOR_CONFIGUREFLAGS $FUEGO_IPHONE_SIMULATOR_CONFIGUREFLAGS" \
      "$IPHONE_SIMULATOR_PREFIXDIR"
    if test $? -ne 0; then
      return 1
    fi
  fi

  if test "$MACOSX_BUILD_ENABLED" = "1"; then
    BUILD_ARCHITECTURE \
      "$MACOSX_PREFIX" \
      "$MACOSX_CXX" \
      "$MACOSX_CC" \
      "$MACOSX_ARCH_CPPFLAGS $COMMON_CPPFLAGS $FUEGO_COMMON_CPPFLAGS $MACOSX_CPPFLAGS $FUEGO_MACOSX_CPPFLAGS" \
      "$MACOSX_ARCH_CPPFLAGS $COMMON_LDFLAGS $FUEGO_COMMON_LDFLAGS $MACOSX_LDFLAGS $FUEGO_MACOSX_LDFLAGS" \
      "--prefix=$MACOSX_PREFIXDIR $COMMON_CONFIGUREFLAGS $FUEGO_COMMON_CONFIGUREFLAGS $MACOSX_CONFIGUREFLAGS $FUEGO_MACOSX_CONFIGUREFLAGS" \
      "$MACOSX_PREFIXDIR"
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
  # Must create a symbolic link if the iPhoneSimulator base SDK version is
  # different from the iPhoneOS base SDK version. This is necessary because, at
  # the moment, in Xcode there is no way to specify different versions for the
  # two SDKs.
  if test "$IPHONEOS_BASESDK_VERSION" != "$IPHONE_SIMULATOR_BASESDK_VERSION"; then
    PREFIX_DIRNAME="$(dirname "$IPHONE_SIMULATOR_PREFIXDIR")"
    PREFIX_BASENAME="$(basename "$IPHONE_SIMULATOR_PREFIXDIR")"
    PREFIX_ALTERNATE_BASENAME="${IPHONE_SIMULATOR_PREFIX}${IPHONEOS_BASESDK_VERSION}.sdk"
    echo "Creating symlink $PREFIX_ALTERNATE_BASENAME to make Xcode happy..."
    cd "$PREFIX_DIRNAME" >/dev/null 2>&1
    if test ! -e "$PREFIX_ALTERNATE_BASENAME"; then
      ln -s "$PREFIX_BASENAME" "$PREFIX_ALTERNATE_BASENAME"
    else
      echo "Symlink (or some other file) already exists, nothing to do"
    fi
    cd - >/dev/null 2>&1
  fi

  # Nothing else to do; build results were installed immediately after each
  # build, because configure/make cannot handle multiple build results in the
  # same directory
  return 0
}
