#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the Boost and Fuego libraries.
# |
# | https://www.boost.org/
# | http://fuego.sourceforge.net/
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/fuego-on-ios"
DEST_DIR="$PREFIX_BASEDIR"

BOOST_SRC_DIR="$SRC_DIR/boost"
BOOST_XCFRAMEWORK_NAME="boost.xcframework"
BOOST_XCFRAMEWORK_SRC_DIR="$BOOST_SRC_DIR/build/$BOOST_XCFRAMEWORK_NAME"
BOOST_XCFRAMEWORK_DEST_DIR="$DEST_DIR/$BOOST_XCFRAMEWORK_NAME"
FUEGO_SRC_DIR="$SRC_DIR"
FUEGO_XCFRAMEWORK_NAME="fuego-on-ios.xcframework"
FUEGO_XCFRAMEWORK_SRC_DIR="$FUEGO_SRC_DIR/ios/framework/$FUEGO_XCFRAMEWORK_NAME"
FUEGO_XCFRAMEWORK_DEST_DIR="$DEST_DIR/$FUEGO_XCFRAMEWORK_NAME"

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

  # The following script performs the same operations as above on the
  # modular-boost Git submodule
  pushd "$BOOST_SRC_DIR" >/dev/null
  ./clean-and-reset.sh
  RETVAL=$?
  popd >/dev/null
  if test $RETVAL -ne 0; then
    return 1
  fi

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
  # Exporting these variables makes them visible to the Boost build script.
  # We expect that the deployment target variables are set by build-env.sh.
  # Note: The Boost build script does not support specifying the base SDK at
  # all.
  export IOS_VERSION="$IPHONEOS_DEPLOYMENT_TARGET"
  export IOS_SIM_VERSION="$IPHONE_SIMULATOR_DEPLOYMENT_TARGET"

  # Build Boost first. The build script supports a large number of platforms,
  # but we only need the iPhone and simulator builds.
  echo "Begin building Boost ..."
  pushd "$BOOST_SRC_DIR" >/dev/null
  ./boost.sh --platforms=ios,iossim
  RETVAL=$?
  popd >/dev/null
  if test $RETVAL -ne 0; then
    return 1
  fi

  # Exporting these variables makes them visible to the Fuego build script.
  # We expect that the variables are set by build-env.sh.
  # IMPORTANT: The deployment target variables must be exported only AFTER the
  # Boost build. Because these variables are known and interpreted by clang,
  # they would interfere with how the Boost build script manages the build.
  export IPHONEOS_BASESDK_VERSION
  export IPHONEOS_DEPLOYMENT_TARGET
  export IPHONE_SIMULATOR_BASESDK_VERSION
  export IPHONE_SIMULATOR_DEPLOYMENT_TARGET

  # Build Fuego after Boost. The build script runs both the iPhone and
  # simulator builds.
  echo "Begin building Fuego ..."
  ./build.sh
  if test $? -ne 0; then
    return 1
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
  echo "Removing installation files from previous build ..."
  rm -rf "$BOOST_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  rm -rf "$FUEGO_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Creating installation folder $DEST_DIR ..."
  mkdir -p "$DEST_DIR"

  echo "Copying Boost installation files to $BOOST_XCFRAMEWORK_DEST_DIR ..."
  cp -R "$BOOST_XCFRAMEWORK_SRC_DIR" "$BOOST_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Copying Fuego installation files to $FUEGO_XCFRAMEWORK_DEST_DIR ..."
  cp -R "$FUEGO_XCFRAMEWORK_SRC_DIR" "$FUEGO_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}
