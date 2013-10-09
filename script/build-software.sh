#!/usr/bin/env bash

# =========================================================================
# | Builds a 3rdparty software package from source. The process consists of the
# | following steps:
# | - Retrieve an archive with source code from the Internet
# | - Extract the archive
# | - Execute pre-build steps
# | - Run the actual build
# | - Execute post-build steps
# | - Install the built software
# |
# | Invoke this script with -h to get the usage.
# |
# | Inspiration for this script, including the way how to specify build
# | settings for a build system that is not based on Xcode, was borrowed from
# | various sources on the web, notably
# | - BoostOniPhone, by Pete Goodliffe
# |   https://gitorious.org/boostoniphone
# | - "Building autoconf-configured libraries for iPhone OS", by
# |   Christopher Stawarz
# |   http://pseudogreen.org/blog/build_autoconfed_libs_for_iphone.html
# |
# | This script provides the framework for the build process, but delegates most
# | of the actual work to a software-specific build script (for those familiar
# | with design patterns: something like the template method pattern). The
# | interface and the requirements for a software-specific build script are:
# | - The script must be located in the same directory as this main build script
# | - The script may refer to variables defined in the general build environment
# |   script build-env.sh (this main build script makes sure to source
# |   build-env.sh before it sources the software-specific build script)
# | - The script must define the following environment variables
# |   - ARCHIVE_URL: Full URL where a single archive file with the software's
# |     source code may be downloaded. Handled file types are: .tar.gz, .tgz
# |     .tar.bz2, .tbz, .zip. Script may use the environment variable
# |     ARCHIVE_BASEURL as a base.
# |   - ARCHIVE_FILE: Name that should be used to store the archive after it
# |     was downloaded. Only a simple file name, not a path.
# |   - ARCHIVE_CHECKSUM: SHA-256 checksum of the archive file.
# | - The script may define the following functions to execute software-specific
# |   commands during the respective build step. If a function is not present,
# |   it is not invoked. Unless specified otherwise, a function will be invoked
# |   without arguments and must return 0 for success, and 1 for failure.
# |   - PRE_BUILD_STEPS_SOFTWARE
# |   - BUILD_STEPS_SOFTWARE
# |   - POST_BUILD_STEPS_SOFTWARE
# |   - INSTALL_STEPS_SOFTWARE
# | - The script must not change the working directory (unless it cd's back to
# |   the original directory before passing control back to the caller)
# | - The script must build the software for only those platforms that have
# |   been enabled in build-env.sh. The variables to look out for are named
# |   <platform>_BUILD_ENABLED (e.g. IPHONEOS_BUILD_ENABLED).
# |
# | TODO
# | - Allow to run this script for several software packages
# | - Improve handling for archives that do not expand cleanly into a single
# |   root directory
# | - Allow the base directory for the operation of this script to be
# |   customized (currently this is hardcoded in BUILD_BASEDIR)
# | - Support in 3rdparty directory for multiple versions of the same software
# =========================================================================

# /////////////////////////////////////////////////////////////////////////
# // Functions
# /////////////////////////////////////////////////////////////////////////

# +------------------------------------------------------------------------
# | Prints a (more or less) short help text explaining the usage of the
# | program.
# +------------------------------------------------------------------------
# | Arguments:
# |  None
# +------------------------------------------------------------------------
# | Return values:
# |  None
# +------------------------------------------------------------------------
PRINT_USAGE()
{
  cat << EOF
$USAGE_LINE
 -h: Print this usage text
 -q: Quiet build
 <software>: Name of the 3rdparty software to build

Exit codes:
 0: No error
 1: Error

$SCRIPT_NAME in itself is not complete, it includes other script parts at
runtime (using shell script sourcing). These script parts must be located in
the same directory as $SCRIPT_NAME:
- $(basename $BUILDENV_SCRIPT): This determines the build environment to use, notably the
  base SDK, the deployment target and the compiler version. If you need to
  change these things, you must edit $(basename $BUILDENV_SCRIPT). There is no way (yet) to
  specify these things on the command line.
- build-<software>.sh: A script with stuff that is specific to the software
  package for which you request a build. The name of the actual script is
  determined at runtime. If you need to change things such as the version of
  the software package that is being built, you must edit build-<software>.sh.
EOF
}

