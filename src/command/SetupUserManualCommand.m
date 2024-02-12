// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "SetupUserManualCommand.h"
#import "../help/UserManualUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../utility/PathUtilities.h"

// 3rdparty library includes
#import <ZipKit/ZKDefs.h>
#import <ZipKit/ZKFileArchive.h>


@implementation SetupUserManualCommand

@synthesize asynchronousCommandDelegate;
@synthesize showProgressHUD;


// -----------------------------------------------------------------------------
/// @brief Initializes a SetupUserManualCommand object.
///
/// @note This is the designated initializer of SetupUserManualCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.showProgressHUD = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  NSBundle* resourceBundle = applicationDelegate.resourceBundle;
  NSString* userManualArchiveResourcePath = [resourceBundle pathForResource:userManualResource
                                                                     ofType:nil];

  @try
  {
    bool isUserManualAlreadySetup = [self isUserManualAlreadySetup:userManualArchiveResourcePath];
    if (isUserManualAlreadySetup)
      return true;

    [self createBaseFolder];

    bool success = [self setupUserManual:userManualArchiveResourcePath];
    if (! success)
      return false;

    [self createSetupMarkerFile:userManualArchiveResourcePath];

    return true;
  }
  @catch (NSException* exception)
  {
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) isUserManualAlreadySetup:(NSString*)userManualArchiveResourcePath
{
  BOOL isUserManualAlreadySetup;
  NSString* userManualSetupMarkerFilePath = [UserManualUtilities filePathForUserManualFileNamed:userManualSetupMarkerFileName
                                                                                     fileExists:&isUserManualAlreadySetup];
  if (! isUserManualAlreadySetup)
    return false;

  BOOL isUserManualResourceNewerThanSetupUserManual = [PathUtilities isItemAtPath:userManualArchiveResourcePath
                                                              newerThanItemAtPath:userManualSetupMarkerFilePath];
  if (isUserManualResourceNewerThanSetupUserManual)
  {
    DDLogInfo(@"%@: User manual setup is outdated", [self shortDescription]);
    return false;
  }
  else
  {
    DDLogInfo(@"%@: User manual is already set up", [self shortDescription]);
    return true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) createBaseFolder
{
  NSString* userManualBaseFolderPath = [UserManualUtilities userManualBaseFolderPath];
  DDLogInfo(@"%@: Setting up user manual: %@", [self shortDescription], userManualBaseFolderPath);

  [PathUtilities createFolder:userManualBaseFolderPath removeIfExists:true];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (bool) setupUserManual:(NSString*)userManualArchiveResourcePath
{
  NSString* userManualArchiveTempPath = [UserManualUtilities filePathForUserManualFileNamed:userManualResource
                                                                                 fileExists:nil];
  NSError* error;
  BOOL success = [PathUtilities copyItemAtPath:userManualArchiveResourcePath
                                 overwritePath:userManualArchiveTempPath
                                         error:&error];
  if (! success)
  {
    DDLogError(@"%@: Failed to set up user manual, copying archive file failed: %@", [self shortDescription], [error localizedDescription]);
    return false;
  }

  ZKFileArchive* userManualArchive = [ZKFileArchive archiveWithArchivePath:userManualArchiveTempPath];
  NSInteger result = [userManualArchive inflateToDiskUsingResourceFork:NO];
  if (zkSucceeded != result)
  {
    DDLogError(@"%@: Failed to extract content of user manual archive file", [self shortDescription]);
    return false;
  }

  [PathUtilities deleteItemIfExists:userManualArchiveTempPath];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (void) createSetupMarkerFile:(NSString*)userManualArchiveResourcePath
{
  NSString* userManualSetupMarkerFilePath = [UserManualUtilities filePathForUserManualFileNamed:userManualSetupMarkerFileName
                                                                                     fileExists:nil];

  // Ideally we would specify a time interval of 0 seconds, i.e. the marker file
  // would then have the exact same timestamp as the archive file. When testing
  // on the simulator, though, it turned out that the marker file was touched
  // with a timestamp that was slightly off so that when the marker file's
  // timestamp was then checked the next time it would look as if the archive
  // file was newer. For this reason we add a few seconds, to guarantee that the
  // marker file's timestamp is later than the archive file.
  [PathUtilities createOrOverwriteFile:userManualSetupMarkerFilePath
withModificationDateOfItemAtPath:userManualArchiveResourcePath
              timeInterval:10];
}

@end
