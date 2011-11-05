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
#import "ComputerPlayMoveCommand.h"
#import "ResignMoveCommand.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ComputerPlayMoveCommand.
// -----------------------------------------------------------------------------
@interface ComputerPlayMoveCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name GTP response handlers
//@{
- (void) gtpResponseReceived:(GtpResponse*)response;
//@}
@end


@implementation ComputerPlayMoveCommand

@synthesize game;


// -----------------------------------------------------------------------------
/// @brief Initializes a ComputerPlayMoveCommand.
///
/// @note This is the designated initializer of ComputerPlayMoveCommand.
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
/// @brief Deallocates memory allocated by this ComputerPlayMoveCommand object.
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
  NSString* commandString = @"genmove ";
  commandString = [commandString stringByAppendingString:self.game.currentPlayer.colorString];
  GtpCommand* command = [GtpCommand command:commandString
                             responseTarget:self
                                   selector:@selector(gtpResponseReceived:)];
  [command submit];

  self.game.nextMoveIsComputerGenerated = true;
  // Thinking state must change after any of the other things; this order is
  // important for observer notifications
  self.game.computerThinks = true;

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

  bool shouldResign = false;
  NSString* responseString = [response.parsedResponse lowercaseString];
  if ([responseString isEqualToString:@"pass"])
    [self.game pass];
  else if ([responseString isEqualToString:@"resign"])
    shouldResign = true;  // wait until thinking state has been updated
  else
  {
    GoPoint* point = [self.game.board pointAtVertex:responseString];
    if (point)
      [self.game play:point];
    else
      ;  // TODO vertex was invalid; do something...
  }

  // Thinking state must change after any of the other things; this order is
  // important for observer notifications
  self.game.computerThinks = false;

  if (shouldResign)
  {
    ResignMoveCommand* command = [[ResignMoveCommand alloc] init];
    [command submit];
  }
  else
  {
    // Let computer continue playing if the game state allows it and it is
    // actually a computer player's turn
    switch (self.game.state)
    {
      case GameIsPaused:  // game has been paused while GTP was thinking about its last move
      case GameHasEnded:  // game has ended as a result of the last move (e.g. resign, 2x pass)
        break;
      default:
        if ([self.game isComputerPlayersTurn])
        {
          ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
          [command submit];
        }
        break;
    }
  }
}

@end
