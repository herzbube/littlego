#!/usr/bin/env bash

# =========================================================================
# | Builds all 3rdparty software packages so that the project can then be
# | built on top of them.
# =========================================================================

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"

# Other variables
SOFTWARE_PACKAGES="fuego sgfckit usermanual"
BUILD_SCRIPT="$SCRIPT_DIR/build-software.sh"

show_usage () {
  echo "Usage:"
  echo "./$SCRIPT_NAME [-v]"
  echo "-v (verbose): see all build script output (defaults to quiet)."
  echo ""
  echo "This script will execute BUILD_SCRIPT for each of the SOFTWARE_PACKAGES:"
  echo "SOFTWARE_PACKAGES = $SOFTWARE_PACKAGES"
  echo "BUILD_SCRIPT = $BUILD_SCRIPT"
  exit 1
}

# Default quiet to true
QUIET_OPT="-q"
while getopts ":v" OPTION
do
  case $OPTION in
    v) QUIET_OPT="";;
    \?)
      echo "Invalid option -$OPTARG"
      echo ""
      show_usage;;
  esac
done
shift $(($OPTIND - 1))

if test $# -ne 0; then
  show_usage
fi

if test ! -x "$BUILD_SCRIPT"; then
  echo "Build script $BUILD_SCRIPT not found"
  exit 1
fi

for SOFTWARE_PACKAGE in $SOFTWARE_PACKAGES; do
  $BUILD_SCRIPT $QUIET_OPT $SOFTWARE_PACKAGE
  if test $? -ne 0; then
    echo "Build failed for software package "$SOFTWARE_PACKAGE""
    echo "Try running with -v for verbose to see error details."
    exit 1
  fi
  echo ""
done
