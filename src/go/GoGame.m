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
#import "GoGame.h"
#import "GoBoard.h"
#import "GoPlayer.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoBoardRegion.h"
#import "GoVertex.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"
#import "../ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoGame.
// -----------------------------------------------------------------------------
@interface GoGame()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name Setters needed for posting notifications to notify our observers
//@{
- (void) setFirstMove:(GoMove*)newValue;
- (void) setLastMove:(GoMove*)newValue;
- (void) setComputerThinks:(bool)newValue;
//@}
/// @name Submit GTP commands
//@{
- (void) submitPlayMove:(NSString*)vertex;
- (void) submitPassMove;
- (void) submitGenMove;
- (void) submitFinalScore;
//@}
/// @name Update state
//@{
- (void) updatePlayMove:(GoPoint*)point;
- (void) updatePassMove;
- (void) updateResignMove;
//@}
/// @name Others methods
//@{
- (void) gtpResponseReceived:(NSNotification*)notification;
- (NSString*) colorStringForMoveAfter:(GoMove*)move;
- (bool) isComputerPlayersTurn;
//@}
@end


@implementation GoGame

@synthesize board;
@synthesize playerBlack;
@synthesize playerWhite;
@synthesize firstMove;
@synthesize lastMove;
@synthesize state;
@synthesize boardSize;
@synthesize computerThinks;
@synthesize score;