# +------------------------------------------------------------------------
# | Checks whether the specified shell function exists.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Function name
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: Function exists
# |  * 1: Function does not exist (or an error occurred)
# +------------------------------------------------------------------------
FUNCTION_EXISTS()
{
  typeset FUNCTION_NAME="$1"

  if test -z "$FUNCTION_NAME"; then
    echo "Specified empty function name"
    return 1
  fi

  typeset TYPE_RESULT="$(type "$FUNCTION_NAME" 2>/dev/null)"
  if test $? -ne 0; then
    # Does not exist, so it can't be a function :-)
    return 1
  fi
  echo "$TYPE_RESULT" | grep -qi "function"
  if test $? -eq 0; then
    # Exists and seems to be a function...
    return 0
  else
    return 1
  fi
}

# +------------------------------------------------------------------------
# | Performs pre-build steps.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  * 0|1 = Whether or not the build should be quiet
# |  * Build log file (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
PRE_BUILD_STEPS()
{
  typeset QUIET_BUILD="$1"
  typeset BUILDLOG_PATH="$2"

  SOFTWARE_FUNCTION_NAME="PRE_BUILD_STEPS_SOFTWARE"
  FUNCTION_EXISTS "$SOFTWARE_FUNCTION_NAME"
  if test $? -eq 0; then
    echo "Executing pre-build steps..."
    typeset EXIT_CODE
    if test "$QUIET_BUILD" = "1"; then
      $SOFTWARE_FUNCTION_NAME >>"$BUILDLOG_PATH" 2>&1
      EXIT_CODE=$?
    else
      ($SOFTWARE_FUNCTION_NAME 2>&1; echo $? >"$EXITCODE_FILE") | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$(cat "$EXITCODE_FILE")
      rm -f "$EXITCODE_FILE"
    fi
    if test $EXIT_CODE -ne 0; then
      return 1
    fi
  else
    echo "No pre-build steps to execute..."
  fi

  return 0
}

