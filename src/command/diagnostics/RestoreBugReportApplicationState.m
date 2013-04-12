// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "RestoreBugReportApplicationState.h"
#import "../../diagnostics/BugReportUtilities.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/ScoringModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// RestoreBugReportApplicationState.
// -----------------------------------------------------------------------------
@interface RestoreBugReportApplicationState()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (void) unarchiveInMemoryObjects;
- (void) fixObjectReferences;
- (void) loadCurrentGameFromSgf;
//@}
/// @name Private properties
//@{
@property(nonatomic, retain) GoGame* unarchivedGame;
@property(nonatomic, retain) GoScore* unarchivedScore;
//@}
@end


@implementation RestoreBugReportApplicationState

// -----------------------------------------------------------------------------
/// @brief Initializes a RestoreBugReportApplicationState object.
///
/// @note This is the designated initializer of
/// RestoreBugReportApplicationState.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.unarchivedGame = nil;
  self.unarchivedScore = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RestoreBugReportApplicationState
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.unarchivedGame = nil;
  self.unarchivedScore = nil;
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
  [self loadCurrentGameFromSgf];
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
  NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
  self.unarchivedGame = [unarchiver decodeObjectForKey:nsCodingGoGameKey];
  self.unarchivedScore = [unarchiver decodeObjectForKey:nsCodingGoScoreKey];
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
  // Must send this notification manually. Must send it now before scoring model
  // sends its own notification.
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameDidCreate object:self.unarchivedGame];

  if (self.unarchivedScore)
  {
    ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
    // Scoring model sends its own notification
    [scoringModel restoreScoringModeWithScoreObject:self.unarchivedScore];
  }
}

// -----------------------------------------------------------------------------
/// @brief Loads the .sgf file from the diagnostics information package into
/// Fuego.
///
/// This method does not execute LoadGameCommand because we only need to send
/// the "loadsgf" GTP command.
// -----------------------------------------------------------------------------
- (void) loadCurrentGameFromSgf
{
  DDLogVerbose(@"%@: Loading current game from .sgf file", [self shortDescription]);

  // Temporarily change working directory so that Fuego finds the .sgf file
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:[BugReportUtilities diagnosticsInformationFolderPath]];

  NSString* commandString = [NSString stringWithFormat:@"loadsgf %@", bugReportCurrentGameFileName];
  GtpCommand* gtpCommand = [GtpCommand command:commandString];
  gtpCommand.waitUntilDone = true;
  [gtpCommand submit];
  bool success = gtpCommand.response.status;

  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];

  if (! success)
  {
    NSString* errorMessage = @"Failed to load current game from .sgf file";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
}

@end
