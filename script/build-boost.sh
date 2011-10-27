#!/usr/bin/env bash

# =========================================================================
# | This is a script snippet that is included (via shell script sourcing) from
# | a main build script. This snippet provides the required environment
# | variables and functions to build the Boost library.
# |
# | http://www.boost.org/
# |
# | See the main build script for more information.
# =========================================================================

# General Boost variables
BOOST_VERSION="1_45_0"
# Build at least those libs that are required by dependencies
BOOST_LIBS="thread signals filesystem regex program_options system test date_time"
BOOST_LIBS_COMMA="$(echo $BOOST_LIBS | sed -e 's/ /,/g')"

# Variables for downloading/extracting the source archive
ARCHIVE_FILE="boost_$BOOST_VERSION.tar.bz2"
ARCHIVE_URL="$ARCHIVE_BASEURL/$ARCHIVE_FILE"
ARCHIVE_CHECKSUM="55ed3ec51d5687e8224c988e22bef215dacce04e037d9f689569a80c4377a6d5"

# Compiler flags
BOOST_COMMON_CPPFLAGS="-fvisibility=hidden -fvisibility-inlines-hidden -DBOOST_AC_USE_PTHREADS -DBOOST_SP_USE_PTHREADS"
BOOST_IPHONEOS_CPPFLAGS="-D_LITTLE_ENDIAN"
BOOST_IPHONE_SIMULATOR_CPPFLAGS=""
BOOST_MACOSX_CPPFLAGS=""

# Linker flags
BOOST_COMMON_LDFLAGS=""
BOOST_IPHONEOS_LDFLAGS=""
BOOST_IPHONE_SIMULATOR_LDFLAGS=""
BOOST_MACOSX_LDFLAGS=""

# bjam flags
BOOST_COMMON_BJAMFLAGS=""
BOOST_IPHONEOS_BJAMFLAGS=""
BOOST_IPHONE_SIMULATOR_BJAMFLAGS=""
BOOST_MACOSX_BJAMFLAGS=""

# +------------------------------------------------------------------------
# | Copies a few header files that are missing in the iPhoneOS SDK from the
# | iPhone Simulator SDK (where they are known to exist) to a location where
# | they are included for the ARM build as well as for the Simulator build.
# |
# | Notes:
# | - The information that this workaround is OK seems to be common knowledge
# |   on the Internet, but I have not tested this in any way
# | - Interestingly enough, the Boost build process seems to place the Boost
# |   root directory into the compiler's list of include directories (-I), so
# |   we can simply copy the files to this root directory
# | - On one of the Boost mailing lists I found a discussion about
# |   crt_externs.h -> it appears that the dependency on this header might go
# |   away in a future version of Boost
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
COPY_MISSING_HEADERS()
{
  echo "Copying missing headers..."

  typeset HEADER_FILES="crt_externs.h bzlib.h"
  typeset HEADER_FILE
  for HEADER_FILE in $HEADER_FILES; do
    cp "$IPHONE_SIMULATOR_BASESDK_DIR/usr/include/$HEADER_FILE" .
  done

  return 0
}

# +------------------------------------------------------------------------
# | Writes build settings into Boost's user-config.jam.
# |
# | A backup copy is made so that this function may operate on a pristine copy
# | of the file if it is invoked again later on with new build settings.
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
WRITE_BJAM_USERCONFIG()
{
  echo "Preparing bjam for build..."

  typeset BJAM_USERCONFIG_FILE="./tools/build/v2/user-config.jam"
  typeset ORIGINAL_BJAM_USERCONFIG_FILE="./tools/build/v2/user-config.jam.org"

  # Make a backup copy, or restore the backup if it already exists
  if test ! -f "$ORIGINAL_BJAM_USERCONFIG_FILE"; then
    cp "$BJAM_USERCONFIG_FILE" "$ORIGINAL_BJAM_USERCONFIG_FILE"
  else
    cp "$ORIGINAL_BJAM_USERCONFIG_FILE" "$BJAM_USERCONFIG_FILE"
  fi

  # - "using darwin" tells the build system that the tool "darwin" is available
  #   http://www.boost.org/boost-build2/doc/html/bbv2/overview/configuration.html
  #   http://www.boost.org/boost-build2/doc/html/bbv2/reference/tools.html
  # - "gcc~<prefix>" name of the compiler being used - apparently this can be
  #    any string; this will be used to form part of the build directory
  #    hierarchy
  # - The next field specifies the compiler executable to run; apparently it is
  #   possible to specify additional flags here
  # - The next field specifies compiler options, the syntax is
  #   <option-name>option-value
  # - The last field specifies conditions
  cat >> "$BJAM_USERCONFIG_FILE" <<EOF
using darwin : gcc~$IPHONEOS_PREFIX
   : $IPHONEOS_CC $IPHONEOS_ARCH_CPPFLAGS $COMMON_CPPFLAGS $BOOST_COMMON_CPPFLAGS $IPHONEOS_CPPFLAGS $BOOST_IPHONEOS_CPPFLAGS
   : <striper>
   : <architecture>arm <target-os>iphone
   ;
using darwin : gcc~$IPHONE_SIMULATOR_PREFIX
   : $IPHONE_SIMULATOR_CC $IPHONE_SIMULATOR_ARCH_CPPFLAGS $COMMON_CPPFLAGS $BOOST_COMMON_CPPFLAGS $IPHONESIMULATOR_CPPFLAGS $BOOST_IPHONE_SIMULATOR_CPPFLAGS
   : <striper>
   : <architecture>x86 <target-os>iphone
   ;
using darwin : gcc~$MACOSX_PREFIX
   : $MACOSX_CC $MACOSX_ARCH_CPPFLAGS $COMMON_CPPFLAGS $BOOST_COMMON_CPPFLAGS $MACOSX_CPPFLAGS $BOOST_MACOSX_CPPFLAGS
   : <striper>
   : <target-os>darwin
   ;
EOF

  return 0
}

