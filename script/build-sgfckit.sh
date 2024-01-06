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
SIMULATOR_BUILD_FOLDER="simulator"
DEVICE_BUILD_FOLDER="device"
INSTALL_PREFIX="install"
FRAMEWORKS_INSTALL_FOLDER="Frameworks"
CMAKE_GENERATOR_NAME="Xcode"
CMAKE_SYSTEM_NAME="iOS"
# Bitcode notes
# - The CMake option -DCMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE=YES adds the
#   option ENABLE_BITCODE=YES to the Xcode build. This in turn causes the
#   Clang compiler option -fembed-bitcode-marker to be used. This does not
#   really add bitcode to the built object files, instead it merely adds a
#   placeholder. When the final build of Little Go is archived this causes
#   the archiving to fail because of missing Bitcode. For this reason
#   ENABLE_BITCODE=YES is not used.
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
CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE="bitcode"

LIBSGFCPLUSPLUS_SRC_DIR="$SRC_DIR/libsgfcplusplus"
LIBSGFCPLUSPLUS_FRAMEWORK_NAME="libsgfcplusplus_static.framework"
LIBSGFCPLUSPLUS_XCFRAMEWORK_NAME="libsgfcplusplus.xcframework"
LIBSGFCPLUSPLUS_XCFRAMEWORK_DEST_DIR="$DEST_DIR/$LIBSGFCPLUSPLUS_XCFRAMEWORK_NAME"

