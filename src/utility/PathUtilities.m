// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PathUtilities.h"


@implementation PathUtilities

// -----------------------------------------------------------------------------
/// @brief Creates a folder located at @a path.
///
/// If @a removeIfExists is true and the folder already exists, it is removed
/// (recursive) before the attempt to create it is made.
///
/// If @a removeIfExists is false and the folder already exists, this method
/// silently succeeds. This is consistent with the behaviour of the backend
/// method in NSFileManager.
///
/// Raises an @e NSException if the folder cannot be created. Also raises an
/// @e NSException if @a removeIfExists is true but the folder cannot be
/// removed.
// -----------------------------------------------------------------------------
+ (void) createFolder:(NSString*)path removeIfExists:(bool)removeIfExists
{
  if (removeIfExists)
    [PathUtilities deleteItemIfExists:path];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSError* error;
  BOOL success = [fileManager createDirectoryAtPath:path
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:&error];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to create folder %@, reason: %@", path, [error description]];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Recursively deletes the file or folder located at @a path, if it
/// exists. Does nothing if the file or folder does not exist.
///
/// Raises an @e NSException if the file or folder cannot be deleted.
// -----------------------------------------------------------------------------
+ (void) deleteItemIfExists:(NSString*)path
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:path])
    return;
  NSError* error;
  BOOL success = [fileManager removeItemAtPath:path error:&error];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to remove file or folder %@, reason: %@", path, [error description]];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Copies the source file or folder located at @a sourcePath to the new
/// location @a destinationPath, overwriting @a destinationPath if it exists.
///
/// Overwriting items with the NSFileManager API is rather cumbersome, so this
/// method conveniently takes care of checking whether @a destinationPath
/// exists and removing it, before the actual copy operation is invoked.
// -----------------------------------------------------------------------------
+ (BOOL) copyItemAtPath:(NSString*)sourcePath overwritePath:(NSString*)destinationPath error:(NSError**)error
{
  // Get rid of the destination file if it exists, otherwise copyItemAtPath:()
  // further down will abort the copy attempt.
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:destinationPath])
  {
    BOOL success = [fileManager removeItemAtPath:destinationPath error:error];
    if (! success)
    {
      DDLogError(@"Failed to remove item, reason: %@", [*error localizedDescription]);
      return success;
    }
  }
  BOOL success = [fileManager copyItemAtPath:sourcePath toPath:destinationPath error:error];
  if (! success)
    DDLogError(@"Failed to copy item, reason: %@", [*error localizedDescription]);
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Moves the source file or folder located at @a sourcePath to the new
/// location @a destinationPath, overwriting @a destinationPath if it exists.
///
/// Overwriting items with the NSFileManager API is rather cumbersome, so this
/// method conveniently takes care of checking whether @a destinationPath
/// exists and removing it, before the actual move operation is invoked.
// -----------------------------------------------------------------------------
+ (BOOL) moveItemAtPath:(NSString*)sourcePath overwritePath:(NSString*)destinationPath error:(NSError**)error
{
  // Get rid of the destination file if it exists, otherwise moveItemAtPath:()
  // further down will abort the move attempt.
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:destinationPath])
  {
    BOOL success = [fileManager removeItemAtPath:destinationPath error:error];
    if (! success)
    {
      DDLogError(@"Failed to remove item, reason: %@", [*error localizedDescription]);
      return success;
    }
  }
  BOOL success = [fileManager moveItemAtPath:sourcePath toPath:destinationPath error:error];
  if (! success)
    DDLogError(@"Failed to move item, reason: %@", [*error localizedDescription]);
  return success;
}

// -----------------------------------------------------------------------------
/// @brief Returns YES if the file or folder located at @a firstPath has a
/// modification timestamp that is newer than the file or folder located at
/// @a secondPath. Returns NO if it is the other way round, or if the two
/// timestamps are equal.
///
/// Raises an @e NSException if one or both files/folders do not exist, or if
/// the modification timestamp of one or both files/folders cannot be obtained
/// for any reason.
// -----------------------------------------------------------------------------
+ (BOOL) isItemAtPath:(NSString*)firstPath newerThanItemAtPath:(NSString*)secondPath
{
  NSDate* fileModificationDateOfFirstPath = [PathUtilities fileModificationDateOfItemAtPath:firstPath];
  NSDate* fileModificationDateOfSecondPath = [PathUtilities fileModificationDateOfItemAtPath:secondPath];

  NSTimeInterval timeInterval = [fileModificationDateOfFirstPath timeIntervalSinceDate:fileModificationDateOfSecondPath];
  if (timeInterval > 0)
    return YES;
  else
    return NO;
}

// -----------------------------------------------------------------------------
/// @brief Returns the modification timestamp of the file or folder located at
/// @a path.
///
/// Raises an @e NSException if the file or folder does not exist, or the
/// modification timestamp cannot be obtained for any reason.
// -----------------------------------------------------------------------------
+ (NSDate*) fileModificationDateOfItemAtPath:(NSString*)path
{
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSError* error;

  if (! [fileManager fileExistsAtPath:path])
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to obtain file modification date, path does not exist: %@", path];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSDictionary* attributes = [fileManager attributesOfItemAtPath:path error:&error];
  if (! attributes)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to obtain file modification date, failed to obtain file attributes of path %@, reason: %@", path, [error description]];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  NSDate* fileModificationDate = [attributes fileModificationDate];
  if (! fileModificationDate)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to obtain file modification date, failed to obtain timestamp of path: %@", path];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  return fileModificationDate;
}

