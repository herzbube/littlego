// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "CleanBackupCommand.h"
#import "../game/LoadGameCommand.h"
#import "../game/NewGameCommand.h"
#import "../../ApplicationDelegate.h"
#import "../../go/GoGame.h"
#import "../../player/PlayerModel.h"
#import "../../player/Player.h"
#import "../../newgame/NewGameModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface RestoreGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
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
    NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
    PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
    Player* blackPlayer = [playerModel playerWithUUID:newGameModel.blackPlayerUUID];
    Player* whitePlayer = [playerModel playerWithUUID:newGameModel.whitePlayerUUID];

    LoadGameCommand* loadCommand = [[LoadGameCommand alloc] initWithFilePath:sgfBackupFilePath];
    loadCommand.waitUntilDone = true;
    loadCommand.blackPlayer = blackPlayer;
    loadCommand.whitePlayer = whitePlayer;
    [loadCommand submit];  // command is executed synchronously
    [[[CleanBackupCommand alloc] init] submit];
  }
  else
  {
    [[[NewGameCommand alloc] init] submit];
  }

  return true;
}

@end
