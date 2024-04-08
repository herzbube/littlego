#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the user manual.
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/usermanual"
DEST_DIR="$PREFIX_BASEDIR"

ZIP_FILENAME="littlego-usermanual.zip"
DOWNLOAD_URL="https://github.com/herzbube/littlego-usermanual/releases/latest/download/$ZIP_FILENAME"
SRC_FILE="$SRC_DIR/$ZIP_FILENAME"
DEST_FILE="$DEST_DIR/$ZIP_FILENAME"

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
  typeset CURL_ZFLAG=""

  if test -f "$SRC_FILE"; then
    CURL_ZFLAG="-z $SRC_FILE"
  fi

  echo "Downloading latest user manual (unless local file is present and newer) ..."
  curl -L "$DOWNLOAD_URL" $CURL_ZFLAG --output "$SRC_FILE"

  if test $? -eq 0; then
    echo "Download successful"
  else
    echo "Download failed"
    return 1
  fi

  cp "$SRC_FILE" "$DEST_FILE"
}
