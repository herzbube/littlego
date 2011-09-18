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
#import "UndoMoveCommand.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../play/PlayView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for UndoMoveCommand.
// -----------------------------------------------------------------------------
@interface UndoMoveCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name GTP response handlers
//@{
- (void) gtpResponseReceived:(GtpResponse*)response;
//@}
@end


@implementation UndoMoveCommand

@synthesize game;


// -----------------------------------------------------------------------------
/// @brief Initializes a UndoMoveCommand object.
///
/// @note This is the designated initializer of UndoMoveCommand.
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
  assert(GameHasEnded != gameState);
  if (GameHasEnded == gameState)
    return nil;

  self.game = sharedGame;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UndoMoveCommand object.
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
  // It is possible that we need to undo two moves, but we want them to be drawn
  // in a single view update. Therefore we need to disable view updates now.
  [[PlayView sharedView] actionStarts];

  GtpCommand* command = [GtpCommand command:@"undo"
                             responseTarget:self
                                   selector:@selector(gtpResponseReceived:)];
  [command submit];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered whenever the GTP engine responds to a command.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  if (! response.status)
  {
    assert(0);
    return;
  }

  [self.game undo];

  // If it's now the computer player's turn, the "undo" above took back the
  // computer player's move
  // -> now also take back the player's move
  if ([self.game isComputerPlayersTurn])
  {
    UndoMoveCommand* command = [[UndoMoveCommand alloc] init];
    [command submit];
  }

  // Re-enable play view updates
  [[PlayView sharedView] actionEnds];
}

@end
