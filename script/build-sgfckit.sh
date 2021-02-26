#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the libsgfc++ and SgfcKit libraries.
# |
# | https://github.com/herzbube/libsgfcplusplus
# | https://github.com/herzbube/SgfcKit
# |
# | See the main build script for more information.
# =========================================================================

SRC_DIR="$SRC_BASEDIR/SgfcKit"
DEST_DIR="$PREFIX_BASEDIR"
CONFIGURATION="Release"
BUILD_FOLDER="build"
INSTALL_PREFIX="install"
FRAMEWORKS_INSTALL_FOLDER="Frameworks"

LIBSGFCPLUSPLUS_SRC_DIR="$SRC_DIR/libsgfcplusplus"
LIBSGFCPLUSPLUS_FRAMEWORK_NAME="libsgfcplusplus_static.framework"
LIBSGFCPLUSPLUS_FRAMEWORK_SRC_DIR="$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$LIBSGFCPLUSPLUS_FRAMEWORK_NAME"
LIBSGFCPLUSPLUS_FRAMEWORK_DEST_DIR="$DEST_DIR/$LIBSGFCPLUSPLUS_FRAMEWORK_NAME"

SGFCKIT_SRC_DIR="$SRC_DIR"
SGFCKIT_FRAMEWORK_NAME="SgfcKit_static.framework"
SGFCKIT_FRAMEWORK_SRC_DIR="$SGFCKIT_SRC_DIR/$BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$SGFCKIT_FRAMEWORK_NAME"
SGFCKIT_FRAMEWORK_DEST_DIR="$DEST_DIR/$SGFCKIT_FRAMEWORK_NAME"

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
  echo "Cleaning up libsgfc++ Git repository ..."
  pushd "$LIBSGFCPLUSPLUS_SRC_DIR" >/dev/null
  # Remove everything not under version control...
  git clean -dfx
  RETVAL=$?
  if test $RETVAL -eq 0; then
    # Throw away local changes
    git reset --hard
    RETVAL=$?
  fi
  popd >/dev/null
  if test $RETVAL -ne 0; then
    return 1
  fi

  echo "Cleaning up SgfcKit Git repository ..."
  pushd "$SGFCKIT_SRC_DIR" >/dev/null
  # Remove everything not under version control...
  git clean -dfx
  RETVAL=$?
  if test $RETVAL -eq 0; then
    # Throw away local changes
    git reset --hard
    RETVAL=$?
  fi
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
  # Bitcode notes
  # - The CMake option -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=YES adds the
  #   option ENABLE_BITCODE=YES to the Xcode build. This in turn causes the
  #   Clang compiler option -fembed-bitcode-marker to be used. This does not
  #   really add bitcode to the built object files, instead it merely adds a
  #   placeholder. When the final build of Little Go is archived this causes
  #   the archiving to fail because of missing Bitcode. For this reason
  #   ENABLE_BITCODE=YES is not used.
  #   Causes the compiler option -fembed-bitcode-marker to be used.
  # - The CMake option -DCMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE=bitcode
  #   adds the option BITCODE_GENERATION_MODE=bitcode to the Xcode build. This
  #   in turn causes the Clang compiler option -fembed-bitcode to be used. This
  #   actually generates and embeds the necessary Bitcode into the built object
  #   files so that the archiving of the final Little Go build can succeed.
  #
  # StackOverflow references
  # - https://stackoverflow.com/a/34965178/1054378
  # - https://stackoverflow.com/a/31486233/1054378
  # - https://stackoverflow.com/a/31346742/1054378

  echo "Begin building libsgfc++ ..."
  pushd "$LIBSGFCPLUSPLUS_SRC_DIR" >/dev/null
  mkdir "$BUILD_FOLDER"
  cd "$BUILD_FOLDER"
  cmake .. -G Xcode -T buildsystem=1 -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO -DCMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE=bitcode -DCMAKE_IOS_INSTALL_COMBINED=YES -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DCMAKE_OSX_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
  RETVAL=$?
  if test $RETVAL -eq 0; then
    cmake --build . --config $CONFIGURATION --target install
    RETVAL=$?
  fi
  popd >/dev/null
  if test $RETVAL -ne 0; then
    return 1
  fi

  echo "Begin building SgfcKit ..."
  pushd "$SGFCKIT_SRC_DIR" >/dev/null
  mkdir "$BUILD_FOLDER"
  cd "$BUILD_FOLDER"
  cmake .. -G Xcode -T buildsystem=1 -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=NO -DCMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE=bitcode -DCMAKE_IOS_INSTALL_COMBINED=YES -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX -DCMAKE_OSX_DEPLOYMENT_TARGET=$IPHONEOS_DEPLOYMENT_TARGET
  RETVAL=$?
  if test $RETVAL -eq 0; then
    cmake --build . --config $CONFIGURATION --target install
    RETVAL=$?
  fi
  popd >/dev/null
  if test $RETVAL -ne 0; then
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
  rm -rf "$LIBSGFCPLUSPLUS_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  rm -rf "$SGFCKIT_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Creating installation folder $DEST_DIR ..."
  mkdir -p "$DEST_DIR"

  echo "Copying libsgfc++ installation files to $LIBSGFCPLUSPLUS_FRAMEWORK_DEST_DIR ..."
  cp -R "$LIBSGFCPLUSPLUS_FRAMEWORK_SRC_DIR" "$LIBSGFCPLUSPLUS_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Copying SgfcKit installation files to $SGFCKIT_FRAMEWORK_DEST_DIR ..."
  cp -R "$SGFCKIT_FRAMEWORK_SRC_DIR" "$SGFCKIT_FRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  return 0
}