SGFCKIT_SRC_DIR="$SRC_DIR"
SGFCKIT_FRAMEWORK_NAME="SgfcKit_static.framework"
SGFCKIT_XCFRAMEWORK_NAME="SgfcKit.xcframework"
SGFCKIT_XCFRAMEWORK_DEST_DIR="$DEST_DIR/$SGFCKIT_XCFRAMEWORK_NAME"

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
# | Builds a software package for a specific platform (device or simulator).
# +------------------------------------------------------------------------
# | Arguments:
# |  * Base folder of the software package, i.e. the folder where the
# |    software package's root CMakeLists.txt is located.
# |  * Build folder where the CMake build system should be generated and the
# |    build results should be installed.
# |  * SDK name to be used for setting CMAKE_OSX_SYSROOT.
# |  * Deployment target to be used for setting CMAKE_OSX_DEPLOYMENT_TARGET.
# |  * The name of a CMake variable to set. An empty string indicates that no
# |    CMake variable should be set. The variable name must not contain space
# |    characters or other characters interpreted by the shell.
# |  * The value to use for setting the CMake variable. This is ignored if the
# |    CMake variable name argument is an empty string. The variable value must
# |    not contain space characters or other characters interpreted by the
# |    shell.
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS_PLATFORM()
{
  local BASE_FOLDER="$1"
  local BUILD_FOLDER="$2"
  local SDK_NAME="$3"
  local DEPLOYMENT_TARGET="$4"
  local OPTIONAL_CMAKE_VARIABLE_NAME="$5"
  local OPTIONAL_CMAKE_VARIABLE_VALUE="$6"

  local OPTIONAL_CMAKE_VARIABLE_ARGUMENT=""
  if test -n "$OPTIONAL_CMAKE_VARIABLE_NAME"; then
    OPTIONAL_CMAKE_VARIABLE_ARGUMENT="-D$OPTIONAL_CMAKE_VARIABLE_NAME=$OPTIONAL_CMAKE_VARIABLE_VALUE"
  fi

  mkdir -p "$BUILD_FOLDER"
  if test $? -ne 0; then
    return 1
  fi

  pushd "$BUILD_FOLDER" >/dev/null

  cmake "$BASE_FOLDER" \
        -G "$CMAKE_GENERATOR_NAME" \
        "-DCMAKE_SYSTEM_NAME=$CMAKE_SYSTEM_NAME" \
        "-DCMAKE_OSX_SYSROOT=$SDK_NAME" \
        "-DCMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE=$CMAKE_XCODE_ATTRIBUTE_BITCODE_GENERATION_MODE" \
        "-DCMAKE_OSX_DEPLOYMENT_TARGET=$DEPLOYMENT_TARGET" \
        $OPTIONAL_CMAKE_VARIABLE_ARGUMENT
  RETVAL=$?
  if test $RETVAL -eq 0; then
    cmake --build . --config "$CONFIGURATION"
    RETVAL=$?
    if test $RETVAL -eq 0; then
      cmake --install . --prefix "$BUILD_FOLDER/$INSTALL_PREFIX"
      RETVAL=$?
    fi
  fi

  popd >/dev/null

  if test $RETVAL -ne 0; then
    return 1
  fi
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
  echo "Begin building libsgfc++ ..."

  echo "Begin libsgfc++ simulator build ..."
  BUILD_STEPS_PLATFORM "$LIBSGFCPLUSPLUS_SRC_DIR" \
                       "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$SIMULATOR_BUILD_FOLDER" \
                       "$IPHONE_SIMULATOR_SDKNAME" \
                       "$IPHONE_SIMULATOR_DEPLOYMENT_TARGET" \
                       "" \
                       ""
  if test $? -ne 0; then
    return 1
  fi

  echo "Begin libsgfc++ device build ..."
  BUILD_STEPS_PLATFORM "$LIBSGFCPLUSPLUS_SRC_DIR" \
                       "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$DEVICE_BUILD_FOLDER" \
                       "$IPHONEOS_SDKNAME" \
                       "$IPHONEOS_DEPLOYMENT_TARGET" \
                       "" \
                       ""
  if test $? -ne 0; then
    return 1
  fi

  echo "Begin building SgfcKit ..."

  echo "Begin SgfcKit simulator build ..."
  BUILD_STEPS_PLATFORM "$SGFCKIT_SRC_DIR" \
                       "$SGFCKIT_SRC_DIR/$BUILD_FOLDER/$SIMULATOR_BUILD_FOLDER" \
                       "$IPHONE_SIMULATOR_SDKNAME" \
                       "$IPHONE_SIMULATOR_DEPLOYMENT_TARGET" \
                       "LIBSGFCPLUSPLUS_INSTALLATION_PREFIX" \
                       "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$SIMULATOR_BUILD_FOLDER/$INSTALL_PREFIX"
  if test $? -ne 0; then
    return 1
  fi

  echo "Begin SgfcKit device build ..."
  BUILD_STEPS_PLATFORM "$SGFCKIT_SRC_DIR" \
                       "$SGFCKIT_SRC_DIR/$BUILD_FOLDER/$DEVICE_BUILD_FOLDER" \
                       "$IPHONEOS_SDKNAME" \
                       "$IPHONEOS_DEPLOYMENT_TARGET" \
                       "LIBSGFCPLUSPLUS_INSTALLATION_PREFIX" \
                       "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$DEVICE_BUILD_FOLDER/$INSTALL_PREFIX"
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
  rm -rf "$LIBSGFCPLUSPLUS_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi
  rm -rf "$SGFCKIT_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Creating installation folder $DEST_DIR ..."
  mkdir -p "$DEST_DIR"

  echo "Creating libsgfc++ XCFramework $LIBSGFCPLUSPLUS_XCFRAMEWORK_DEST_DIR ..."
  xcodebuild -create-xcframework \
             -framework "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$SIMULATOR_BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$LIBSGFCPLUSPLUS_FRAMEWORK_NAME" \
             -framework "$LIBSGFCPLUSPLUS_SRC_DIR/$BUILD_FOLDER/$DEVICE_BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$LIBSGFCPLUSPLUS_FRAMEWORK_NAME" \
             -output "$LIBSGFCPLUSPLUS_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  echo "Creating SgfcKit XCFramework $SGFCKIT_XCFRAMEWORK_DEST_DIR ..."
  xcodebuild -create-xcframework \
             -framework "$SGFCKIT_SRC_DIR/$BUILD_FOLDER/$SIMULATOR_BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$SGFCKIT_FRAMEWORK_NAME" \
             -framework "$SGFCKIT_SRC_DIR/$BUILD_FOLDER/$DEVICE_BUILD_FOLDER/$INSTALL_PREFIX/$FRAMEWORKS_INSTALL_FOLDER/$SGFCKIT_FRAMEWORK_NAME" \
             -output "$SGFCKIT_XCFRAMEWORK_DEST_DIR"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}
