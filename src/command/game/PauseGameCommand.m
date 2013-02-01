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
#import "PauseGameCommand.h"
#import "../../go/GoGame.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PauseGameCommand.
// -----------------------------------------------------------------------------
@interface PauseGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation PauseGameCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a PauseGameCommand object.
///
/// @note This is the designated initializer of PauseGameCommand.
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
  assert(GoGameStateGameHasStarted == gameState);
  if (GoGameStateGameHasStarted != gameState)
    return nil;

  self.game = sharedGame;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PauseGameCommand object.
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
  if (GoGameTypeComputerVsComputer != self.game.type)
    return false;

  [self.game pause];
  return true;
}

@end
