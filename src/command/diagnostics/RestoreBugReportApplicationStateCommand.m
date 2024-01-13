// -----------------------------------------------------------------------------
// Copyright 2012-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "RestoreBugReportApplicationStateCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../diagnostics/BugReportUtilities.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// RestoreBugReportApplicationStateCommand.
// -----------------------------------------------------------------------------
@interface RestoreBugReportApplicationStateCommand()
@property(nonatomic, retain) GoGame* unarchivedGame;
@end


@implementation RestoreBugReportApplicationStateCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a RestoreBugReportApplicationStateCommand object.
///
/// @note This is the designated initializer of
/// RestoreBugReportApplicationStateCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  self.unarchivedGame = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// RestoreBugReportApplicationStateCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.unarchivedGame = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  [self unarchiveInMemoryObjects];
  if (! self.unarchivedGame)
  {
    DDLogError(@"%@: Aborting because self.unarchivedGame is nil", [self shortDescription]);
    return false;
  }
  [self fixObjectReferences];
  [GoUtilities relinkMoves:self.unarchivedGame];
  [GoUtilities recalculateZobristHashes:self.unarchivedGame];

  [self postNotifications];
  [self syncGtpEngine];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Unarchives in-memory objects from diagnostics information dump file.
// -----------------------------------------------------------------------------
- (void) unarchiveInMemoryObjects
{
  DDLogVerbose(@"%@: Unarchiving in-memory objects", [self shortDescription]);

  NSString* archiveFilePath = [[BugReportUtilities diagnosticsInformationFolderPath] stringByAppendingPathComponent:bugReportInMemoryObjectsArchiveFileName];
  NSData* data = [NSData dataWithContentsOfFile:archiveFilePath];

  // This initializer uses NSDecodingFailurePolicySetErrorAndReturn, i.e. when
  // decoding fails it returns nil and does not raise an exception. The
  // initializer itself *does* throw an exception, though, if data is not a
  // valid keyed archive in the first place.
  NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data
                                                                              error:nil];

  self.unarchivedGame = [unarchiver decodeObjectForKey:nsCodingGoGameKey];
  [unarchiver finishDecoding];
  [unarchiver release];
}

// -----------------------------------------------------------------------------
/// @brief Fixes incomplete relationships in the object tree.
// -----------------------------------------------------------------------------
- (void) fixObjectReferences
{
  DDLogVerbose(@"%@: Fixing object references", [self shortDescription]);

  ApplicationDelegate* applicationDelegate = [ApplicationDelegate sharedDelegate];
  applicationDelegate.game = self.unarchivedGame;
}

// -----------------------------------------------------------------------------
/// @brief Posts notifications that were not sent during unarchiving
// -----------------------------------------------------------------------------
- (void) postNotifications
{
  DDLogVerbose(@"%@: Posting notifications", [self shortDescription]);

  [[NSNotificationCenter defaultCenter] postNotificationName:goGameDidCreate object:self.unarchivedGame];
}

// -----------------------------------------------------------------------------
/// @brief Synchronizes the GTP engine to match the state of the current GoGame.
// -----------------------------------------------------------------------------
- (void) syncGtpEngine
{
  DDLogVerbose(@"%@: Sync GTP engine with the current GoGame state", [self shortDescription]);

  SyncGTPEngineCommand* command = [[[SyncGTPEngineCommand alloc] init] autorelease];
  bool success = [command submit];
  if (! success)
  {
    NSString* errorMessage = @"Failed to synchronize the GTP engine state with the current GoGame state";
    DDLogError(@"%@: %@. GTP engine error message:\n\n%@", self, errorMessage, command.errorDescription);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

@end