# +------------------------------------------------------------------------
# | Run the bootstrap script in Boost's root directory to setup the build
# | for the desired libraries.
# |
# | Bootstrapping can be repeated without cleaning previous build results. Boost
# | will simply re-configure its build configuration in project-config.jam,
# | which will be picked up next time a build is started.
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
BOOTSTRAP_BOOST()
{
  echo "Bootstrapping Boost..."
  return 0

  typeset BOOTSTRAP_SCRIPT="bootstrap.sh"
  if test ! -f "$BOOTSTRAP_SCRIPT"; then
    echo "Boost bootstrap script $BOOTSTRAP_SCRIPT does not exist"
    return 1
  fi
  "./$BOOTSTRAP_SCRIPT" "--with-libraries=$BOOST_LIBS_COMMA"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}

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
  COPY_MISSING_HEADERS
  if test $? -ne 0; then
    return 1
  fi
  WRITE_BJAM_USERCONFIG
  if test $? -ne 0; then
    return 1
  fi
  BOOTSTRAP_BOOST
  if test $? -ne 0; then
    return 1
  fi

  return 0
}

# +------------------------------------------------------------------------
# | Backend function that is invoked once for performing the actual build,
# | and once for performing the install step.
# |
# | bjam selects a build configuration from user-config.jam based on the
# | arguments specified on the bjam command line. Since the build and install
# | phases occur in different invocations of bjam (once in BUILD_STEPS_SOFTWARE,
# | once in INSTALL_STEPS_SOFTWARE), both invocations need to specify the same
# | command line arguments. This function is here to ensure that this is the
# | case, i.e. that BUILD_STEPS_SOFTWARE and INSTALL_STEPS_SOFTWARE both use
# | the same bjam command line.
# +------------------------------------------------------------------------
# | Arguments:
# |  * 0|1 = Whether or not to clean the results of a previous build
# |  * bjam operation: keyword passed to bjam; must be one of "build" or
# |    "install"
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
RUN_BJAM()
{
  typeset CLEAN_BUILD="$1"
  typeset BJAM_OPERATION="$2"

  typeset CLEAN_BJAMFLAG
  if test "$CLEAN_BUILD" = "1"; then
    CLEAN_BJAMFLAG="--clean"
  fi

  case "$BJAM_OPERATION" in
    build)
      BJAM_OPERATION=""   # might also be "release" or "debug"
      BJAM_OPERATION_VERB="Building"
      ;;
    install)
      BJAM_OPERATION_VERB="Installing"
      ;;
    *)
      echo "Unknown bjam operation $BJAM_OPERATION"
      return 1
      ;;
  esac

  echo "$BJAM_OPERATION_VERB Boost for $IPHONEOS_PREFIX"
  ./bjam --prefix="$IPHONEOS_PREFIXDIR"         $CLEAN_BJAMFLAG $COMMON_BJAMFLAGS $BOOST_COMMON_BJAMFLAGS $IPHONEOS_BJAMFLAGS         $BOOST_IPHONEOS_BJAMFLAGS         $BJAM_OPERATION
  if test $? -ne 0; then
    return 1
  fi
  echo "$BJAM_OPERATION_VERB Boost for $IPHONE_SIMULATOR_PREFIX"
  ./bjam --prefix="$IPHONE_SIMULATOR_PREFIXDIR" $CLEAN_BJAMFLAG $COMMON_BJAMFLAGS $BOOST_COMMON_BJAMFLAGS $IPHONE_SIMULATOR_BJAMFLAGS $BOOST_IPHONE_SIMULATOR_BJAMFLAGS $BJAM_OPERATION
  if test $? -ne 0; then
    return 1
  fi
  echo "$BJAM_OPERATION_VERB Boost for $MACOSX_PREFIX"
  ./bjam --prefix="$MACOSX_PREFIXDIR"           $CLEAN_BJAMFLAG $COMMON_BJAMFLAGS $BOOST_COMMON_BJAMFLAGS $MACOSX_BJAMFLAGS           $BOOST_MACOSX_BJAMFLAGS           $BJAM_OPERATION
  if test $? -ne 0; then
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
# |  * 0|1 = Whether or not to clean the results of a previous build
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS_SOFTWARE()
{
  typeset CLEAN_BUILD="$1"
  RUN_BJAM "$CLEAN_BUILD" "build"
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
  typeset CLEAN_BUILD="0"   # never clean, we are installing
  RUN_BJAM "$CLEAN_BUILD" "install"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}
