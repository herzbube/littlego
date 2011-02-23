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
# |   http://www.gitorious.com/BoostOnIphone
# | - "Building autoconf-configured libraries for iPhone OS", by
# |   Christopher Stawarz
# |   http://pseudogreen.org/blog/build_autoconfed_libs_for_iphone.html
# |
# | Interface and requirements for software-specific build script:
# | - Script must be located in the same directory as this main build script
# | - Script may refer to variables defined in the general build environment
# |   script build-env.sh (this main build script makes sure to source
# |   build-env.sh before it sources the software-specific build script)
# | - Script must define the following environment variables
# |   - ARCHIVE_URL: Full URL where a single archive file with the software's
# |     source code may be downloaded. Handled file types are: .tar.gz, .tgz
# |     .tar.bz2, .tbz, .zip. Script may use the environment variable
# |     ARCHIVE_BASEURL as a base.
# |   - ARCHIVE_FILE: Name that should be used to store the archive after it
# |     was downloaded. Only a simple file name, not a path.
# |   - ARCHIVE_CHECKSUM: SHA-512 checksum of the archive file.
# | - Script may define the following functions to execute software-specific
# |   commands during the respective build step. Unless specified otherwise,
# |   a function will be invoked without arguments and must return 0 for
# |   success, and 1 for failure.
# |   - PRE_BUILD_STEPS_SOFTWARE
# |   - BUILD_STEPS_SOFTWARE. Arguments are:
# |     * 0|1 = Whether or not to clean the results of a previous build
# |     * 0|1 = Whether or not the build should be quiet
# |   - POST_BUILD_STEPS_SOFTWARE
# |   - INSTALL_STEPS_SOFTWARE
# | - Script must not change working directory (unless it cd's back to the
# |   original directory before passing control back to caller)
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
 -d: Download only
 -b: Build only
 -c: Clean previous build
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
# | Fetch a single file from the given URL.
# +------------------------------------------------------------------------
# | Arguments:
# |  * URL to download
# |  * Name of the file to store (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
FETCH_FILE()
{
  typeset FILE_URL="$1"
  typeset FILE_PATH="$2"

  if test -z "$FILE_URL"; then
    echo "URL for download not specified"
    return 1
  fi
  if test -z "$FILE_PATH"; then
    echo "File name for download not specified"
    return 1
  fi
  case "$FILE_PATH" in
    /*) ;;
    *)
      echo "Specified file name for download $FILE_PATH must be an absolute path"
      return 1
      ;;
  esac

  echo "Downloading file $(basename $FILE_PATH)... "

  if test -f "$FILE_PATH"; then
    echo "Download skipped, file already exists"
    return 0
  fi

  type curl >/dev/null 2>&1
  if test $? -ne 0; then
    echo "Download failed, curl command not found"
    return 1
  fi

  curl --fail "${FILE_URL}" >"$FILE_PATH"
  if test $? -eq 0; then
    return 0
  else
    echo "Download failed"
    if test ! -s "$FILE_PATH"; then
      rm -f "$FILE_PATH"
    fi
    return 1
  fi
}

# +------------------------------------------------------------------------
# | Checks whether the checksum of the specified file is correct.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Name of the file to check (must be an absolute path)
# |  * Expected (correct) SHA-256 checksum
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error and checksum matches
# |  * 1: Error or checksum does not match
# +------------------------------------------------------------------------
CHECK_CHECKSUM()
{
  typeset FILE_PATH="$1"
  typeset CHECKSUM_EXPECTED="$2"

  if test -z "$FILE_PATH"; then
    echo "File name for checking checksum not specified"
    return 1
  fi
  case "$FILE_PATH" in
    /*) ;;
    *)
      echo "Specified file $FILE_PATH must be an absolute path"
      return 1
      ;;
  esac
  if test -z "$CHECKSUM_EXPECTED"; then
    echo "Expected checksum for checking checksum not specified"
    return 1
  fi

  echo "Checking checksum of $(basename $FILE_PATH)... "

  if test ! -f "$FILE_PATH"; then
    echo "Checking checksum failed, file not found"
    return 1
  fi

  type shasum >/dev/null 2>&1
  if test $? -ne 0; then
    echo "Checking checksum failed, shasum command not found"
    return 1
  fi

  CHECKSUM_REAL="$(shasum -a 256 "$FILE_PATH" 2>/dev/null | cut -d" " -f1)"
  if test $? -ne 0; then
    echo "Checking checksum failed, error while calculating checksum"
    return 1
  fi
  if test "$CHECKSUM_REAL" = "$CHECKSUM_EXPECTED"; then
    echo "Checksum ok"
  else
    echo "Checksum did not match"
    return 1
  fi

  return 0
}

# +------------------------------------------------------------------------
# | Downloads a file and checks whether its checksum is correct.
# +------------------------------------------------------------------------
# | Arguments:
# |  * URL to download
# |  * Name of the file to store and check (must be an absolute path)
# |  * Expected (correct) SHA-256 checksum
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error and checksum matches
# |  * 1: Error or checksum does not match
# +------------------------------------------------------------------------
DOWNLOAD_FILE()
{
  # Delegate argument checking to sub-functions
  typeset FILE_URL="$1"
  typeset FILE_PATH="$2"
  typeset CHECKSUM_EXPECTED="$3"

  FETCH_FILE "$FILE_URL" "$FILE_PATH"
  if test $? -ne 0; then
    return 1
  fi
  CHECK_CHECKSUM "$FILE_PATH" "$CHECKSUM_EXPECTED"
  if test $? -ne 0; then
    return 1
  fi

  return 0
}

# +------------------------------------------------------------------------
# | Extracts the content from the specified archive.
# |
# | This function has side effects:
# | - It changes the current working directory (sloppy programming)
# | - It sets the global environment variable SRC_DIR, to indicate the
# |   directory that the archive contents have been extracted to. SRC_DIR will
# |   be a sub-directory of the base directory specified as an argument to this
# |   function. SRC_DIR is specified as an absolute path.
# |
# | Note: It is expected that the archive expands into a single root directory.
# | This is customary for tarballs, but may be a problem with .zip files that
# | are sometimes not created with this convention.
# +------------------------------------------------------------------------
# | Arguments:
# |  * Name of the archive file to extract (must be an absolute path)
# |  * Base directory where the archive contents should be extracted (must be
# |    an absolute path); the content will be extracted to a sub-directory of
# |    this
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
EXTRACT_ARCHIVE_CONTENT()
{
  typeset ARCHIVE_FILE_PATH="$1"
  typeset SRC_BASEDIR="$2"
  typeset ARCHIVE_FILE_NAME="$(basename $ARCHIVE_FILE_PATH)"

  echo "Extracting content of archive $ARCHIVE_FILE_NAME..."

  case "$ARCHIVE_FILE_PATH" in
    /*) ;;
    *)
      echo "Archive must be an absolute path"
      return 1
      ;;
  esac
  if test ! -f "$ARCHIVE_FILE_PATH"; then
    echo "Cannot extract archive, file not found"
    return 1
  fi

  # Determine the tool with which to extract the archive content
  typeset EXTRACT_TOOL
  typeset EXTRACT_TOOL_ARGUMENTS
  case "$ARCHIVE_FILE_NAME" in
    *.tar.gz|*.tgz)
      EXTRACT_TOOL=tar
      EXTRACT_TOOL_ARGUMENTS="xfz"
      ;;
    *.tar.bz2|*.tbz)
      EXTRACT_TOOL=tar
      EXTRACT_TOOL_ARGUMENTS="xfj"
      ;;
    *.zip)
      EXTRACT_TOOL=unzip
      EXTRACT_TOOL_ARGUMENTS=""
      ;;
    *)
      echo "Cannot extract archive, unknown archive file type"
      return 1
      ;;
  esac

  # Because SRC_DIR will be an absolute path, we also require SRC_BASEDIR to
  # be an absolute path.
  case "$SRC_BASEDIR" in
    /*) ;;
    *)
      echo "Base directory $SRC_BASEDIR for archive extraction must be an absolute path"
      return 1
      ;;
  esac

  # Check if a directory exists with the same name as the archive file name,
  # minus file suffix. If so, we boldly assume that the archive has already
  # been extracted before, and use the directory we just found as the source
  # directory
  typeset ARCHIVE_FILE_BASENAME="$(echo "$ARCHIVE_FILE_NAME" | sed -Ee 's/(.tar.gz|.tgz|.tar.bz2|.tbz|.zip)//')"
  if test -d "$SRC_BASEDIR/$ARCHIVE_FILE_BASENAME"; then
    SRC_DIR="$SRC_BASEDIR/$ARCHIVE_FILE_BASENAME"
    echo "It appears that the archive content was previously extracted; using this content instead of extracting again"
    return 0
  fi

  # Create temporary directory where archive content is extracted
  typeset EXTRACT_DIR="$SRC_BASEDIR/$ARCHIVE_FILE_NAME.$$"
  if test -d "$EXTRACT_DIR"; then
    echo "Temporary directory $EXTRACT_DIR for archive extraction already exists"
    return 1
  fi
  mkdir -p "$EXTRACT_DIR"
  if test $? -ne 0; then
    echo "Could not create temporary directory $EXTRACT_DIR for archive extraction"
    return 1
  fi

  # Extract archive content
  cd "$EXTRACT_DIR" >/dev/null 2>&1
  $EXTRACT_TOOL $EXTRACT_TOOL_ARGUMENTS "$ARCHIVE_FILE_PATH"
  if test $? -ne 0; then
    echo "Extracting archive failed; partial results may exist in $EXTRACT_DIR"
    return 1
  fi

  # Verify that the archive expands into a single root directory
  typeset NR_OF_RESULTS="$(ls -1 | grep -Fv '^.$' | grep -Fv '^..$' | wc -l)"
  if test "$NR_OF_RESULTS" -eq 0; then
    echo "Cannot find content extracted from archive, should be in $EXTRACT_DIR"
    return 1
  elif test "$NR_OF_RESULTS" -gt 1; then
    echo "Cannot handle content of archive, expands into more than a single directory; content was extracted to $EXTRACT_DIR"
    return 1
  fi
  typeset RESULT_DIRNAME="$(ls -1 | grep -Fv '^.$' | grep -Fv '^..$')"
  if test ! -d "$RESULT_DIRNAME"; then
    echo "Cannot handle content of archive, expands into something that is not a directory; content was extracted to $EXTRACT_DIR"
    return 1
  fi

  # Move extracted content to final destination, then cleanup
  SRC_DIR="$SRC_BASEDIR/$RESULT_DIRNAME"   # NO typeset! THIS VAR MUST BE GLOBAL
  if test ! -d "$SRC_DIR"; then
    mv "$RESULT_DIRNAME" "$SRC_DIR"
    if test $? -ne 0; then
      echo "Cannot move content of archive to $SRC_DIR; content was extracted to $EXTRACT_DIR"
      return 1
    fi
  else
    # No error if final location of archive content already exists.
    #
    # The reasoning here is that we assume that the archive expands into a root
    # directory that includes the software version number (e.g. foobar-0.7.9),
    # which means that we can be reasonably sure that the content of the
    # already existing SRC_DIR matches the content of the archive that we just
    # extracted.
    #
    # As a consequence, the subsequent build will take place in a directory that
    # may already contain stuff from a previous build. If this is actually the
    # case, we expect the user to request a clean step before the actual build.
    #
    # Note that the hint we give to the user is slightly misleading - in fact
    # we *DID* extract again, but we are simply throwing away the results of
    # that. Does the user really need to know the difference?
    echo "It appears that the archive content was previously extracted; using this content instead of extracting again"
  fi
  rm -rf "$EXTRACT_DIR"
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
      $SOFTWARE_FUNCTION_NAME 2>&1 | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$?
      # TODO exit code is always 0 here!!!
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
# |  * 0|1 = Whether or not to clean the results of a previous build
# |  * 0|1 = Whether or not the build should be quiet
# |  * Build log file (must be an absolute path)
# +------------------------------------------------------------------------
# | Return values:
# |  * 0: No error
# |  * 1: Error
# +------------------------------------------------------------------------
BUILD_STEPS()
{
  typeset CLEAN_BUILD="$1"
  typeset QUIET_BUILD="$2"
  typeset BUILDLOG_PATH="$3"

  SOFTWARE_FUNCTION_NAME="BUILD_STEPS_SOFTWARE"
  FUNCTION_EXISTS "$SOFTWARE_FUNCTION_NAME"
  if test $? -eq 0; then
    echo "Building the software..."
    typeset EXIT_CODE
    if test "$QUIET_BUILD" = "1"; then
      $SOFTWARE_FUNCTION_NAME "$CLEAN_BUILD" >>"$BUILDLOG_PATH" 2>&1
      EXIT_CODE=$?
    else
      $SOFTWARE_FUNCTION_NAME "$CLEAN_BUILD" 2>&1 | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$?
      # TODO exit code is always 0 here!!!
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
      $SOFTWARE_FUNCTION_NAME 2>&1 | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$?
      # TODO exit code is always 0 here!!!
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
      $SOFTWARE_FUNCTION_NAME 2>&1 | tee -a "$BUILDLOG_PATH"
      EXIT_CODE=$?
      # TODO exit code is always 0 here!!!
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
SCRIPT_DIR="$(pwd)/$(dirname $0)"
USAGE_LINE="$SCRIPT_NAME [-h] [-d|-b] [-cq] <software>"

# Remaining variables and resources
BUILD_BASEDIR="$SCRIPT_DIR/../3rdparty"
ARCHIVE_BASEURL="http://www.herzbube.ch/software/3rdparty"
BUILDENV_SCRIPT="$SCRIPT_DIR/build-env.sh"
OPTSOK=hdbcq
unset DOWNLOAD_ONLY BUILD_ONLY CLEAN_BUILD QUIET_BUILD

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
    d)
      DOWNLOAD_ONLY=1
      ;;
    b)
      BUILD_ONLY=1
      ;;
    c)
      CLEAN_BUILD=1
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

if test -z "$CLEAN_BUILD"; then
  CLEAN_BUILD=0
fi

if test -z "$QUIET_BUILD"; then
  QUIET_BUILD=0
fi

if test -n "$DOWNLOAD_ONLY" -a -n "$BUILD_ONLY"; then
  echo "-d and -b cannot be used at the same time"
  echo "$USAGE_LINE"
  exit 1
fi

if test -n "$DOWNLOAD_ONLY" -a "$CLEAN_BUILD" -eq 1; then
  echo "-d and -c cannot be used at the same time"
  echo "$USAGE_LINE"
  exit 1
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
for DIR_TO_CREATE in "$DOWNLOAD_DIR" "$SRC_BASEDIR" "$PREFIX_BASEDIR"; do
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

# Download the source archive and check whether the file's checksum is correct
if test -z "$BUILD_ONLY"; then
  DOWNLOAD_FILE "$ARCHIVE_URL" "$DOWNLOAD_DIR/$ARCHIVE_FILE" "$ARCHIVE_CHECKSUM"
  if test $? -ne 0; then
    exit 1
  fi
fi

if test -z "$DOWNLOAD_ONLY"; then
  # Extract sources
  # (the function sets SRC_DIR as a side effect)
  EXTRACT_ARCHIVE_CONTENT "$DOWNLOAD_DIR/$ARCHIVE_FILE" "$SRC_BASEDIR"
  if test $? -ne 0; then
    exit 1
  fi

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
    echo "Build failed."
    exit 1
  fi
  BUILD_STEPS "$CLEAN_BUILD" "$QUIET_BUILD" "$BUILDLOG_PATH"
  if test $? -ne 0; then
    echo "Build failed."
    exit 1
  fi
  POST_BUILD_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
  if test $? -ne 0; then
    echo "Build failed."
    exit 1
  fi
  INSTALL_STEPS "$QUIET_BUILD" "$BUILDLOG_PATH"
  if test $? -ne 0; then
    echo "Build failed."
    exit 1
  fi
fi

exit 0
