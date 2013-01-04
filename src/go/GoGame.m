// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoPlayer.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoBoardRegion.h"
#import "GoUtilities.h"
#import "../player/Player.h"
#import "../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoGame.
// -----------------------------------------------------------------------------
@interface GoGame()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
/// @name NSCoding protocol
//@{
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
//@}
/// @name Setters needed for posting notifications to notify our observers
//@{
- (void) setFirstMove:(GoMove*)newValue;
- (void) setLastMove:(GoMove*)newValue;
- (void) setComputerThinks:(bool)newValue;
//@}
@end


@implementation GoGame

@synthesize type;
@synthesize board;
@synthesize handicapPoints;
@synthesize komi;
@synthesize playerBlack;
@synthesize playerWhite;
@synthesize firstMove;
@synthesize lastMove;
@synthesize state;
@synthesize reasonForGameHasEnded;
@synthesize computerThinks;
@synthesize nextMoveIsComputerGenerated;


// -----------------------------------------------------------------------------
/// @brief Returns the shared GoGame object that represents the current game.
// -----------------------------------------------------------------------------
+ (GoGame*) sharedGame;
{
  return [ApplicationDelegate sharedDelegate].game;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new GoGame object and returns that object. From now on,
/// sharedGame() also returns the same object.
// -----------------------------------------------------------------------------
+ (GoGame*) newGame
{
  GoGame* newGame = [[[GoGame alloc] init] autorelease];
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

  // Don't use "self" because most properties have non-trivial setter methods
  // (e.g. notificatins are triggered, but also other stuff)
  type = GoGameTypeUnknown;
  board = nil;
  handicapPoints = [[NSArray array] retain];
  komi = 0;
  playerBlack = nil;
  playerWhite = nil;
  firstMove = nil;
  lastMove = nil;
  state = GoGameStateGameHasNotYetStarted;
  reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  computerThinks = false;
  nextMoveIsComputerGenerated = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  // Don't use "self" because most properties have non-trivial setter methods
  // (e.g. notificatins are triggered, but also other stuff)
  type = [decoder decodeIntForKey:goGameTypeKey];
  board = [[decoder decodeObjectForKey:goGameBoardKey] retain];
  handicapPoints = [[decoder decodeObjectForKey:goGameHandicapPointsKey] retain];
  komi = [decoder decodeDoubleForKey:goGameKomiKey];
  playerBlack = [[decoder decodeObjectForKey:goGamePlayerBlackKey] retain];
  playerWhite = [[decoder decodeObjectForKey:goGamePlayerWhiteKey] retain];
  firstMove = [[decoder decodeObjectForKey:goGameFirstMoveKey] retain];
  lastMove = [[decoder decodeObjectForKey:goGameLastMoveKey] retain];
  state = [decoder decodeIntForKey:goGameStateKey];
  reasonForGameHasEnded = [decoder decodeIntForKey:goGameReasonForGameHasEndedKey];
  computerThinks = [decoder decodeBoolForKey:goGameIsComputerThinkingKey];
  nextMoveIsComputerGenerated = [decoder decodeBoolForKey:goGameNextMoveIsComputerGeneratedKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoGame object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.board = nil;
  // Don't use self.handicapPoints, because setHandicapPoints:() is not
  // intelligent enough to detect that it is called during deallocation and
  // will throw an exception if the game state is not what it expects
  if (handicapPoints)
  {
    [handicapPoints release];
    handicapPoints = nil;
  }
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
  if (firstMove == newValue)
    return;
  [firstMove release];
  firstMove = [newValue retain];
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameFirstMoveChanged object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setLastMove:(GoMove*)newValue
{
  if (lastMove == newValue)
    return;
  [lastMove release];
  lastMove = [newValue retain];
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameLastMoveChanged object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setState:(enum GoGameState)newValue
{
  if (state == newValue)
    return;
  state = newValue;
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameStateChanged object:self];
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #GoMoveTypePlay.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted,
/// #GoGameStateGameHasStarted or #GoGameStateGameIsPaused.
///
/// @note Play when in paused state is allowed only because the computer
/// player who is thinking at the time the game is paused must be able to
/// finish its turn.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil, if isLegalMove:()
/// returns false for @a aPoint, or if an exception occurs while actually
/// playing on @a aPoint.
// -----------------------------------------------------------------------------
- (void) play:(GoPoint*)aPoint
{
  if (GoGameStateGameHasNotYetStarted != self.state &&
      GoGameStateGameHasStarted != self.state &&
      GoGameStateGameIsPaused != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Play is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted, GoGameStateGameHasStarted or GoGameStateGameIsPaused"
                                                   userInfo:nil];
    @throw exception;
  }
  if (! aPoint)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }
  if (! [self isLegalMove:aPoint])
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:[NSString stringWithFormat:@"Point argument is not a legal move: %@", aPoint.vertex]
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePlay by:self.currentPlayer after:self.lastMove];
  @try
  {
    move.point = aPoint;  // many side-effects here (e.g. region handling) !!!
  }
  @catch (NSException* exception)
  {
    NSException* newException = [NSException exceptionWithName:NSInvalidArgumentException
                                                        reason:[NSString stringWithFormat:@"Exception occurred while playing on intersection %@. Exception = %@", aPoint.vertex, exception]
                                                      userInfo:nil];
    @throw newException;
  }
  move.computerGenerated = self.nextMoveIsComputerGenerated;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  if (GoGameStateGameHasNotYetStarted == self.state)
    self.state = GoGameStateGameHasStarted;  // don't set this state if game is currently paused
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #GoMoveTypePass.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted
/// or #GoGameStateGameHasStarted.
// -----------------------------------------------------------------------------
- (void) pass
{
  if (GoGameStateGameHasNotYetStarted != self.state && GoGameStateGameHasStarted != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Pass is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted or GoGameStateGameHasStarted"
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePass by:self.currentPlayer after:self.lastMove];
  move.computerGenerated = self.nextMoveIsComputerGenerated;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // Game state must change after any of the other things; this order is
  // important for observer notifications
  if (move.previous.type == GoMoveTypePass)
  {
    self.reasonForGameHasEnded = GoGameHasEndedReasonTwoPasses;
    self.state = GoGameStateGameHasEnded;
  }
  else
  {
    if (GoGameStateGameHasNotYetStarted == self.state)
      self.state = GoGameStateGameHasStarted;  // don't set this state if game is currently paused
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players resigning the game.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted
/// or #GoGameStateGameHasStarted.
// -----------------------------------------------------------------------------
- (void) resign
{
  if (GoGameStateGameHasNotYetStarted != self.state && GoGameStateGameHasStarted != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Resign is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted or GoGameStateGameHasStarted"
                                                   userInfo:nil];
    @throw exception;
  }
  
  self.reasonForGameHasEnded = GoGameHasEndedReasonResigned;
  self.state = GoGameStateGameHasEnded;
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players taking back his move.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted, or if
/// there are no moves that can be taken back (typically because all moves have
/// already been taken back).
// -----------------------------------------------------------------------------
- (void) undo
{
  if (GoGameStateGameHasStarted != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Undo is possible only while GoGame object is in state GoGameStateGameHasStarted"
                                                   userInfo:nil];
    @throw exception;
  }
  if (! self.firstMove)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"No moves to undo"
                                                   userInfo:nil];
    @throw exception;
  }

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
  //   GoGameStateGameHasStarted
  // - But undoing a move will never cause the game to revert to state
  //   GoGameStateGameHasNotYetStarted
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
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted, or if
/// this GoGame object is not of type #GoGameTypeComputerVsComputer.
// -----------------------------------------------------------------------------
- (void) pause
{
  if (GoGameStateGameHasStarted != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Pause is possible only while GoGame object is in state GoGameStateGameHasStarted"
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoGameTypeComputerVsComputer != self.type)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Pause is possible only in a computer vs. computer game"
                                                   userInfo:nil];
    @throw exception;
  }

  self.state = GoGameStateGameIsPaused;
}

