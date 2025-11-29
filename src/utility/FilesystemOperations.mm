// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "FilesystemOperations.h"

// System includes
#include <filesystem>


@implementation FilesystemOperations

// -----------------------------------------------------------------------------
/// @brief Copies the content of an existing file or folder at @a sourcePath to
/// the new location @a destinationPath, overwriting @a destinationPath if it
/// exists. The behaviour resembles that of the @e cp command line utility.
/// Returns true if the operation is successful. Returns false if the operation
/// fails.
///
/// If @a errorCode is not @e nil, sets the value of @a errorCode to 0 (zero)
/// if the filesystem operation is successful. If the filesystem operation
/// fails, sets the value of @a errorCode to an OS-specific non-zero error code.
///
/// Returns false if @a sourcePath and/or @a destinationPath is @e nil, but
/// sets @a errorCode to 0 because no filesystem operation was attempted.
///
/// @attention This method has only been tested for @a sourcePath being a file,
/// and when no symbolic links were involved. If @a sourcePath is a folder, or
/// symbolic links are involved, the filesystem operation may or may not work
/// as expected.
///
/// If @a destinationPath does not exist, FilesystemMonitor delegates will
/// receive the following notifications in this order:
/// - #FilesystemMonitorChangeTypeDataChanged for the folder that contains
///   @a destinationPath.
/// - No notifications for @a destinationPath.
///
/// If @a destinationPath exists it will be overwritten. FilesystemMonitor
/// delegates will receive the following notifications in this order:
/// - #FilesystemMonitorChangeTypeDataChanged for the folder that contains
///   @a destinationPath.
/// - #FilesystemMonitorChangeTypeMetadataChanged at least once for
///   @a destinationPath (probably more than once).
/// - #FilesystemMonitorChangeTypeSizeChanged for @a destinationPath (even if
///   the file size of @a sourcePath and @a destinationPath are the same).
/// - #FilesystemMonitorChangeTypeDataChanged for @a destinationPath (even if
///   the content of @a sourcePath and @a destinationPath are the same).
// -----------------------------------------------------------------------------
+ (bool) copyItemAtPath:(NSString*)sourcePath
          overwritePath:(NSString*)destinationPath
              errorCode:(int*)errorCode
{
  if (errorCode)
    *errorCode = 0;

  if (! sourcePath || ! destinationPath)
    return false;

  const char* pchSourcePath = [sourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::filesystem::path fsSourcePath(pchSourcePath);
  const char* pchDestinationPath = [destinationPath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::filesystem::path fsDestinationPath(pchDestinationPath);
  std::filesystem::copy_options options = (std::filesystem::copy_options::recursive |
                                           std::filesystem::copy_options::overwrite_existing);
  std::error_code fsErrorCode;

  std::filesystem::copy(fsSourcePath, fsDestinationPath, options, fsErrorCode);

  if (errorCode)
    *errorCode = fsErrorCode.value();

  if (fsErrorCode)
  {
    DDLogError(@"copyItemAtPath:overwritePath:() failed with OS-specific error code %d", fsErrorCode.value());
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Moves (renames) an existing file or folder at @a sourcePath to
/// the new location @a destinationPath, overwriting @a destinationPath if it
/// exists. The behaviour resembles that of the @e mv command line utility.
/// Returns true if the operation is successful. Returns false if the operation
/// fails.
///
/// If @a errorCode is not @e nil, sets the value of @a errorCode to 0 (zero)
/// if the filesystem operation is successful. If the filesystem operation
/// fails, sets the value of @a errorCode to an OS-specific non-zero error code.
///
/// Returns false if @a sourcePath and/or @a destinationPath is @e nil, but
/// sets @a errorCode to 0 because no filesystem operation was attempted.
///
/// @attention This method has only been tested for @a sourcePath being a file,
/// and when no symbolic links were involved. If @a sourcePath is a folder, or
/// symbolic links are involved, the filesystem operation may or may not work
/// as expected.
///
/// If @a destinationPath does not exist, FilesystemMonitor delegates will
/// receive the following notifications in this order:
/// - #FilesystemMonitorChangeTypeDataChanged for the folder that contains
///   @a destinationPath.
/// - #FilesystemMonitorChangeTypeRenamed for @a sourcePath.
/// - No notifications for @a destinationPath.
///
/// If @a destinationPath exists it will be overwritten. FilesystemMonitor
/// delegates will receive the following notifications in this order:
/// - #FilesystemMonitorChangeTypeDataChanged for the folder that contains
///   @a destinationPath.
/// - #FilesystemMonitorChangeTypeDeleted for @a destinationPath.
/// - #FilesystemMonitorChangeTypeRenamed for @a sourcePath.
// -----------------------------------------------------------------------------
+ (bool) moveItemAtPath:(NSString*)sourcePath
          overwritePath:(NSString*)destinationPath
              errorCode:(int*)errorCode
{
  if (errorCode)
    *errorCode = 0;

  if (! sourcePath || ! destinationPath)
    return false;

  const char* pchSourcePath = [sourcePath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::filesystem::path fsSourcePath(pchSourcePath);
  const char* pchDestinationPath = [destinationPath cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::filesystem::path fsDestinationPath(pchDestinationPath);
  std::error_code fsErrorCode;

  std::filesystem::rename(fsSourcePath, fsDestinationPath, fsErrorCode);

  if (errorCode)
    *errorCode = fsErrorCode.value();

  if (fsErrorCode)
  {
    DDLogError(@"moveItemAtPath:overwritePath:() failed with OS-specific error code %d", fsErrorCode.value());
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Recursively deletes the file or folder located at @a path, if it
/// exists. Does nothing if the file or folder does not exist. The behaviour
/// resembles that of the @e rm command line utility. Returns true if the
/// operation is successful. Returns false if the operation fails.
///
/// If @a errorCode is not @e nil, sets the value of @a errorCode to 0 (zero)
/// if the filesystem operation is successful. If the filesystem operation
/// fails, sets the value of @a errorCode to an OS-specific non-zero error code.
///
/// If @a numberOfItemsDeleted is not @e nil, sets the value of
/// @a numberOfItemsDeleted to the number of files that were deleted. If the
/// filesystem operation fails, sets the value of @a @a numberOfItemsDeleted
/// to @e static_cast<unsigned long>(-1).
///
/// Returns false if @a path is @e nil, but sets @a numberOfItemsDeleted and
/// @a errorCode to 0 (zero) because no filesystem operation was attempted.
///
/// Returns false if the existence check for @a path fails, sets @a errorCode
/// to an OS-specific non-zero error code, but sets @a numberOfItemsDeleted to
/// 0 (zero) because no filesystem operation was attempted.
///
/// @attention This method has only been tested for @a path being a file,
/// and when no symbolic links were involved. If @a path is a folder, or
/// symbolic links are involved, the filesystem operation may or may not work
/// as expected.
///
/// FilesystemMonitor delegates will receive the following notifications in
/// this order:
/// - #FilesystemMonitorChangeTypeDeleted for @a path.
/// - #FilesystemMonitorChangeTypeObjectLinkCountChanged for @a path.
/// - #FilesystemMonitorChangeTypeDataChanged for the folder that contains
///   @a path.
// -----------------------------------------------------------------------------
+ (bool) deleteItemIfExists:(NSString*)path
       numberOfItemsDeleted:(unsigned long*)numberOfItemsDeleted
                  errorCode:(int*)errorCode
{
  if (numberOfItemsDeleted)
    *numberOfItemsDeleted = 0;
  if (errorCode)
    *errorCode = 0;

  if (! path)
  {
    DDLogError(@"deleteItemIfExists:() failed because supplied path is nil");
    return false;
  }

  const char* pchPath = [path cStringUsingEncoding:[NSString defaultCStringEncoding]];
  std::filesystem::path fsPath(pchPath);
  std::error_code fsErrorCode;

  bool itemExists = std::filesystem::exists(fsPath, fsErrorCode);

  if (fsErrorCode)
  {
    if (errorCode)
      *errorCode = fsErrorCode.value();

    DDLogError(@"deleteItemIfExists:() failed to determine file status with OS-specific error code %d", fsErrorCode.value());
    return false;
  }
  else if (! itemExists)
  {
    return true;
  }

  std::uintmax_t fsNumberOfItemsDeleted = std::filesystem::remove_all(fsPath, fsErrorCode);

  if (numberOfItemsDeleted)
    *numberOfItemsDeleted = fsNumberOfItemsDeleted;
  if (errorCode)
    *errorCode = fsErrorCode.value();

  if (fsErrorCode)
  {
    DDLogError(@"deleteItemIfExists:() failed with OS-specific error code %d", fsErrorCode.value());
    return false;
  }

  // Not tested, but it is conceivable that this is returned even though
  // errorCode did not indicate an error, for instance if the standard library
  // finds a problem while validating the parameter
  if (fsNumberOfItemsDeleted == static_cast<std::uintmax_t>(-1))
  {
    DDLogError(@"deleteItemIfExists:() returned number of deleted items indicating error");
    return false;
  }

  return true;
}

@end
