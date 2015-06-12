// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "SaveGameCommand.h"
#import "../boardposition/SyncGTPEngineCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/PathUtilities.h"


@implementation SaveGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a SaveGameCommand object.
///
/// @note This is the designated initializer of SaveGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithSaveGame:(NSString*)aGameName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.gameName = aGameName;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SaveGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameName = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoGame* game = [GoGame sharedGame];
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSError* error;

  // The GTP engine saves its file into the temporary directory, but the final
  // destination is in the archive folder
  NSString* temporaryDirectory = NSTemporaryDirectory();
  NSString* sgfTemporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];
  NSString* fileName = [self.gameName stringByAppendingString:@".sgf"];
  NSString* filePath = [model.archiveFolder stringByAppendingPathComponent:fileName];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSString* oldCurrentDirectory = [fileManager currentDirectoryPath];
  [fileManager changeCurrentDirectoryPath:temporaryDirectory];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], temporaryDirectory);

  bool temporarilyResyncGTPEngine = false;
  if (! game.boardPosition.isLastPosition)
  {
    temporarilyResyncGTPEngine = true;
    SyncGTPEngineCommand* command = [[[SyncGTPEngineCommand alloc] init] autorelease];
    command.syncMoveType = SyncMovesOfEntireGame;
    bool syncSuccess = [command submit];
    [self throwIfSyncCommandFailed:syncSuccess];
  }

  // Use the file *NAME* without the path
  NSString* commandString = [NSString stringWithFormat:@"savesgf %@", sgfTemporaryFileName];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];

  if (temporarilyResyncGTPEngine)
  {
    bool syncSuccess = [[[[SyncGTPEngineCommand alloc] init] autorelease] submit];
    [self throwIfSyncCommandFailed:syncSuccess];
  }

  // Switch back as soon as possible; from now on operations use the full path
  // to the temporary file
  [fileManager changeCurrentDirectoryPath:oldCurrentDirectory];
  DDLogVerbose(@"%@: Working directory changed to %@", [self shortDescription], oldCurrentDirectory);

  if (! command.response.status)
  {
    [fileManager removeItemAtPath:sgfTemporaryFilePath error:nil];
    assert(0);
    NSString* errorMessage = [NSString stringWithFormat:@"Internal error: GTP engine failed to process 'savesgf' command, reason: %@", [command.response parsedResponse]];
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    [self showAlertWithMessage:errorMessage];
    return false;
  }

  // Get rid of another file of the same name (otherwise the subsequent move
  // operation fails)
  BOOL success = [PathUtilities moveItemAtPath:sgfTemporaryFilePath overwritePath:filePath error:&error];
  DDLogVerbose(@"%@: Moved file %@ to %@, result = %d", [self shortDescription], sgfTemporaryFilePath, filePath, success);
  if (! success)
  {
    [fileManager removeItemAtPath:sgfTemporaryFilePath error:nil];
    assert(0);
    [self showAlertWithError:error];
    return false;
  }

  [game.document save:self.gameName];
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
  [[NSNotificationCenter defaultCenter] postNotificationName:archiveContentChanged object:nil];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Raises an exception if @a syncCommandResult is false. Does nothing if
/// @a syncCommandResult is true.
// -----------------------------------------------------------------------------
- (void) throwIfSyncCommandFailed:(bool)syncCommandResult
{
  if (syncCommandResult)
    return;
  NSString* errorMessage = [NSString stringWithFormat:@"Failed to synchronize the GTP engine state with the current GoGame state"];
  DDLogError(@"%@: %@", self, errorMessage);
  NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                   reason:errorMessage
                                                 userInfo:nil];
  @throw exception;
}

// -----------------------------------------------------------------------------
/// @brief Displays "failed to save game" alert with the error details stored
/// in @a error.
// -----------------------------------------------------------------------------
- (void) showAlertWithError:(NSError*)error
{
  NSString* errorMessage = [NSString stringWithFormat:@"Internal error: Failed to save game, reason: %@", [error localizedDescription]];
  [self showAlertWithMessage:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Displays "failed to save game" alert with the error details stored
/// in @a message.
// -----------------------------------------------------------------------------
- (void) showAlertWithMessage:(NSString*)message
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to save game"
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = AlertViewTypeSaveGameFailed;
  [alert show];
  [alert release];
}

@end
