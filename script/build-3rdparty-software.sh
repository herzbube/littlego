#!/usr/bin/env bash

# =========================================================================
# | Builds all 3rdparty software packages so that the project can then be
# | built on top of them.
# =========================================================================

VERBOSE_BUILD="-q"
OPTIONS="v"
while getopts $OPTIONS OPTION
do
  case $OPTION in
    v)
      VERBOSE_BUILD=""
      ;;
  esac
done

shift $(($OPTIND - 1))

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"

# Other variables
SOFTWARE_PACKAGES="fuego sgfckit"
BUILD_SCRIPT="$SCRIPT_DIR/build-software.sh"

if test $# -ne 0; then
  echo "$SCRIPT_NAME: No arguments supported."
  echo ""
  echo "This script will execute BUILD_SCRIPT for each of the SOFTWARE_PACKAGES:"
  echo "SOFTWARE_PACKAGES = $SOFTWARE_PACKAGES"
  echo "BUILD_SCRIPT = $BUILD_SCRIPT"
  exit 1
fi

if test ! -x "$BUILD_SCRIPT"; then
  echo "Build script $BUILD_SCRIPT not found"
  exit 1
fi

for SOFTWARE_PACKAGE in $SOFTWARE_PACKAGES; do
  $BUILD_SCRIPT $VERBOSE_BUILD $SOFTWARE_PACKAGE
  if test $? -ne 0; then
    echo "Build failed for software package "$SOFTWARE_PACKAGE""
    echo "Try running with -v for verbose to see error details."
    exit 1
  fi
  echo ""
done
