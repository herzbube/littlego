#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the Boost and Fuego libraries.
# |
# | http://www.boost.org/
# | http://fuego.sourceforge.net/
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/fuego-on-ios"

BOOST_SRC_DIR="$SRC_DIR/boost"
BOOST_FRAMEWORK_NAME="boost.framework"
BOOST_FRAMEWORK_SRC_DIR="$BOOST_SRC_DIR/ios/framework/$BOOST_FRAMEWORK_NAME"
BOOST_FRAMEWORK_DEST_DIR="$PREFIX_BASEDIR/$BOOST_FRAMEWORK_NAME"

FUEGO_SRC_DIR="$SRC_DIR"
FUEGO_FRAMEWORK_NAME="fuego-on-ios.framework"
FUEGO_FRAMEWORK_SRC_DIR="$FUEGO_SRC_DIR/ios/framework/$FUEGO_FRAMEWORK_NAME"
FUEGO_FRAMEWORK_DEST_DIR="$PREFIX_BASEDIR/$FUEGO_FRAMEWORK_NAME"


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
  echo "Cleaning up Git repository ..."
  # Remove everything not under version control...
  git clean -dfx
  if test $? -ne 0; then
    return 1
  fi
  # Throw away local changes
  git reset --hard
  if test $? -ne 0; then
    return 1
  fi
  # The Boost build script performs its own cleanup in the Boost submodule
  return 0
}

# +------------------------------------------------------------------------
# | Builds the software package.
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
BUILD_STEPS_SOFTWARE()
{
  # Build Boost first. Build script runs both the iPhone and simulator builds.
  echo "Begin building Boost ..."
  pushd "$BOOST_SRC_DIR" >/dev/null
  ./boost.sh
  RETVAL=$?
  popd >/dev/null
  if test $RETVAL -ne 0; then
    return 1
  fi

  # Build Fuego after Boost. Build script Runs both the iPhone and simulator builds.
  echo "Begin building Fuego ..."
  ./build.sh
  return $?
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
  echo "Removing installation files from previous build ..."
  rm -rf "$BOOST_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  rm -rf "$FUEGO_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Copying Boost installation files to $BOOST_FRAMEWORK_DEST_DIR ..."
  cp -R "$BOOST_FRAMEWORK_SRC_DIR" "$BOOST_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Copying Fuego installation files to $FUEGO_FRAMEWORK_DEST_DIR ..."
  cp -R "$FUEGO_FRAMEWORK_SRC_DIR" "$FUEGO_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  return 0
}
