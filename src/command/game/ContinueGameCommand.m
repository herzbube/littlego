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
#import "ContinueGameCommand.h"
#import "../../go/GoGame.h"
#import "../move/ComputerPlayMoveCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ContinueGameCommand.
// -----------------------------------------------------------------------------
@interface ContinueGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation ContinueGameCommand

@synthesize game;


// -----------------------------------------------------------------------------
/// @brief Initializes a ContinueGameCommand object.
///
/// @note This is the designated initializer of ContinueGameCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  GoGame* sharedGame = [GoGame sharedGame];
  assert(sharedGame);
  if (! sharedGame)
    return nil;
  enum GoGameState gameState = sharedGame.state;
  assert(GameIsPaused == gameState);
  if (GameIsPaused != gameState)
    return nil;

  self.game = sharedGame;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ContinueGameCommand object.
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
  if (ComputerVsComputerGame != self.game.type)
    return false;

  [self.game continue];

  if (self.game.isComputerThinking)
  {
    // Do nothing. If computer is still thinking, the next move will be
    // triggered automatically as soon as thinking for the current move ends.
  }
  else
  {
    // Restart automatic game play. If computer has stopped thinking, the game
    // apparently has been paused long enough for the last computer player move
    // to have been played.
    ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
    [command submit];
  }

  return true;
}

@end
