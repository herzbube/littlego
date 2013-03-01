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
  BOOL success = [fileManager createDirectoryAtPath:path
                        withIntermediateDirectories:YES
                                         attributes:nil
                                              error:nil];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to create folder %@", path];
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
  BOOL success = [fileManager removeItemAtPath:path error:nil];
  if (! success)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Unable to remove file or folder %@", path];
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

@end
