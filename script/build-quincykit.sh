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


# These paths are relative to the root directory of the extracted source archive
QUINCYKIT_SRCDIR="client/iOS"

# These paths are relative to the destination PREFIX_BASEDIR
QUINCYKIT_DESTDIR="quincykit"

# Variables for downloading/extracting the source archive
QUINCYKIT_VERSION="531cd75fef32"
ARCHIVE_FILE="TheRealKerni-QuincyKit-2.1.9-0-ge7c7a3a.tar.gz"
ARCHIVE_URL="$ARCHIVE_BASEURL/$ARCHIVE_FILE"
ARCHIVE_CHECKSUM="3763a5b5e908b01e6ce05974f2046d2e1cc1ca652f802f1ef7d6854aa07aa37c"


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
  : # nothing to do
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
  mkdir -p "$PREFIX_BASEDIR/$QUINCYKIT_DESTDIR"
  cp -Rf $QUINCYKIT_SRCDIR/* "$PREFIX_BASEDIR/$QUINCYKIT_DESTDIR"
  rm -rf "$PREFIX_BASEDIR/$QUINCYKIT_DESTDIR/QuincyLib"
}
