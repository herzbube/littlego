// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoBoardPosition.h"
#import "GoBoardRegion.h"
#import "GoGameDocument.h"
#import "GoGameRules.h"
#import "GoMove.h"
#import "GoMoveModel.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "GoScore.h"
#import "GoUtilities.h"
#import "GoZobristTable.h"
#import "../player/Player.h"
#import "../main/ApplicationDelegate.h"


@implementation GoGame

// -----------------------------------------------------------------------------
/// @brief Returns the shared GoGame object that represents the current game.
// -----------------------------------------------------------------------------
+ (GoGame*) sharedGame;
{
  return [ApplicationDelegate sharedDelegate].game;
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
  _rules = nil;
  _handicapPoints = [[NSArray array] retain];
  _komi = 0;
  _playerBlack = nil;
  _playerWhite = nil;
  _moveModel = [[GoMoveModel alloc] initWithGame:self];
  _state = GoGameStateGameHasStarted;
  _reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  _reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
  // Create GoBoardPosition after GoMoveModel because GoBoardPosition requires
  // GoMoveModel to be already around
  _boardPosition = [[GoBoardPosition alloc] initWithGame:self];
  _rules = [[GoGameRules alloc] init];
  _document = [[GoGameDocument alloc] init];
  _score = [[GoScore alloc] initWithGame:self];
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
  _reasonForComputerIsThinking = [decoder decodeIntForKey:goGameReasonForComputerIsThinking];
  _boardPosition = [[decoder decodeObjectForKey:goGameBoardPositionKey] retain];
  _rules = [[decoder decodeObjectForKey:goGameRulesKey] retain];
  _document = [[decoder decodeObjectForKey:goGameDocumentKey] retain];
  _score = [[decoder decodeObjectForKey:goGameScoreKey] retain];

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
  self.rules = nil;
  self.document = nil;
  self.score = nil;
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
/// Invoking this method sets the document dirty flag.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
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
  if (GoGameStateGameHasStarted != self.state && GoGameStateGameIsPaused != self.state)
  {
    NSString* errorMessage = @"Play is possible only while GoGame object is either in state GoGameStateGameHasStarted or GoGameStateGameIsPaused";
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
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players making a #GoMoveTypePass.
///
/// Invoking this method sets the document dirty flag.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
// -----------------------------------------------------------------------------
- (void) pass
{
  if (GoGameStateGameHasStarted != self.state && GoGameStateGameIsPaused != self.state)
  {
    NSString* errorMessage = @"Pass is possible only while GoGame object is either in state GoGameStateGameHasStarted or GoGameStateGameIsPaused";
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
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to one of the players resigning the game.
///
/// Invoking this method sets the document dirty flag.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
// -----------------------------------------------------------------------------
- (void) resign
{
  if (GoGameStateGameHasStarted != self.state && GoGameStateGameIsPaused != self.state)
  {
    NSString* errorMessage = @"Resign is possible only while GoGame object is either in state GoGameStateGameHasStarted or GoGameStateGameIsPaused";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  // At the time of implementing this, setting the dirty flag in reaction to
  // resigning the game is not strictly necessary, since saving the game will,
  // at the moment, NOT store the resignation status in the .sgf file. This is
  // either a bug in Fuego, or a limitation in the SGF file format - which one
  // it is still needs to be researched. Nevertheless, the dirty flag is set
  // to remain conceptually correct.
  self.document.dirty = true;

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
/// while this GoGame object is not in state #GoGameStateGameHasStarted, or if
/// this GoGame object is not of type #GoGameTypeComputerVsComputer.
// -----------------------------------------------------------------------------
- (void) pause
{
  if (GoGameStateGameHasStarted != self.state)
  {
    NSString* errorMessage = @"Pause is possible only while GoGame object is either in state GoGameStateGameHasStarted";
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
  {
    return false;
  }
  // Point is an empty intersection, possibly with other empty intersections as
  // neighbours
  else if ([point liberties] > 0)
  {
    return ![self isKoMove:point checkSuperkoOnly:true];
  }
  // Point is an empty intersection that is surrounded by stones
  else
  {
    bool nextMoveIsBlack = self.boardPosition.currentPlayer.isBlack;
    enum GoColor nextMoveColor = (nextMoveIsBlack ? GoColorBlack : GoColorWhite);
    enum GoColor nextMoveOpponentColor = (nextMoveIsBlack ? GoColorWhite : GoColorBlack);

    // Pass 1: Check if we can connect to a friendly colored stone group
    // without killing it
    NSArray* neighbourRegionsFriendly = [point neighbourRegionsWithColor:nextMoveColor];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsFriendly)
    {
      // If the friendly stone group has more than one liberty, we are sure that
      // we are not killing it. The only thing that can still make the move
      // illegal is a ko (but since we are connecting, a simple ko is not
      // possible here).
      if ([neighbourRegion liberties] > 1)
      {
        return ![self isKoMove:point checkSuperkoOnly:true];
      }
    }

    // Pass 2: Check if we can capture opposing stone groups
    NSArray* neighbourRegionsOpponent = [point neighbourRegionsWithColor:nextMoveOpponentColor];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsOpponent)
    {
      // If the opposing stone group has only one liberty left we can capture
      // it. The only thing that can still make the move illegal is a ko.
      if ([neighbourRegion liberties] == 1)
      {
        // A simple Ko situation is possible only if we are NOT connecting
        bool isSimpleKoStillPossible = (0 == neighbourRegionsFriendly.count);
        return ![self isKoMove:point checkSuperkoOnly:!isSimpleKoStillPossible];
      }
    }

    // If we arrive here, no opposing stones can be captured and there are no
    // friendly groups with sufficient liberties to connect to
    // -> the move is a suicide and therefore illegal
    return false;
  }
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (bool) isKoMove:(GoPoint*)point checkSuperkoOnly:(bool)checkSuperkoOnly
{
  enum GoKoRule koRule = self.rules.koRule;
  if (checkSuperkoOnly && GoKoRuleSimple == koRule)
    return false;

  GoMove* lastMove = self.lastMove;
  long long zobristHashOfHypotheticalMove = [self zobristHashOfHypotheticalMoveAtPoint:point];
  switch (koRule)
  {
    case GoKoRuleSimple:
    {
      GoMove* previousMoveOfSamePlayer;
      if (lastMove)
        previousMoveOfSamePlayer = lastMove.previous;
      if (! previousMoveOfSamePlayer)
        return false;
      return (zobristHashOfHypotheticalMove == previousMoveOfSamePlayer.zobristHash);
    }
    case GoKoRuleSuperkoPositional:
    case GoKoRuleSuperkoSituational:
    {
      GoPlayer* currentPlayer = self.currentPlayer;
      for (GoMove* move = lastMove; move != nil; move = move.previous)
      {
        if (GoKoRuleSuperkoSituational == koRule && move.player != currentPlayer)
            continue;
        if (zobristHashOfHypotheticalMove == move.zobristHash)
          return true;
      }
      return false;
    }
    default:
    {
      NSString* errorMessage = @"Unrecognized ko rule";
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSGenericException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (long long) zobristHashOfHypotheticalMoveAtPoint:(GoPoint*)point
{
  GoPlayer* currentPlayer = self.currentPlayer;
  bool nextMoveIsBlack = currentPlayer.isBlack;
  enum GoColor nextMoveOpponentColor = (nextMoveIsBlack ? GoColorWhite : GoColorBlack);
  NSArray* stonesWithOneLiberty = [self stonesWithColor:nextMoveOpponentColor withSingleLibertyAt:point];
  return [self.board.zobristTable hashForStonePlayedBy:currentPlayer
                                               atPoint:point
                                       capturingStones:stonesWithOneLiberty
                                             afterMove:self.lastMove];
}

// -----------------------------------------------------------------------------
/// Private helper
// -----------------------------------------------------------------------------
- (NSArray*) stonesWithColor:(enum GoColor)color withSingleLibertyAt:(GoPoint*)point
{
  NSMutableArray* stonesWithSingleLiberty = [NSMutableArray arrayWithCapacity:0];
  NSArray* neighbourRegionsOpponent = [point neighbourRegionsWithColor:color];
  for (GoBoardRegion* neighbourRegion in neighbourRegionsOpponent)
  {
    if ([neighbourRegion liberties] == 1)
      [stonesWithSingleLiberty addObjectsFromArray:neighbourRegion.points];
  }
  return stonesWithSingleLiberty;
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
- (bool) isComputerThinking
{
  return (GoGameComputerIsThinkingReasonIsNotThinking != _reasonForComputerIsThinking);
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setReasonForComputerIsThinking:(enum GoGameComputerIsThinkingReason)newValue
{
  if (_reasonForComputerIsThinking == newValue)
    return;
  _reasonForComputerIsThinking = newValue;
  NSString* notificationName;
  if (GoGameComputerIsThinkingReasonIsNotThinking == newValue)
    notificationName = computerPlayerThinkingStops;
  else
    notificationName = computerPlayerThinkingStarts;
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setHandicapPoints:(NSArray*)newValue
{
  if (GoGameStateGameHasStarted != self.state || nil != self.firstMove)
  {
    NSString* errorMessage = @"Handicap can only be set while GoGame object is in state GoGameStateGameHasStarted and has no moves";
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
  [encoder encodeInt:self.reasonForComputerIsThinking forKey:goGameReasonForComputerIsThinking];
  [encoder encodeObject:self.boardPosition forKey:goGameBoardPositionKey];
  [encoder encodeObject:self.rules forKey:goGameRulesKey];
  [encoder encodeObject:self.document forKey:goGameDocumentKey];
  [encoder encodeObject:self.score forKey:goGameScoreKey];
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
///
/// If the game has ended due to resignation, invoking this method sets the
/// document dirty flag. This behaviour exists to remain consistent with the
/// resignation action, which also sets the document dirty flag. If the game
/// ended for some reason other than resigning, it is expected that some other
/// action in addition to invoking revertStateFromEndedToInProgress will cause
/// the document dirty flag to be set. For instance, if two pass moves caused
/// the game to end, then the document dirty flag needs to be reset by
/// discarding the second pass move.
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

  if (GoGameHasEndedReasonResigned == self.reasonForGameHasEnded)
    self.document.dirty = true;

  self.reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  if (GoGameTypeComputerVsComputer == self.type)
    self.state = GoGameStateGameIsPaused;
  else
    self.state = GoGameStateGameHasStarted;
}

@end
