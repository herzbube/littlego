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
#import "GoBoardPosition.h"
#import "GoBoardRegion.h"
#import "GoMove.h"
#import "GoMoveModel.h"
#import "GoPlayer.h"
#import "GoPoint.h"
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
- (void) setComputerThinks:(bool)newValue;
//@}
@end


@implementation GoGame

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
  _type = GoGameTypeUnknown;
  _board = nil;
  _handicapPoints = [[NSArray array] retain];
  _komi = 0;
  _playerBlack = nil;
  _playerWhite = nil;
  _moveModel = [[GoMoveModel alloc] init];
  _state = GoGameStateGameHasNotYetStarted;
  _reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  _computerThinks = false;
  // Create GoBoardPosition after GoMoveModel because GoBoardPosition requires
  // GoMoveModel to be already around
  _boardPosition = [[GoBoardPosition alloc] initWithGame:self];

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
  _type = [decoder decodeIntForKey:goGameTypeKey];
  _board = [[decoder decodeObjectForKey:goGameBoardKey] retain];
  _handicapPoints = [[decoder decodeObjectForKey:goGameHandicapPointsKey] retain];
  _komi = [decoder decodeDoubleForKey:goGameKomiKey];
  _playerBlack = [[decoder decodeObjectForKey:goGamePlayerBlackKey] retain];
  _playerWhite = [[decoder decodeObjectForKey:goGamePlayerWhiteKey] retain];
  _moveModel = [[decoder decodeObjectForKey:goGameMoveModelKey] retain];
  _state = [decoder decodeIntForKey:goGameStateKey];
  _reasonForGameHasEnded = [decoder decodeIntForKey:goGameReasonForGameHasEndedKey];
  _computerThinks = [decoder decodeBoolForKey:goGameIsComputerThinkingKey];
  _boardPosition = [[decoder decodeObjectForKey:goGameBoardPositionKey] retain];

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
  if (_handicapPoints)
  {
    [_handicapPoints release];
    _handicapPoints = nil;
  }
  self.playerBlack = nil;
  self.playerWhite = nil;
  // Deallocate GoBoardPosition before GoMoveModel because GoBoardPosition
  // requires GoMoveModel to still be around
  self.boardPosition = nil;
  self.moveModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) firstMove
{
  return self.moveModel.firstMove;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) lastMove
{
  return self.moveModel.lastMove;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setState:(enum GoGameState)newValue
{
  if (_state == newValue)
    return;
  _state = newValue;
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
    NSString* errorMessage = @"Play is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted, GoGameStateGameHasStarted or GoGameStateGameIsPaused";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! aPoint)
  {
    NSString* errorMessage = @"Point argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! [self isLegalMove:aPoint])
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Point argument is not a legal move: %@", aPoint.vertex];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePlay by:self.currentPlayer after:self.lastMove];
  @try
  {
    move.point = aPoint;
  }
  @catch (NSException* exception)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Exception occurred while playing on intersection %@. Exception = %@", aPoint.vertex, exception];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* newException = [NSException exceptionWithName:NSInvalidArgumentException
                                                        reason:errorMessage
                                                      userInfo:nil];
    @throw newException;
  }

  [move doIt];
  [self.moveModel appendMove:move];

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
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted,
/// #GoGameStateGameHasStarted or #GoGameStateGameIsPaused.
// -----------------------------------------------------------------------------
- (void) pass
{
  if (GoGameStateGameHasNotYetStarted != self.state &&
      GoGameStateGameHasStarted != self.state &&
      GoGameStateGameIsPaused != self.state)
  {
    NSString* errorMessage = @"Pass is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted, GoGameStateGameHasStarted or GoGameStateGameIsPaused";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePass by:self.currentPlayer after:self.lastMove];

  [move doIt];
  [self.moveModel appendMove:move];

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
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted,
/// #GoGameStateGameHasStarted or #GoGameStateGameIsPaused.
// -----------------------------------------------------------------------------
- (void) resign
{
  if (GoGameStateGameHasNotYetStarted != self.state &&
      GoGameStateGameHasStarted != self.state &&
      GoGameStateGameIsPaused != self.state)
  {
    NSString* errorMessage = @"Resign is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted, GoGameStateGameHasStarted or GoGameStateGameIsPaused";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  
  self.reasonForGameHasEnded = GoGameHasEndedReasonResigned;
  self.state = GoGameStateGameHasEnded;
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
/// while this GoGame object is not in state #GoGameStateGameHasNotYetStarted
/// or #GoGameStateGameHasStarted, or if this GoGame object is not of type
/// #GoGameTypeComputerVsComputer.
// -----------------------------------------------------------------------------
- (void) pause
{
  if (GoGameStateGameHasNotYetStarted != self.state && GoGameStateGameHasStarted != self.state)
  {
    NSString* errorMessage = @"Pause is possible only while GoGame object is either in state GoGameStateGameHasNotYetStarted or GoGameStateGameHasStarted";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoGameTypeComputerVsComputer != self.type)
  {
    NSString* errorMessage = @"Pause is possible only in a computer vs. computer game";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
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
    NSString* errorMessage = @"Continue is possible only while GoGame object is in state GoGameStateGameIsPaused";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (GoGameTypeComputerVsComputer != self.type)
  {
    NSString* errorMessage = @"Continue is possible only in a computer vs. computer game";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  self.state = GoGameStateGameHasStarted;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a stone on the intersection represented by
/// @a point would be legal for the current player in the current board
/// position. This includes checking for suicide moves and Ko situations.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil.
// -----------------------------------------------------------------------------
- (bool) isLegalMove:(GoPoint*)point
{
  if (! point)
  {
    NSString* errorMessage = @"Point argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
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
    bool nextMoveIsBlack = self.boardPosition.currentPlayer.isBlack;
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
  return [GoUtilities playerAfter:self.lastMove inGame:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setComputerThinks:(bool)newValue
{
  if (_computerThinks == newValue)
    return;
  _computerThinks = newValue;
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
    NSString* errorMessage = @"Handicap can only be set while GoGame object is in state GoGameStateGameHasNotYetStarted";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! newValue)
  {
    NSString* errorMessage = @"Point list argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  if ([_handicapPoints isEqualToArray:newValue])
    return;

  // Reset previously set handicap points
  if (_handicapPoints)
  {
    [_handicapPoints autorelease];
    for (GoPoint* point in _handicapPoints)
    {
      point.stoneState = GoColorNone;
      [GoUtilities movePointToNewRegion:point];
    }
  }

  _handicapPoints = [newValue copy];
  if (_handicapPoints)
  {
    for (GoPoint* point in _handicapPoints)
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
  [encoder encodeObject:self.moveModel forKey:goGameMoveModelKey];
  [encoder encodeInt:self.state forKey:goGameStateKey];
  [encoder encodeInt:self.reasonForGameHasEnded forKey:goGameReasonForGameHasEndedKey];
  [encoder encodeBool:self.isComputerThinking forKey:goGameIsComputerThinkingKey];
  [encoder encodeObject:self.boardPosition forKey:goGameBoardPositionKey];
}

// -----------------------------------------------------------------------------
/// @brief Reverts the game from state #GoGameStateGameHasEnded to an
/// "in progress" state that is appropriate for the current game type.
///
/// If the game is a computer vs. computer game, the game state is reverted to
/// #GoGameStateGameIsPaused. All other game types are reverted to
/// #GoGameStateGameHasStarted.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasEnded.
///
/// @note This method should only be invoked if the state of other objects
/// associated with this GoGame is also adjusted to bring the game into a state
/// that conforms to the Go rules. For instance, if two pass moves caused the
/// game to end, then the most recent pass move should also be discarded after
/// control returns to the caller.
// -----------------------------------------------------------------------------
- (void) revertStateFromEndedToInProgress
{
  if (GoGameStateGameHasEnded != self.state)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Game state can only be reverted from GoGameStateGameHasEnded. Current game state = %d", self.state];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  self.reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  if (GoGameTypeComputerVsComputer == self.type)
    self.state = GoGameStateGameIsPaused;
  else
    self.state = GoGameStateGameHasStarted;
}

@end
