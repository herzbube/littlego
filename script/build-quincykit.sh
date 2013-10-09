#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to download and extract the files of the QuincyKit
# | framework.
# |
# | https://github.com/therealkerni/QuincyKit
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/QuincyKit"
QUINCYKIT_SRCDIR="$SRC_DIR/client/iOS"
QUINCYKIT_DESTDIR="$PREFIX_BASEDIR/quincykit"


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
  echo "Removing installation files from previous build ..."
  rm -rf "$QUINCYKIT_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
  echo "Creating installation folder $QUINCYKIT_DESTDIR ..."
  mkdir -p "$QUINCYKIT_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
  echo "Copying installation files to $QUINCYKIT_DESTDIR ..."
  cp -Rf $QUINCYKIT_SRCDIR/* "$QUINCYKIT_DESTDIR"
  if test $? -ne 0; then
    return 1
  fi
  echo "Cleaning up in installation folder $QUINCYKIT_DESTDIR ..."
  rm -rf "$QUINCYKIT_DESTDIR/QuincyLib"
  if test $? -ne 0; then
    return 1
  fi
  return 0
}