// -----------------------------------------------------------------------------
/// @brief Shared instance of GoGame.
// -----------------------------------------------------------------------------
static GoGame* sharedGame = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared GoGame object that represents the current game.
/// If no such object exists, a new one is created.
// -----------------------------------------------------------------------------
+ (GoGame*) sharedGame;
{
  if (! sharedGame)
    return [GoGame newGame];
  else
    return sharedGame;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new GoGame object and returns that object. From now on,
/// sharedGame() also returns the same object. If another GoGame object exists
/// at the moment, it is de-allocated first.
// -----------------------------------------------------------------------------
+ (GoGame*) newGame
{
  if (sharedGame)
  {
    [sharedGame release];
    assert(nil == sharedGame);
  }
  // TODO: We are the owner of sharedGame, but we never release the object
  GoGame* newGame = [[GoGame alloc] init];
  assert(newGame == sharedGame);

  [[NSNotificationCenter defaultCenter] postNotificationName:goGameNewCreated object:newGame];

  return newGame;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGame object.
///
/// @note This is the designated initializer of GoGame.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Make sure that this instance of GoGame is globally available
  assert(nil == sharedGame);
  sharedGame = self;

  self.board = [GoBoard board];
  self.playerBlack = [GoPlayer blackPlayer];
  self.playerWhite = [GoPlayer whitePlayer];
  self.firstMove = nil;
  self.lastMove = nil;
  self.state = GameHasNotYetStarted;
  self.computerThinks = false;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseReceived:)
                                               name:gtpResponseReceivedNotification
                                             object:nil];
  [[GtpCommand command:@"clear_board"] submit];

  // Setting this property triggers creation of all GoPoint objects
  // -> do this only after everything else has been set up
  // TODO Try to improve the design so that the order of initialization is
  // not important
  // TODO It would be better if GoBoard would initialize itself to the correct
  // size by reading from the user defaults. Note that the GTP client also
  // needs to be set up.
  self.boardSize = 19;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoGame object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  sharedGame = nil;
  self.board = nil;
  self.playerBlack = nil;
  self.playerWhite = nil;
  self.firstMove = nil;
  self.lastMove = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFirstMove:(GoMove*)newValue
{
  @synchronized(self)
  {
    if (firstMove == newValue)
      return;
    [firstMove release];
    firstMove = [newValue retain];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameFirstMoveChanged object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setLastMove:(GoMove*)newValue
{
  @synchronized(self)
  {
    if (lastMove == newValue)
      return;
    [lastMove release];
    lastMove = [newValue retain];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameLastMoveChanged object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setState:(enum GoGameState)newValue
{
  @synchronized(self)
  {
    if (state == newValue)
      return;
    state = newValue;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameStateChanged object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (int) boardSize
{
  @synchronized(self)
  {
    return board.size;
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setBoardSize:(int)newValue
{
  @synchronized(self)
  {
    board.size = newValue;
    [[GtpCommand command:[NSString stringWithFormat:@"boardsize %d", newValue]] submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Generates a GoMove of type #PlayMove for the player whose turn it
/// is (should be a human player). The computer player is triggered if it is
/// now its turn to move.
// -----------------------------------------------------------------------------
- (void) play:(GoPoint*)point
{
  [self submitPlayMove:point.vertex.string];
  [self updatePlayMove:point];
  if ([self isComputerPlayersTurn])
    [self computerPlay];
}

// -----------------------------------------------------------------------------
/// @brief Generates a GoMove of type #PassMove for the player whose turn it
/// is (should be a human player). The computer player is triggered if it is
/// now its turn to move.
// -----------------------------------------------------------------------------
- (void) pass
{
  [self submitPassMove];
  [self updatePassMove];
  if ([self isComputerPlayersTurn])
    [self computerPlay];
}

// -----------------------------------------------------------------------------
/// @brief Generates a GoMove of type #ResignMove for the player whose turn it
/// is (should be a human player). The game state changes to #GameHasEnded.
// -----------------------------------------------------------------------------
- (void) resign
{
  [self submitFinalScore];
  [self updateResignMove];
  // TODO calculate score
}

// -----------------------------------------------------------------------------
/// @brief Lets the computer player make a move even if it is not his turn.
// -----------------------------------------------------------------------------
- (void) computerPlay
{
  [self submitGenMove];
}

// -----------------------------------------------------------------------------
/// @brief Takes back the last move made by a human player, including any
/// computer player moves that were made in response.
// -----------------------------------------------------------------------------
- (void) undo
{
  // TODO not yet implementend
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a stone on the intersection represented by
/// @a point would be legal. This includes checking for suicide moves and
/// Ko situations.
// -----------------------------------------------------------------------------
- (bool) isLegalNextMove:(GoPoint*)point
{
  // We could use the Fuego-specific GTP command "go_point_info" to obtain
  // the desired information, but parsing the response would require some
  // effort, is prone to fail when Fuego changes its response format, and
  // Fuego also does not tell us directly whether or not the point is protected
  // by a Ko, so we would have to derive this information from the other parts
  // of the response.
  // -> it's better to implement this in our own terms
  if (! point)
    return false;
  else if ([point hasStone])
    return false;
  else if ([point liberties] > 0)
    return true;
  else
  {
    bool nextMoveIsBlack = true;
    if (self.lastMove)
      nextMoveIsBlack = ! self.lastMove.isBlack;
    bool isKoStillPossible = true;

    NSArray* neighbours = point.neighbours;
    for (GoPoint* neighbour in neighbours)
    {
      if ([neighbour blackStone] == nextMoveIsBlack)  // friendly color?
      {
        // If we are connecting to a stone group with more than just one
        // liberty, we are *NOT* killing it, so the move is not a suicide and
        // therefore legal
        if ([neighbour liberties] > 1)
          return true;
        else
        {
          // A Ko situation is not possible since one of our neighbours is a
          // friendly colored stone
          isKoStillPossible = false;
        }
      }
      else  // opposing color!
      {
        // Can we capture the stone (or the group to which it belongs)?
        if ([neighbour liberties] == 1)
        {
          // Yes, we can capture the group. If the group is larger than 1 stone
          // it can't be a Ko, so the move is legal
          GoBoardRegion* neighbourRegion = neighbour.region;
          if ([neighbourRegion size] > 1)
            return true;
          else if (isKoStillPossible)
          {
            // There is a Ko if the opposing stone was just played during the
            // last turn, so the move is illegal
            GoPoint* lastMovePoint = self.lastMove.point;
            if (lastMovePoint && [lastMovePoint isEqualToPoint:neighbour])
              return false;
          }
        }
      }
    }
    // If we arrive here, no opposing stones can be captured and there are no
    // friendly groups with sufficient liberties to connect to
    // -> the move is a suicide and therefore illegal
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the game has started and is still running, i.e.
/// moves are still possible.
// -----------------------------------------------------------------------------
- (bool) hasStarted
{
  return (GameHasStarted == self.state);
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the game has ended, i.e. moves are no longer allowed.
// -----------------------------------------------------------------------------
- (bool) hasEnded
{
  return (GameHasEnded == self.state);
}

// -----------------------------------------------------------------------------
/// @brief Submits a "play" command to the GTP engine.
///
/// This method returns immediately. gtpResponseReceived:() is triggered as
/// soon as the GTP engine response has arrived.
// -----------------------------------------------------------------------------
- (void) submitPlayMove:(NSString*)vertex
{
  NSString* commandString = @"play ";
  commandString = [commandString stringByAppendingString:
                   [self colorStringForMoveAfter:self.lastMove]];
  commandString = [commandString stringByAppendingString:@" "];
  commandString = [commandString stringByAppendingString:vertex];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Submits a "pass" command to the GTP engine.
///
/// This method returns immediately. gtpResponseReceived:() is triggered as
/// soon as the GTP engine response has arrived.
// -----------------------------------------------------------------------------
- (void) submitPassMove
{
  [self submitPlayMove:@"pass"];
}

// -----------------------------------------------------------------------------
/// @brief Submits a "genmove" command to the GTP engine.
///
/// This method returns immediately. gtpResponseReceived:() is triggered as
/// soon as the GTP engine response has arrived.
// -----------------------------------------------------------------------------
- (void) submitGenMove
{
  self.computerThinks = true;
  NSString* commandString = @"genmove ";
  commandString = [commandString stringByAppendingString:
                   [self colorStringForMoveAfter:self.lastMove]];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Submits a "final_score" command to the GTP engine.
///
/// This method returns immediately. gtpResponseReceived:() is triggered as
/// soon as the GTP engine response has arrived.
// -----------------------------------------------------------------------------
- (void) submitFinalScore
{
  // Scoring involves the following
  // 1. Captured stones
  // 2. Dead stones
  // 3. Territory
  // 4. Komi
  // Little Go is capable of counting 1 and 4, but not 2 and 3. So for the
  // moment we rely on Fuego's scoring.
  self.computerThinks = true;
  GtpCommand* command = [GtpCommand command:@"final_score"];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #PlayMove.
///
/// This method does not care about GTP.
// -----------------------------------------------------------------------------
- (void) updatePlayMove:(GoPoint*)point
{
  GoMove* move = [GoMove move:PlayMove after:self.lastMove];
  move.point = point;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  self.state = GameHasStarted;
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #PassMove.
///
/// This method does not care about GTP.
// -----------------------------------------------------------------------------
- (void) updatePassMove
{
  GoMove* move = [GoMove move:PassMove after:self.lastMove];

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  if (move.previous.type == PassMove)
  {
    [self submitFinalScore];
    self.state = GameHasEnded;
  }
  else
    self.state = GameHasStarted;
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #ResignMove.
///
/// This method does not care about GTP.
// -----------------------------------------------------------------------------
- (void) updateResignMove
{
  GoMove* move = [GoMove move:ResignMove after:self.lastMove];

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  self.state = GameHasEnded;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered whenever the GTP engine responds to a command.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(NSNotification*)notification
{
  GtpResponse* response = (GtpResponse*)[notification object];
  if (! response.status)
    return;
  NSString* commandString = response.command.command;
  if ([commandString hasPrefix:@"genmove"])
  {
    self.computerThinks = false;
    NSString* responseString = response.parsedResponse;
    if ([responseString isEqualToString:@"pass"])
      [self updatePassMove];
    else if ([responseString isEqualToString:@"resign"])
      [self updateResignMove];
    else
    {
      GoPoint* point = [self.board pointAtVertex:responseString];
      if (point)
        [self updatePlayMove:point];
      else
        ;  // TODO vertex was invalid; do something...
    }
    if ([self isComputerPlayersTurn])
      [self computerPlay];
  }
  else if ([commandString isEqualToString:@"final_score"])
  {
    self.computerThinks = false;
    // TODO parse result
    self.score = response.parsedResponse;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns either the string "B" or the string "W" to signify which
/// color (B=Black, W=White) will make the next move after @a move.
// -----------------------------------------------------------------------------
- (NSString*) colorStringForMoveAfter:(GoMove*)move
{
  // TODO what about a GoColor class?
  bool playForBlack = true;
  if (self.lastMove)
    playForBlack = ! self.lastMove.isBlack;
  if (playForBlack)
    return @"B";
  else
    return @"W";
}

// -----------------------------------------------------------------------------
/// @brief Returns true if it is the computer player's turn.
// -----------------------------------------------------------------------------
- (bool) isComputerPlayersTurn
{
  // TODO: Find a better way to determine when it is the computer player's
  // turn. This works only as long as white is fixed to be the computer
  if (! self.lastMove)
    return false;  // first turn always goes to black
  return self.lastMove.black;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setComputerThinks:(bool)newValue
{
  @synchronized(self)
  {
    if (computerThinks == newValue)
      return;
    computerThinks = newValue;
    NSString* notificationName;
    if (newValue)
      notificationName = computerPlayerThinkingStarts;
    else
      notificationName = computerPlayerThinkingStops;
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setScore:(NSString*)newValue
{
  @synchronized(self)
  {
    if ([score isEqualToString:newValue])
      return;
    [score release];
    score = [newValue retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:goGameScoreChanged object:self];
  }
}

@end
