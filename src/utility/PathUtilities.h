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


// -----------------------------------------------------------------------------
/// @brief The PathUtilities class is a container for various utility functions
/// related to handling of files and folders.
///
/// All functions in PathUtilities are class methods, so there is no need to
/// create an instance of PathUtilities.
// -----------------------------------------------------------------------------
@interface PathUtilities : NSObject
{
}

+ (void) createFolder:(NSString*)path removeIfExists:(bool)removeIfExists;
+ (void) deleteItemIfExists:(NSString*)path;
+ (BOOL) copyItemAtPath:(NSString*)sourcePath overwritePath:(NSString*)destinationPath error:(NSError**)error;
+ (BOOL) moveItemAtPath:(NSString*)sourcePath overwritePath:(NSString*)destinationPath error:(NSError**)error;
+ (BOOL) isItemAtPath:(NSString*)firstPath newerThanItemAtPath:(NSString*)secondPath;
+ (NSDate*) fileModificationDateOfItemAtPath:(NSString*)path;
+ (void) createOrOverwriteFile:(NSString*)path withModificationDateOfItemAtPath:(NSString*)referencePath timeInterval:(NSTimeInterval)timeInterval;
+ (NSString*) preferencesFileName;
+ (NSString*) preferencesFilePath;
+ (NSString*) backupFolderPath;
+ (NSString*) filePathForBackupFileNamed:(NSString*)fileName fileExists:(BOOL*)fileExists;
+ (NSString*) inboxFolderPath;
+ (NSString*) archiveFolderPath;
+ (NSString*) filePathForFileNamed:(NSString*)fileName folderPath:(NSString*)folderPath fileExists:(BOOL*)fileExists;

@end