// -----------------------------------------------------------------------------
/// @brief Creates the file located at @a path, overwriting it if it already
/// exists. The new file will have a modification timestamp that is equal to the
/// modification timestamp of the file or folder located at @a referencePath,
/// offset by @a timeInterval seconds.
///
/// The offset can be positive or negative to make the new file's modification
/// timestamp later or earlier than the reference timestamp. Specifying offset
/// 0 (zero) results in the two timestamps to be equal.
///
/// @attention When testing on the simulator, an offset of 0 (zero) resulted in
/// a timestamp that was @b NOT equal when the two timestamps were read from the
/// filesystem the next time. The difference was a fraction of a second
/// (e.g. 2.384185791015625E-7 seconds) which was likely caused by some floating
/// point error. Since at the moment it seems to be impossible to have fully
/// equal timestamps, the usefulness of this method is reduced.
///
/// Raises an @e NSException if the file or folder located at @a referencePath
/// does not exist, or the modification timestamp cannot be obtained for any
/// reason.
// -----------------------------------------------------------------------------
+ (void) createOrOverwriteFile:(NSString*)path withModificationDateOfItemAtPath:(NSString*)referencePath timeInterval:(NSTimeInterval)timeInterval
{
  NSDate* fileModificationDate = [PathUtilities fileModificationDateOfItemAtPath:referencePath];

  if (timeInterval != 0)
    fileModificationDate = [fileModificationDate dateByAddingTimeInterval:timeInterval];

  NSDictionary* attributes = @{ NSFileModificationDate: fileModificationDate };

  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager createFileAtPath:path
                                      contents:nil
                                    attributes:attributes];
  if (success == NO)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to touch file: %@", path];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the name of the application's preferences file.
///
/// The file name is based on the main bundle's identifier.
///
/// @attention This method should be used only in a controlled environment, and
/// only for debugging and/or testing purposes. It should not be used in a
/// production environment where storage of preferences is opaque to the
/// application.
// -----------------------------------------------------------------------------
+ (NSString*) preferencesFileName
{
  NSString* bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
  return [bundleIdentifier stringByAppendingPathExtension:@"plist"];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path of the application's preferences file.
///
/// The file name is based on the main bundle's identifier. The file location
/// is assumed to be in the standard location "Library/Preferences".
///
/// @attention This method should be used only in a controlled environment, and
/// only for debugging and/or testing purposes. It should not be used in a
/// production environment where storage of preferences is opaque to the
/// application.
// -----------------------------------------------------------------------------
+ (NSString*) preferencesFilePath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, expandTilde);
  NSString* libraryFolderPath = [paths objectAtIndex:0];
  NSString* preferencesFolderPath = [libraryFolderPath stringByAppendingPathComponent:@"Preferences"];
  return [preferencesFolderPath stringByAppendingPathComponent:[PathUtilities preferencesFileName]];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path to the folder that is used to store backup
/// files (i.e. files used to restore the application state from a previous
/// session).
// -----------------------------------------------------------------------------
+ (NSString*) backupFolderPath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  return [paths objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Prepends a pre-defined folder to @a fileName, then returns the
/// resulting full path.
///
/// If @a fileExists is not nil, this method also checks whether the file
/// exists and fills @a fileExists with the result.
// -----------------------------------------------------------------------------
+ (NSString*) filePathForBackupFileNamed:(NSString*)fileName fileExists:(BOOL*)fileExists
{
  NSString* backupFolderPath = [PathUtilities backupFolderPath];
  return [PathUtilities filePathForFileNamed:fileName
                                  folderPath:backupFolderPath
                                  fileExists:fileExists];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path to the folder that contains the application
/// archive, i.e. the folder where .sgf files are stored.
// -----------------------------------------------------------------------------
+ (NSString*) archiveFolderPath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  return [paths objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Returns the full path to the Inbox folder, i.e. the folder used by
/// the document interaction system to pass files into the app.
///
/// Starting with iOS 7, the system apparently protects the Inbox folder from
/// tampering (possibly in the same way as it protects the general app bundle
/// structure from being modified). For instance, it is not possible the Inbox
/// folder once it has been created.
// -----------------------------------------------------------------------------
+ (NSString*) inboxFolderPath
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, expandTilde);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  return [documentsDirectory stringByAppendingPathComponent:inboxFolderName];
}

// -----------------------------------------------------------------------------
/// @brief Prepends @a folderPath to @a fileName, then returns the resulting
/// full path.
///
/// If @a fileExists is not nil, this method also checks whether the file
/// exists and fills @a fileExists with the result.
// -----------------------------------------------------------------------------
+ (NSString*) filePathForFileNamed:(NSString*)fileName folderPath:(NSString*)folderPath fileExists:(BOOL*)fileExists
{
  NSString* filePath = [folderPath stringByAppendingPathComponent:fileName];
  if (fileExists)
  {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    *fileExists = [fileManager fileExistsAtPath:filePath];
    DDLogVerbose(@"Checking file existence for %@, file exists = %d", filePath, *fileExists);
  }
  return filePath;
}

@end
