// -----------------------------------------------------------------------------
// Copyright 2019-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "UnarchiveGameCommand.h"
#import "../../utility/PathUtilities.h"
#import "../../go/GoGame.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for UnarchiveGameCommand.
// -----------------------------------------------------------------------------
@interface UnarchiveGameCommand()
@property(nonatomic, retain) GoGame* game;
@end


@implementation UnarchiveGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes an UnarchiveGameCommand object.
///
/// @note This is the designated initializer of UnarchiveGameCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.shouldRemoveArchiveFileIfUnarchivingFails = true;
  self.game = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UnarchiveGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  BOOL fileExists;
  NSString* archiveFilePath = [PathUtilities filePathForBackupFileNamed:archiveBackupFileName
                                                             fileExists:&fileExists];
  if (! fileExists)
  {
    DDLogVerbose(@"%@: Unarchiving not possible, NSCoding archive file does not exist: %@", [self shortDescription], archiveFilePath);
    return false;
  }

  NSData* data = [NSData dataWithContentsOfFile:archiveFilePath];
  NSKeyedUnarchiver* unarchiver;
  @try
  {
    // This initializer uses NSDecodingFailurePolicySetErrorAndReturn, i.e. when
    // decoding fails it returns nil and does not raise an exception. The
    // initializer itself *does* throw an exception, though, if data is not a
    // valid keyed archive in the first place.
    unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                             error:nil];
  }
  @catch (NSException* exception)
  {
    DDLogError(@"%@: Unarchiving not possible, file %@ is not a valid NSCoding archive, exception name = %@, reason = %@", [self shortDescription], archiveFilePath, exception.name, exception.reason);

    if (self.shouldRemoveArchiveFileIfUnarchivingFails)
    {
      NSFileManager* fileManager = [NSFileManager defaultManager];
      BOOL result = [fileManager removeItemAtPath:archiveFilePath error:nil];
      DDLogVerbose(@"%@: Removed archive file %@, result = %d", [self shortDescription], archiveFilePath, result);
    }

    return false;
  }

  // Override default failure policy NSDecodingFailurePolicySetErrorAndReturn,
  // because the default policy is no good at indicating the source of an
  // error.
  unarchiver.decodingFailurePolicy = NSDecodingFailurePolicyRaiseException;

  GoGame* unarchivedGame = nil;
  @try
  {
    unarchivedGame = [unarchiver decodeObjectOfClass:[GoGame class] forKey:nsCodingGoGameKey];
  }
  @catch (NSException* exception)
  {
    DDLogError(@"%@: Unarchiving not possible, exception name = %@, reason = %@", [self shortDescription], exception.name, exception.reason);

    if (self.shouldRemoveArchiveFileIfUnarchivingFails)
    {
      NSFileManager* fileManager = [NSFileManager defaultManager];
      BOOL result = [fileManager removeItemAtPath:archiveFilePath error:nil];
      DDLogVerbose(@"%@: Removed archive file %@, result = %d", [self shortDescription], archiveFilePath, result);
    }

    return false;
  }

  [unarchiver finishDecoding];
  [unarchiver release];
  if (! unarchivedGame)
  {
    DDLogError(@"%@: Unarchiving not possible, NSCoding archive not compatible", [self shortDescription]);

    if (self.shouldRemoveArchiveFileIfUnarchivingFails)
    {
      NSFileManager* fileManager = [NSFileManager defaultManager];
      BOOL result = [fileManager removeItemAtPath:archiveFilePath error:nil];
      DDLogVerbose(@"%@: Removed archive file %@, result = %d", [self shortDescription], archiveFilePath, result);
    }

    return false;
  }

  self.game = unarchivedGame;

  return true;
}

@end
