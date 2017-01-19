// -----------------------------------------------------------------------------
// Copyright 2012-2017 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../diagnostics/BugReportUtilities.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoZobristTable.h"
#import "../../go/GoBoard.h"
#import "../../go/GoMove.h"


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
  [self calculateZobristHashes:self.unarchivedGame];

  [self postNotifications];
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
/// Calculates Zobrist hashes because they are not stored in the archive.
// -----------------------------------------------------------------------------
- (void) calculateZobristHashes:(GoGame*)unarchivedGame
{
  GoZobristTable* zobristTable = unarchivedGame.board.zobristTable;
  for (GoMove* move = unarchivedGame.firstMove; move != nil; move = move.next)
    move.zobristHash = [zobristTable hashForMove:move];
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
