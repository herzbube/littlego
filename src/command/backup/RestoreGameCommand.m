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
#import "RestoreGameCommand.h"
#import "../game/LoadGameCommand.h"
#import "../game/NewGameCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../play/boardposition/BoardPositionModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface RestoreGameCommand()
- (void) dealloc;
- (void) loadGameCommandFinished:(LoadGameCommand*)loadGameCommand;
@end


@implementation RestoreGameCommand


// -----------------------------------------------------------------------------
/// @brief Initializes a RestoreGameCommand object.
///
/// @note This is the designated initializer of RestoreGameCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RestoreGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  BOOL expandTilde = YES;
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, expandTilde);
  NSString* appSupportDirectory = [paths objectAtIndex:0];
  NSString* sgfBackupFilePath = [appSupportDirectory stringByAppendingPathComponent:sgfBackupFileName];

  NSFileManager* fileManager = [NSFileManager defaultManager];
  if ([fileManager fileExistsAtPath:sgfBackupFilePath])
  {
    LoadGameCommand* loadCommand = [[LoadGameCommand alloc] initWithFilePath:sgfBackupFilePath gameName:@"Backup"];
    loadCommand.restoreMode = true;
    loadCommand.waitUntilDone = true;
    [loadCommand whenFinishedPerformSelector:@selector(loadGameCommandFinished:)
                                    onObject:self];  // self is retained
    [loadCommand submit];  // not all parts of the command are executed synchronously
  }
  else
  {
    [[[NewGameCommand alloc] init] submit];
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when LoadGameCommand finishes executing.
// -----------------------------------------------------------------------------
- (void) loadGameCommandFinished:(LoadGameCommand*)loadGameCommand
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  // Integrity check in case the model has a stale value (e.g. due to an app
  // crash)
  if (boardPositionModel.boardPositionLastViewed > boardPosition.currentBoardPosition)
    return;
  // Special value -1 means "last board position of the game"
  if (-1 == boardPositionModel.boardPositionLastViewed)
    boardPositionModel.boardPositionLastViewed = boardPosition.currentBoardPosition;
  else
    boardPosition.currentBoardPosition = boardPositionModel.boardPositionLastViewed;
}

@end
