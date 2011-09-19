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
#import "PlayMoveCommand.h"
#import "ComputerPlayMoveCommand.h"
#import "FinalScoreCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../play/PlayView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayMoveCommand.
// -----------------------------------------------------------------------------
@interface PlayMoveCommand()
/// @name Initialization and deallocation
//@{
- (id) initWithMoveType:(enum GoMoveType)aMoveType;
- (void) dealloc;
//@}
/// @name GTP response handlers
//@{
- (void) gtpResponseReceived:(GtpResponse*)response;
//@}
@end


@implementation PlayMoveCommand

@synthesize game;
@synthesize moveType;
@synthesize point;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a play move at
/// @a point.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)aPoint
{
  assert(aPoint);
  if (! aPoint)
    return nil;
  self = [self initWithMoveType:PlayMove];
  self.point = aPoint;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a pass move.
// -----------------------------------------------------------------------------
- (id) initPass
{
  return [self initWithMoveType:PassMove];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayMoveCommand object that will make a move of type
/// @a aMoveType.
///
/// @note This is the designated initializer of PlayMoveCommand.
// -----------------------------------------------------------------------------
- (id) initWithMoveType:(enum GoMoveType)aMoveType
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
  self.moveType = aMoveType;
  self.point = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayMoveCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  self.point = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  // Must get this before updating the game model
  NSString* colorForMove = self.game.currentPlayer.colorString;

  // Update game model now, don't wait until we get the response to the GTP
  // command (as most of the other commands do). If we update the game model
  // now, the play view only needs to be updated once, which is good! If we
  // wait with the model update until after we receive the GTP response, the
  // play view will be updated twice:
  // - Once immediately after this method returns, which causes the cross-hair
  //   point to disappear
  // - A second time after a slight delay, when the GTP response arrives and
  //   we perform the model update
  // The delay looks very bad: It appears as if the stone that was just set by
  // the user's finger goes away for a moment (first update: the cross-hair
  // point is removed) and then reappears after a moment (second update: the
  // actual stone is set due to the model update).
  switch (self.moveType)
  {
    case PlayMove:
      [self.game play:point];
      break;
    case PassMove:
      [self.game pass];
      break;
    default:
      assert(0);
      return false;
  }

  NSString* commandString = @"play ";
  commandString = [commandString stringByAppendingString:colorForMove];
  commandString = [commandString stringByAppendingString:@" "];
  switch (self.moveType)
  {
    case PlayMove:
      commandString = [commandString stringByAppendingString:point.vertex.string];
      break;
    case PassMove:
      commandString = [commandString stringByAppendingString:@"pass"];
      break;
    default:
      assert(0);
      return false;
  }
  GtpCommand* command = [GtpCommand command:commandString
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

  // Game may end due to two pass moves in a row
  if (GameHasEnded == self.game.state)
  {
    FinalScoreCommand* command = [[FinalScoreCommand alloc] init];
    [command submit];
  }
  else
  {
    if ([self.game isComputerPlayersTurn])
    {
      ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
      [command submit];
    }
  }
}

@end
