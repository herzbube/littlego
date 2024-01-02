#!/usr/bin/env /bin/bash

# Different 3rd party software packages should be built using the same
# environment for a given platform (iOS Device, iPhone Simulator, macOS),
# otherwise they won't work together. The build script of each 3rd party
# software package should therefore source this script and use the variables
# defined here to setup the software-specific build process.
#
# Software-specific build settings (e.g. CPPFLAGS)  must be defined in the
# software-specific build script.
#
# Preconditions for invoking this script:
# - The environment variable BUILD_BASEDIR must contain the absolute path to the
#   base directory from which all build activities will occur
# - The environment variable SOFTWARE_NAME must contain the name of the software
#   to build
# - xcode-select must point to the appropriate Xcode version that should be
#   used for the build

# ----------------------------------------------------------------------
# Configurable settings
# Subsequent sections are based on settings in this section,
# you should not need to change anything in these other sections.
# ----------------------------------------------------------------------
# Disable a platform build by setting the platform-specific variable to 0, or by
# commenting out the platform-specific line so that the variable becomes
# undefined
IPHONEOS_BUILD_ENABLED=1
IPHONE_SIMULATOR_BUILD_ENABLED=1

IPHONEOS_BASESDK_VERSION=$(xcrun --sdk iphoneos --show-sdk-version)
IPHONEOS_DEPLOYMENT_TARGET=15.0
IPHONE_SIMULATOR_BASESDK_VERSION=$(xcrun --sdk iphonesimulator --show-sdk-version)
IPHONE_SIMULATOR_DEPLOYMENT_TARGET=15.0


# ----------------------------------------------------------------------
# Locations
#
# Directory structure defined here looks like this:
#   BUILD_BASEDIR
#     +-- src
#     |    +-- software1.git
#     |    +-- software2.git
#     |    [...]
#     +-- install
#         +-- boost.framework
#         +-- fuego-on-ios.framework
#         +-- Xcode.app/Contents/Developer/Platforms
#              +-- iPhoneOS.platform/Developer/SDKs/iPhoneOS6.1.sdk
#              |    +-- bin
#              |    +-- include
#              |    +-- lib
#              |    [...]
#              +-- iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator6.1.sdk
#                   +-- bin
#                   +-- include
#                   +-- lib
#                   [...]
# ----------------------------------------------------------------------
if test -z "$BUILD_BASEDIR"; then
  echo "Environment variable BUILD_BASEDIR is not set"
  exit 1
fi
if test -z "$SOFTWARE_NAME"; then
  echo "Environment variable SOFTWARE_NAME is not set"
  exit 1
fi
SRC_BASEDIR="$BUILD_BASEDIR/src"
PREFIX_BASEDIR="$BUILD_BASEDIR/install"           # build results are installed here; platform-specific prefixes
                                                  # are constructed later on by adding the base SDK path

# ----------------------------------------------------------------------
# All platforms
# ----------------------------------------------------------------------
XCODE_SELECT_PATH="$(xcode-select -print-path)"
PLATFORMS_BASEDIR="$XCODE_SELECT_PATH/Platforms"

# ----------------------------------------------------------------------
# iPhoneOS platform
# ----------------------------------------------------------------------
IPHONEOS_SDKPREFIX="iphoneos"
IPHONEOS_SDKNAME="${IPHONEOS_SDKPREFIX}${IPHONEOS_BASESDK_VERSION}"
IPHONEOS_PREFIX="iPhoneOS"
IPHONEOS_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONEOS_PREFIX.platform"
IPHONEOS_BASESDK_DIR="$IPHONEOS_PLATFORMDIR/Developer/SDKs/${IPHONEOS_PREFIX}${IPHONEOS_BASESDK_VERSION}.sdk"
IPHONEOS_PREFIXDIR="${PREFIX_BASEDIR}${IPHONEOS_BASESDK_DIR}"

# ----------------------------------------------------------------------
# iPhone Simulator platform
# ----------------------------------------------------------------------
IPHONE_SIMULATOR_SDKPREFIX="iphonesimulator"
IPHONE_SIMULATOR_SDKNAME="${IPHONE_SIMULATOR_SDKPREFIX}${IPHONE_SIMULATOR_BASESDK_VERSION}"
IPHONE_SIMULATOR_PREFIX="iPhoneSimulator"
IPHONE_SIMULATOR_PLATFORMDIR="$PLATFORMS_BASEDIR/$IPHONE_SIMULATOR_PREFIX.platform"
IPHONE_SIMULATOR_BASESDK_DIR="$IPHONE_SIMULATOR_PLATFORMDIR/Developer/SDKs/${IPHONE_SIMULATOR_PREFIX}${IPHONE_SIMULATOR_BASESDK_VERSION}.sdk"
IPHONE_SIMULATOR_PREFIXDIR="${PREFIX_BASEDIR}${IPHONE_SIMULATOR_BASESDK_DIR}"
