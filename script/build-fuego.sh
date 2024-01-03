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
BOOST_XCFRAMEWORK_SRC_DIR="$BOOST_SRC_DIR/ios/framework/$BOOST_XCFRAMEWORK_NAME"
BOOST_XCFRAMEWORK_DEST_DIR="$DEST_DIR/$BOOST_XCFRAMEWORK_NAME"
# The Boost build script has some hardcoded default architectures to build.
# These include 32-bit architectures. Because our deployment target is newer
# than 10.0 only 64-bit architectures are supported by clang. We therefore must
# override the Boost build script's default and specify only 64-bit
# architectures. To support building out of the box for both Intel and Silicon
# Macs we attempt to determine the simulator platform by looking at the host
# machine's hardware platform. Note that for Fuego the architecture to build is
# selected automatically by Xcode.
BOOST_IPHONE_ARCHITECTURES="arm64"
case "$(uname -m)" in
  *x86*) BOOST_IPHONE_SIMULATOR_ARCHITECTURES="x86_64" ;;
      *) BOOST_IPHONE_SIMULATOR_ARCHITECTURES="arm64" ;;
esac

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
  # Exporting these variables makes them visible to the Boost and Fuego build
  # scripts. We expect that the variables are set by build-env.sh.
  export IPHONEOS_BASESDK_VERSION
  export IPHONEOS_DEPLOYMENT_TARGET
  export IPHONE_SIMULATOR_BASESDK_VERSION
  export IPHONE_SIMULATOR_DEPLOYMENT_TARGET
  # Export some more variables just for the Boost build. We expect these
  # variables to be set at the top of this build script.
  export IPHONE_ARCHITECTURES="$BOOST_IPHONE_ARCHITECTURES"
  export IPHONE_SIMULATOR_ARCHITECTURES="$BOOST_IPHONE_SIMULATOR_ARCHITECTURES"

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