// -----------------------------------------------------------------------------
/// @brief Continues the game if it is paused while two computer players play
/// against each other.
///
/// Essentially, this method triggers the next computer player move.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameIsPaused, or if
/// this GoGame object is not of type #GoGameTypeComputerVsComputer.
// -----------------------------------------------------------------------------
- (void) continue
{
  if (GoGameStateGameIsPaused != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Continue is possible only while GoGame object is in state GoGameStateGameIsPaused"
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoGameTypeComputerVsComputer != self.type)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Continue is possible only in a computer vs. computer game"
                                                   userInfo:nil];
    @throw exception;
  }

  self.state = GoGameStateGameHasStarted;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a stone on the intersection represented by
/// @a point would be legal for the current player. This includes checking for
/// suicide moves and Ko situations.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil.
// -----------------------------------------------------------------------------
- (bool) isLegalMove:(GoPoint*)point
{
  if (! point)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

  // We could use the Fuego-specific GTP command "go_point_info" to obtain
  // the desired information, but parsing the response would require some
  // effort, is prone to fail when Fuego changes its response format, and
  // Fuego also does not tell us directly whether or not the point is protected
  // by a Ko, so we would have to derive this information from the other parts
  // of the response.
  // -> it's better to implement this in our own terms
  if ([point hasStone])
    return false;
  else if ([point liberties] > 0)
    return true;
  else
  {
    bool nextMoveIsBlack = self.currentPlayer.isBlack;
    bool isKoStillPossible = true;

    // Pass 1: Examine friendly colored neighbours
    NSArray* neighbours = point.neighbours;
    for (GoPoint* neighbour in neighbours)
    {
      if ([neighbour blackStone] != nextMoveIsBlack)
        continue;
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

    // Pass 2: Examine opposite colored neighbours
    for (GoPoint* neighbour in neighbours)
    {
      if ([neighbour blackStone] == nextMoveIsBlack)
        continue;
      // Can we capture the stone (or the group to which it belongs)? If not
      // then we can immediately examine the next neighbour.
      if ([neighbour liberties] > 1)
        continue;
      // Yes, we can capture the group. Now the only thing that can still make
      // the move illegal is a Ko. First check if a previous part of the logic
      // has already found that a Ko is no longer possible.
      if (! isKoStillPossible)
        return true;  // Ko is no longer possible, so the move is legal
      // A Ko is still possible. Next we check if the group we would like to
      // capture is larger than 1 stone. If it is it can't be a Ko, so the move
      // is legal.
      GoBoardRegion* neighbourRegion = neighbour.region;
      if ([neighbourRegion size] > 1)
        return true;
      // The group we would like to capture is just one stone. If that stone
      // was not placed in the previous move it can't be Ko and the move is
      // legal.
      GoPoint* lastMovePoint = self.lastMove.point;
      if (! lastMovePoint || ! [lastMovePoint isEqualToPoint:neighbour])
        return true;
      // The stone we would like to capture was placed in the previous move. If
      // that move captured a) a single stone, and b) that stone was located on
      // the point that we are currently examining, then we finally know that
      // it is Ko and that the move is illegal.
      NSArray* lastMoveCapturedStones = self.lastMove.capturedStones;
      if (1 == lastMoveCapturedStones.count && [lastMoveCapturedStones containsObject:point])
        return false;
      else
        return true;
    }

    // If we arrive here, no opposing stones can be captured and there are no
    // friendly groups with sufficient liberties to connect to
    // -> the move is a suicide and therefore illegal
    return false;
  }
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
  {
    if (0 == self.handicapPoints.count)
      return self.playerBlack;
    else
      return self.playerWhite;
  }
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

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setHandicapPoints:(NSArray*)newValue
{
  if (GoGameStateGameHasNotYetStarted != self.state)
  {
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:@"Handicap can only be set while GoGame object is in state GoGameStateGameHasNotYetStarted"
                                                   userInfo:nil];
    @throw exception;
  }
  if (! newValue)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Point list argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

  if ([handicapPoints isEqualToArray:newValue])
    return;

  // Reset previously set handicap points
  if (handicapPoints)
  {
    [handicapPoints autorelease];
    for (GoPoint* point in handicapPoints)
    {
      point.stoneState = GoColorNone;
      [GoUtilities movePointToNewRegion:point];
    }
  }

  handicapPoints = [newValue copy];
  if (handicapPoints)
  {
    for (GoPoint* point in handicapPoints)
    {
      point.stoneState = GoColorBlack;
      [GoUtilities movePointToNewRegion:point];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeInt:self.type forKey:goGameTypeKey];
  [encoder encodeObject:self.board forKey:goGameBoardKey];
  [encoder encodeObject:self.handicapPoints forKey:goGameHandicapPointsKey];
  [encoder encodeDouble:self.komi forKey:goGameKomiKey];
  [encoder encodeObject:self.playerBlack forKey:goGamePlayerBlackKey];
  [encoder encodeObject:self.playerWhite forKey:goGamePlayerWhiteKey];
  [encoder encodeObject:self.firstMove forKey:goGameFirstMoveKey];
  [encoder encodeObject:self.lastMove forKey:goGameLastMoveKey];
  [encoder encodeInt:self.state forKey:goGameStateKey];
  [encoder encodeInt:self.reasonForGameHasEnded forKey:goGameReasonForGameHasEndedKey];
  [encoder encodeBool:self.isComputerThinking forKey:goGameIsComputerThinkingKey];
  [encoder encodeBool:self.nextMoveIsComputerGenerated forKey:goGameNextMoveIsComputerGeneratedKey];
}

@end
