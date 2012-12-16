#!/usr/bin/env bash

# =========================================================================
# Creates the source distribution (.tar.gz) of Little Go.
#
# THIS SCRIPT IS NO LONGER MAINTAINED. SOURCE DISTRIBUTIONS ARE NOW AVAILABLE
# DIRECTLY FROM GITHUB.
#
# Assumes that this script is run from a subdirectory nested one level deep
# within the project folder. Also assumes that the project folder is a Git
# working tree with all changes necessary for the release committed.
#
# The source distribution is assembled from a clean Git clone of the working
# tree. This gets rid of any temporary (.DS_STORE and the like) or generated
# files. The source distribution file is then placed into the "dist"
# subdirectory within the project folder.
# =========================================================================

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"
USAGE_LINE="$SCRIPT_NAME -h | <version>"

# Other variables
PROJECT_DIR="$(dirname "$0")/.."
# Make sure that project directory is an absolute path
case "$PROJECT_DIR" in
  /*) ;;
  *)  PROJECT_DIR="$(pwd)/$PROJECT_DIR"
      ;;
esac
TMP_DIR="/tmp/$SCRIPT_NAME.tmp.$$"
PROJECT_DISTDIR="$PROJECT_DIR/dist"
PROJECT_BUILDDIR="$PROJECT_DIR/build/Release"
PROJECT_NAME=littlego

if test $# -eq 0; then
  echo "No version given"
  echo "$USAGE_LINE"
  exit 1
fi
if test $# -gt 1; then
  echo "Too many arguments"
  echo "$USAGE_LINE"
  exit 1
fi
case $1 in
  -h|--help)
    echo "$USAGE_LINE"
    exit 0
    ;;
  *)
    VERSION=$1
    ;;
esac
shift $(expr $OPTIND - 1)
DISTRIBUTION_NAME="$PROJECT_NAME-$VERSION"
SOURCE_DISTRIBUTION_DIR="$DISTRIBUTION_NAME"
SOURCE_DISTRIBUTION_FILE="$SOURCE_DISTRIBUTION_DIR.tar.gz"

# Create directories
echo "Creating (temporary) folders..."
mkdir -p "$TMP_DIR"
if test $? -ne 0; then
  echo "error mkdir -p $TMP_DIR"
  exit 1
fi
if test ! -d "$PROJECT_DISTDIR"; then
  mkdir -p "$PROJECT_DISTDIR"
  if test $? -ne 0; then
    echo "error mkdir -p $PROJECT_DISTDIR"
    exit 1
  fi
fi

# Make the source distribution (from a clean git clone)
cd "$TMP_DIR"
git clone "$PROJECT_DIR" "$SOURCE_DISTRIBUTION_DIR"
if test $? -ne 0; then
  echo "Error git-clone $PROJECT_DIR $SOURCE_DISTRIBUTION_DIR"
  exit 1
fi

echo "Creating source distribution file $SOURCE_DISTRIBUTION_FILE..."
tar cfz "$SOURCE_DISTRIBUTION_FILE" --exclude .git "$SOURCE_DISTRIBUTION_DIR"
if test $? -ne 0; then
  echo "Error tarring"
  exit 1
fi
mv "$SOURCE_DISTRIBUTION_FILE" "$PROJECT_DISTDIR"

# Cleanup
echo "Cleaning up..."
rm -rf "$TMP_DIR"

echo "Source distribution file placed in project folder subdirectory $PROJECT_DISTDIR"
