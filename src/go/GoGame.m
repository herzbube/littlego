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
#import "../newgame/NewGameModel.h"
#import "../player/Player.h"


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
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite) enum GoGameType type;
//@}
@end


@implementation GoGame

@synthesize type;
@synthesize board;
@synthesize playerBlack;
@synthesize playerWhite;
@synthesize currentPlayer;
@synthesize firstMove;
@synthesize lastMove;
@synthesize state;
@synthesize computerThinks;
@synthesize score;


// -----------------------------------------------------------------------------
/// @brief Shared instance of GoGame.
// -----------------------------------------------------------------------------
static GoGame* sharedGame = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared GoGame object that represents the current game.
// -----------------------------------------------------------------------------
+ (GoGame*) sharedGame;
{
  return sharedGame;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new GoGame object and returns that object. From now on,
/// sharedGame() also returns the same object.
// -----------------------------------------------------------------------------
+ (GoGame*) newGame
{
  GoGame* newGame = [[[GoGame alloc] init] autorelease];
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
  sharedGame = self;

  // Initialize members (some objects initialize themselves with values from
  // NewGameModel, but we don't really have to know about this)
  self.board = [GoBoard newGameBoard];
  self.playerBlack = [GoPlayer newGameBlackPlayer];
  self.playerWhite = [GoPlayer newGameWhitePlayer];
  self.firstMove = nil;
  self.lastMove = nil;
  self.state = GameHasNotYetStarted;
  self.computerThinks = false;

  bool blackPlayerIsHuman = self.playerBlack.player.human;
  bool whitePlayerIsHuman = self.playerWhite.player.human;
  if (blackPlayerIsHuman && whitePlayerIsHuman)
    self.type = HumanVsHumanGame;
  else if (! blackPlayerIsHuman && ! whitePlayerIsHuman)
    self.type = ComputerVsComputerGame;
  else
    self.type = ComputerVsHumanGame;

  // Post-initialization, after everything else has been set up (especially the
  // shared game instance and a reference to the GoBoard object must have been
  // set up)
  [self.board setupBoard];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoGame object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.board = nil;
  self.playerBlack = nil;
  self.playerWhite = nil;
  self.firstMove = nil;
  self.lastMove = nil;
  if (self == sharedGame)
    sharedGame = nil;
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
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #PlayMove.
// -----------------------------------------------------------------------------
- (void) play:(GoPoint*)aPoint
{
  GoMove* move = [GoMove move:PlayMove by:self.currentPlayer after:self.lastMove];
  move.point = aPoint;  // many side-effects here (e.g. region handling) !!!

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  if (GameHasNotYetStarted == self.state)
    self.state = GameHasStarted;  // don't set this state if game is currently paused
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #PassMove.
// -----------------------------------------------------------------------------
- (void) pass
{
  GoMove* move = [GoMove move:PassMove by:self.currentPlayer after:self.lastMove];

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  if (move.previous.type == PassMove)
    self.state = GameHasEnded;
  else
  {
    if (GameHasNotYetStarted == self.state)
      self.state = GameHasStarted;  // don't set this state if game is currently paused
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #ResignMove.
// -----------------------------------------------------------------------------
- (void) resign
{
  GoMove* move = [GoMove move:ResignMove by:self.currentPlayer after:self.lastMove];

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  self.state = GameHasEnded;
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players taking back his move.
// -----------------------------------------------------------------------------
- (void) undo
{
  GoMove* undoMove = self.lastMove;
  GoMove* newLastMove = undoMove.previous;  // get this reference before it disappears
  [undoMove undo];  // many side-effects here (e.g. region handling) !!!

  // One of the following statements will cause the retain count of lastMove
  // to drop to zero
  // -> the object will be deallocated
  self.lastMove = newLastMove;  // is nil if we are undoing the first move
  if (self.firstMove == undoMove)
    self.firstMove = nil;

  // No game state change
  // - Since we are able to undo moves, this clearly means that we are in state
  //   GameHasStarted
  // - But undoing a move will never cause the game to revert to state
  //   GameHasNotYetStarted
}

// -----------------------------------------------------------------------------
/// @brief Pauses the game if two computer players play against each other.
///
/// The computer player whose turn it is will finish its thinking and play its
/// move. The game is then paused, i.e. the second computer player's move is
/// not triggered.
///
/// This solution is necessary because there is no way to tell the GTP engine
/// to stop its thinking once the "genmove" command has been sent. The only
/// way how to handle this in a graceful way is to let the GTP engine finish
/// its thinking.
// -----------------------------------------------------------------------------
- (void) pause
{
  assert(ComputerVsComputerGame == self.type);
  assert(GameHasStarted == self.state);
  self.state = GameIsPaused;
}

// -----------------------------------------------------------------------------
/// @brief Continues the game if it is paused while two computer players play
/// against each other.
///
/// Essentially, this method triggers the next computer player move.
// -----------------------------------------------------------------------------
- (void) continue
{
  assert(ComputerVsComputerGame == self.type);
  assert(GameIsPaused == self.state);
  self.state = GameHasStarted;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a stone on the intersection represented by
/// @a point would be legal. This includes checking for suicide moves and
/// Ko situations.
// -----------------------------------------------------------------------------
- (bool) isLegalMove:(GoPoint*)point
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
    bool nextMoveIsBlack = self.currentPlayer.isBlack;
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
/// @brief Returns either the string "B" or the string "W" to signify which
/// color (B=Black, W=White) will make the next move after @a move.
// -----------------------------------------------------------------------------
- (NSString*) colorStringForMoveAfter:(GoMove*)move
{
  // TODO what about a GoColor class?
  bool playForBlack = true;
  if (self.lastMove)
    playForBlack = ! self.lastMove.player.isBlack;
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
  return (! self.currentPlayer.player.isHuman);
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoPlayer*) currentPlayer
{
  GoMove* move = self.lastMove;
  if (! move)
    return self.playerBlack;
  else if (move.player == self.playerBlack)
    return self.playerWhite;
  else
    return self.playerBlack;
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