# +------------------------------------------------------------------------
# | Builds and installs the software package.
# |
# | This function expects that the current working directory is the root
# | directory of the extracted source archive.
# +------------------------------------------------------------------------
# | Arguments:
# |  * 0|1 = Whether or not the build should be quiet
# |  * Build log file (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS()
{
  typeset QUIET_BUILD="$1"
  typeset BUILDLOG_PATH="$2"

  SOFTWARE_FUNCTION_NAME="BUILD_STEPS_SOFTWARE"
  FUNCTION_EXISTS "$SOFTWARE_FUNCTION_NAME"
  if test $? -eq 0; then
    echo "Building the software..."
    typeset EXIT_CODE
    if test "$QUIET_BUILD" = "1"; then
      $SOFTWARE_FUNCTION_NAME >>"$BUILDLOG_PATH" 2>&1
      EXIT_CODE=$?
    else
      ($SOFTWARE_FUNCTION_NAME 2>&1; echo $? >"$EXITCODE_FILE") | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$(cat "$EXITCODE_FILE")
      rm -f "$EXITCODE_FILE"
    fi
    if test $EXIT_CODE -ne 0; then
      return 1
    fi
  else
    echo "No build steps to execute..."
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
# |  * 0|1 = Whether or not the build should be quiet
# |  * Build log file (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
POST_BUILD_STEPS()
{
  typeset QUIET_BUILD="$1"
  typeset BUILDLOG_PATH="$2"

  SOFTWARE_FUNCTION_NAME="POST_BUILD_STEPS_SOFTWARE"
  FUNCTION_EXISTS "$SOFTWARE_FUNCTION_NAME"
  if test $? -eq 0; then
    echo "Executing post-build steps..."
    typeset EXIT_CODE
    if test "$QUIET_BUILD" = "1"; then
      $SOFTWARE_FUNCTION_NAME >>"$BUILDLOG_PATH" 2>&1
      EXIT_CODE=$?
    else
      ($SOFTWARE_FUNCTION_NAME 2>&1; echo $? >"$EXITCODE_FILE") | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$(cat "$EXITCODE_FILE")
      rm -f "$EXITCODE_FILE"
    fi
    if test $EXIT_CODE -ne 0; then
      return 1
    fi
  else
    echo "No post-build steps to execute..."
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
# |  * 0|1 = Whether or not the build should be quiet
# |  * Build log file (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
INSTALL_STEPS()
{
  typeset QUIET_BUILD="$1"
  typeset BUILDLOG_PATH="$2"

  SOFTWARE_FUNCTION_NAME="INSTALL_STEPS_SOFTWARE"
  FUNCTION_EXISTS "$SOFTWARE_FUNCTION_NAME"
  if test $? -eq 0; then
    echo "Installing the software..."
    typeset EXIT_CODE
    if test "$QUIET_BUILD" = "1"; then
      $SOFTWARE_FUNCTION_NAME >>"$BUILDLOG_PATH" 2>&1
      EXIT_CODE=$?
    else
      ($SOFTWARE_FUNCTION_NAME 2>&1; echo $? >"$EXITCODE_FILE") | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$(cat "$EXITCODE_FILE")
      rm -f "$EXITCODE_FILE"
    fi
    if test $EXIT_CODE -ne 0; then
      return 1
    fi
  else
    echo "No install steps to execute..."
  fi

  return 0
}

# /////////////////////////////////////////////////////////////////////////
# // Main program
# /////////////////////////////////////////////////////////////////////////

# +------------------------------------------------------------------------
# | Variable declaration and initialisation
# +------------------------------------------------------------------------

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(dirname $0)"
case "$SCRIPT_DIR" in
  /*) ;;
  *)  SCRIPT_DIR="$(pwd)/$SCRIPT_DIR" ;;
esac
USAGE_LINE="$SCRIPT_NAME [-h] [-q] <software>"

# Remaining variables and resources
BUILD_BASEDIR="$SCRIPT_DIR/../3rdparty"
BUILDENV_SCRIPT="$SCRIPT_DIR/build-env.sh"
PATCH_BASEDIR="$SCRIPT_DIR/../patch"
EXITCODE_FILE="/tmp/$SCRIPT_NAME.exitcode.$$"
OPTSOK=hq
unset QUIET_BUILD

# +------------------------------------------------------------------------
# | Argument processing
# +------------------------------------------------------------------------

while getopts $OPTSOK OPTION
do
  case $OPTION in
    h)
      PRINT_USAGE
      exit 0
      ;;
    q)
      QUIET_BUILD=1
      ;;
    \?)
      echo "$USAGE_LINE"
      exit 1
      ;;
  esac
done
shift $(expr $OPTIND - 1)
SOFTWARE_NAME="$*"

if test $# -eq 0; then
  echo "Software name not specified"
  echo "$USAGE_LINE"
  exit 1
fi
if test $# -ne 1; then
  echo "Too many arguments"
  echo "$USAGE_LINE"
  exit 1
fi
BUILDSOFTWARE_SCRIPT="$SCRIPT_DIR/build-${SOFTWARE_NAME}.sh"
if test ! -f "$BUILDSOFTWARE_SCRIPT"; then
  echo "Build script $BUILDSOFTWARE_SCRIPT not found"
  exit 1
fi

if test -z "$QUIET_BUILD"; then
  QUIET_BUILD=0
fi

# +------------------------------------------------------------------------
# | Main program processing
# +------------------------------------------------------------------------

# Define build environment
if test ! -f "$BUILDENV_SCRIPT"; then
  echo "Unable to define build environment (missing script $BUILDENV_SCRIPT)"
  exit 1
fi
. "$BUILDENV_SCRIPT"
. "$BUILDSOFTWARE_SCRIPT"

# Create directories defined by BUILDENV_SCRIPT
for DIR_TO_CREATE in "$PREFIX_BASEDIR"; do
  if test -z "$DIR_TO_CREATE"; then
    echo "$BUILDENV_SCRIPT did not specify one of several essential directories"
    exit 1
  fi
  if test ! -d "$DIR_TO_CREATE"; then
    mkdir -p "$DIR_TO_CREATE"
    if test $? -ne 0; then
      echo "Error creating directory $DIR_TO_CREATE"
      exit 1
    fi
  fi
done

# Validate SRC_DIR and change directory to it so that subsequent steps don't
# have to care about this.
case "$SRC_DIR" in
  /*) ;;
  *)
    echo "Source file directory $SRC_DIR must be an absolute path"
    exit 1
    ;;
esac
if test ! -d "$SRC_DIR"; then
  echo "Source file directory $SRC_DIR does not exist"
  exit 1
fi
cd "$SRC_DIR" >/dev/null 2>&1
if test $? -ne 0; then
  echo "Cannot change directory to source file directory $SRC_DIR"
  exit 1
fi
BUILDLOG_PATH="$SRC_DIR/build.log"
rm -f "$BUILDLOG_PATH"

# Perform build and installation in multiple, well-defined steps
PRE_BUILD_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
if test $? -ne 0; then
  echo "Pre-build steps failed."
  exit 1
fi
BUILD_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
if test $? -ne 0; then
  echo "Build failed."
  exit 1
fi
POST_BUILD_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
if test $? -ne 0; then
  echo "Post-build steps failed."
  exit 1
fi
INSTALL_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
if test $? -ne 0; then
  echo "Install steps failed."
  exit 1
fi

exit 0
