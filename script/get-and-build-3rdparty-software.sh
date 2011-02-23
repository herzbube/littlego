#!/usr/bin/env bash

# =========================================================================
# | Retrieves all 3rdparty software packages from the Internet and builds
# | the packages so that the project can then be built on top of them.
# =========================================================================

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"

BUILD_SCRIPT="$SCRIPT_DIR/build-software.sh"
if test ! -x "$BUILD_SCRIPT"; then
  echo "Build script $BUILD_SCRIPT not found"
  exit 1
fi

$BUILD_SCRIPT -q boost
$BUILD_SCRIPT -q fuego
