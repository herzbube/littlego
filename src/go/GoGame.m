// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/ApplicationDelegate.h"
#import "../player/Player.h"


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
  // (e.g. notifications are triggered, but also other stuff)
  _type = GoGameTypeUnknown;
  _board = nil;
  _rules = nil;
  _handicapPoints = [[NSArray array] retain];
  _komi = 0;
  _playerBlack = nil;
  _playerWhite = nil;
  _nextMoveColor = GoColorBlack;
  _alternatingPlay = true;
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
  // (e.g. notifications are triggered, but also other stuff)
  _type = [decoder decodeIntForKey:goGameTypeKey];
  _board = [[decoder decodeObjectForKey:goGameBoardKey] retain];
  _handicapPoints = [[decoder decodeObjectForKey:goGameHandicapPointsKey] retain];
  _komi = [decoder decodeDoubleForKey:goGameKomiKey];
  _playerBlack = [[decoder decodeObjectForKey:goGamePlayerBlackKey] retain];
  _playerWhite = [[decoder decodeObjectForKey:goGamePlayerWhiteKey] retain];
  _nextMoveColor = [decoder decodeIntForKey:goGameNextMoveColorKey];
  _alternatingPlay = ([decoder decodeBoolForKey:goGameAlternatingPlayKey] == YES);
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
/// response to the @e nextMovePlayer making a #GoMoveTypePlay.
///
/// Invoking this method sets the document dirty flag and, if alternating play
/// is enabled, switches the @e nextMovePlayer.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
///
/// @note Play when in paused state is allowed only because the computer
/// player who is thinking at the time the game is paused must be able to
/// finish its turn.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil, if playing on
/// @a aPoint is not a legal move, or if an exception occurs while actually
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
  enum GoMoveIsIllegalReason illegalReason;
  if (! [self isLegalMove:aPoint isIllegalReason:&illegalReason])
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Point argument is not a legal move: %@", aPoint.vertex];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePlay by:self.nextMovePlayer after:self.lastMove];
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
  // Sets the document dirty flag and, if alternating play is enabled, switches
  // the nextMovePlayer
  [self.moveModel appendMove:move];
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to the @e nextMovePlayer making a #GoMoveTypePass.
///
/// Invoking this method sets the document dirty flag and, if alternating play
/// is enabled, switches the @e nextMovePlayer.
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

  GoMove* move = [GoMove move:GoMoveTypePass by:self.nextMovePlayer after:self.lastMove];

  [move doIt];
  // Sets the document dirty flag and, if alternating play is enabled, switches
  // the nextMovePlayer
  [self.moveModel appendMove:move];

  // This may change the game state. Such a change must occur after the move was
  // generated; this order is important for observer notifications.
  [self endGameIfNecessary];
}

// -----------------------------------------------------------------------------
/// @brief Ends the game after at least two consecutive pass moves have been
/// made. Sets @e reasonForGameHasEnded according to the game rules.
///
/// This is a private helper for pass().
// -----------------------------------------------------------------------------
- (void) endGameIfNecessary
{
  int numberOfConsecutivePassMoves = 0;
  GoMove* potentialPassMove = self.lastMove;
  while (potentialPassMove && GoMoveTypePass == potentialPassMove.type)
  {
    ++numberOfConsecutivePassMoves;
    potentialPassMove = potentialPassMove.previous;
  }

  // GoFourPassesRuleFourPassesEndTheGame has precedence over
  // GoLifeAndDeathSettlingRuleTwoPasses
  if (4 == numberOfConsecutivePassMoves && GoFourPassesRuleFourPassesEndTheGame == self.rules.fourPassesRule)
  {
    self.reasonForGameHasEnded = GoGameHasEndedReasonFourPasses;
    self.state = GoGameStateGameHasEnded;
  }
  else if (3 == numberOfConsecutivePassMoves && GoLifeAndDeathSettlingRuleThreePasses == self.rules.lifeAndDeathSettlingRule)
  {
    self.reasonForGameHasEnded = GoGameHasEndedReasonThreePasses;
    self.state = GoGameStateGameHasEnded;
  }
  else if (0 == (numberOfConsecutivePassMoves % 2) && GoLifeAndDeathSettlingRuleTwoPasses == self.rules.lifeAndDeathSettlingRule)
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
/// move. If the game is still paused at that time, the second computer player's
/// move will not be triggered.
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
/// If one of the two computer players is still thinking and has not yet played
/// its move, continuing the game can be seen as "undo pause", i.e. it will be
/// as if pause() had never been invoked.
///
/// However, if none of two computer players is currently thinking, this method
/// triggers the next computer player move.
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
/// @a point would be legal for the @e nextMovePlayer in the current board
/// position. This includes checking for suicide moves and Ko situations, but
/// not for alternating play.
///
/// If this method returns false, the out parameter @a reason is filled with
/// the reason why the move is not legal. If this method returns true, the
/// value of @a reason is undefined.
///
/// Alternating play, if it is desired, must be enforced by the application
/// logic. This method simply assumes that the @e nextMovePlayer has the right
/// to move in the current board position.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil.
// -----------------------------------------------------------------------------
- (bool) isLegalMove:(GoPoint*)point isIllegalReason:(enum GoMoveIsIllegalReason*)reason
{
  return [self isLegalMove:point byColor:self.nextMoveColor isIllegalReason:reason];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a stone on the intersection represented by
/// @a point would be legal for the player who plays @a color in the current
/// board position. This includes checking for suicide moves and Ko situations,
/// but not for alternating play.
///
/// If this method returns false, the out parameter @a reason is filled with
/// the reason why the move is not legal. If this method returns true, the
/// value of @a reason is undefined.
///
/// Alternating play, if it is desired, must be enforced by the application
/// logic. This method simply assumes that the player who plays @a color has the
/// right to move in the current board position.
///
/// Raises @e NSInvalidArgumentException if @a aPoint is nil, or if @a color is
/// neither GoColorBlack nor GoColorWhite.
// -----------------------------------------------------------------------------
- (bool) isLegalMove:(GoPoint*)point byColor:(enum GoColor)color isIllegalReason:(enum GoMoveIsIllegalReason*)reason
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
  if (color != GoColorBlack && color != GoColorWhite)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Invalid color argument %d", color];
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
    *reason = GoMoveIsIllegalReasonIntersectionOccupied;
    return false;
  }
  // Point is an empty intersection, possibly with other empty intersections as
  // neighbours
  else if ([point liberties] > 0)
  {
    // Because the point has liberties a simple ko is not possible
    bool isSuperko;
    bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:false isSuperko:&isSuperko];
    if (isKoMove)
      *reason = isSuperko ? GoMoveIsIllegalReasonSuperko : GoMoveIsIllegalReasonSimpleKo;
    return !isKoMove;
  }
  // Point is an empty intersection that is surrounded by stones
  else
  {
    // Pass 1: Check if we can connect to a friendly colored stone group
    // without killing it
    NSArray* neighbourRegionsFriendly = [point neighbourRegionsWithColor:color];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsFriendly)
    {
      // If the friendly stone group has more than one liberty, we are sure that
      // we are not killing it. The only thing that can still make the move
      // illegal is a ko (but since we are connecting, a simple ko is not
      // possible here).
      if ([neighbourRegion liberties] > 1)
      {
        bool isSuperko;
        bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:false isSuperko:&isSuperko];
        if (isKoMove)
          *reason = isSuperko ? GoMoveIsIllegalReasonSuperko : GoMoveIsIllegalReasonSimpleKo;
        return !isKoMove;
      }
    }

    // Pass 2: Check if we can capture opposing stone groups
    enum GoColor opponentColor = (color == GoColorBlack ? GoColorWhite : GoColorBlack);
    NSArray* neighbourRegionsOpponent = [point neighbourRegionsWithColor:opponentColor];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsOpponent)
    {
      // If the opposing stone group has only one liberty left we can capture
      // it. The only thing that can still make the move illegal is a ko.
      if ([neighbourRegion liberties] == 1)
      {
        // A simple Ko situation is possible only if we are NOT connecting
        bool isSimpleKoStillPossible = (0 == neighbourRegionsFriendly.count);
        bool isSuperko;
        bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:isSimpleKoStillPossible isSuperko:&isSuperko];
        if (isKoMove)
          *reason = isSuperko ? GoMoveIsIllegalReasonSuperko : GoMoveIsIllegalReasonSimpleKo;
        return !isKoMove;
      }
    }

    // If we arrive here, no opposing stones can be captured and there are no
    // friendly groups with sufficient liberties to connect to
    // -> the move is a suicide and therefore illegal
    *reason = GoMoveIsIllegalReasonSuicide;
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if placing a stone at @a point by player @a moveColor
/// would violate the current ko rule of the game. Returns false if placing
/// such a stone would not violate the current ko rule of the game.
///
/// If this method returns true, it also fills the out parameter @a isSuperko
/// with true or false to distinguish ko from superko. If this method returns
/// false, the value of the out parameter @a isSuperko is undefined.
///
/// @note If the current ko rule is #GoKoRuleSimple this method does not check
/// for superko at all, so the out parameter @a isSuperko can never become true.
///
/// To optimize ko detection, the caller may set @a simpleKoIsPossible to false
/// if prior analysis has shown that placing a stone at @a point by player
/// @a moveColor is impossible to be a simple ko. If the current ko rule is
/// #GoKoRuleSimple and the caller sets @a simpleKoIsPossible to false, then
/// this method does not have to perform any ko detection at all! If the current
/// ko rule is not #GoKoRuleSimple (i.e. the ko rule allows superko), then no
/// optimization is possible.
///
/// This is a private helper for isLegalMove:byColor:isIllegalReason:().
// -----------------------------------------------------------------------------
- (bool) isKoMove:(GoPoint*)point
        moveColor:(enum GoColor)moveColor
simpleKoIsPossible:(bool)simpleKoIsPossible
        isSuperko:(bool*)isSuperko
{
  enum GoKoRule koRule = self.rules.koRule;
  if (GoKoRuleSimple == koRule && !simpleKoIsPossible)
    return false;

  // The algorithm below for finding ko can kick in only if we have at least
  // two moves. The earliest possible ko needs even more moves, but optimizing
  // the algorithm is not worth the trouble.
  GoMove* lastMove = self.lastMove;
  if (! lastMove)
    return false;
  GoMove* previousToLastMove = lastMove.previous;
  if (! previousToLastMove)
    return false;

  long long zobristHashOfHypotheticalMove = [self zobristHashOfHypotheticalMoveAtPoint:point byColor:moveColor];

  // Even if we use one of the superko rules, we still want to check for simple
  // ko first so that we can distinguish between simple ko and superko.
  bool isSimpleKo = (zobristHashOfHypotheticalMove == previousToLastMove.zobristHash);
  if (isSimpleKo)
  {
    *isSuperko = false;
    return true;
  }

  switch (koRule)
  {
    case GoKoRuleSimple:
    {
      // Simple Ko has already been checked above, so there's nothing else we
      // need to do here
      return false;
    }
    case GoKoRuleSuperkoPositional:
    case GoKoRuleSuperkoSituational:
    {
      for (GoMove* move = previousToLastMove.previous; move != nil; move = move.previous)
      {
        // Situational superko only examines board positions that resulted from
        // moves made by the same color
        if (GoKoRuleSuperkoSituational == koRule && move.player.color != moveColor)
            continue;
        if (zobristHashOfHypotheticalMove == move.zobristHash)
        {
          *isSuperko = true;
          return true;
        }
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
/// @brief Generates the Zobrist hash for a hypothetical move played by @a color
/// on the intersection @a point. The hypothetical move is played as if it
/// occurred after the current last move, i.e. after the move which created the
/// current board position.
///
/// This is a private helper for
/// isKoMove:moveColor:checkSuperkoOnly:isSuperko:().
// -----------------------------------------------------------------------------
- (long long) zobristHashOfHypotheticalMoveAtPoint:(GoPoint*)point
                                           byColor:(enum GoColor)color
{
  enum GoColor opponentColor = (color == GoColorBlack ? GoColorWhite : GoColorBlack);
  NSArray* stonesWithOneLiberty = [self stonesWithColor:opponentColor withSingleLibertyAt:point];
  return [self.board.zobristTable hashForStonePlayedByColor:color
                                                    atPoint:point
                                            capturingStones:stonesWithOneLiberty
                                                  afterMove:self.lastMove];
}

// -----------------------------------------------------------------------------
/// @brief Determines stone groups with color @a color that have only a single
/// liberty, and that liberty is at @a point. Returns an array with all GoPoint
/// objects that make up those regions. The array is empty if no such stone
/// groups exist. The array has no particular order.
///
/// This is a private helper.
///
/// This is a private helper for
/// zobristHashOfHypotheticalMoveAtPoint:byColor:().
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
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setNextMoveColor:(enum GoColor)nextMoveColor
{
  if (_nextMoveColor == nextMoveColor)
    return;
  switch (nextMoveColor)
  {
    case GoColorBlack:
    case GoColorWhite:
    {
      _nextMoveColor = nextMoveColor;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid color %d", nextMoveColor];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoPlayer*) nextMovePlayer
{
  if (GoColorBlack == self.nextMoveColor)
    return self.playerBlack;
  else if (GoColorWhite == self.nextMoveColor)
    return self.playerWhite;
  else
    return nil;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) nextMovePlayerIsComputerPlayer
{
  return (! self.nextMovePlayer.player.isHuman);
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

  if (_handicapPoints && 0 == _handicapPoints.count)
    self.nextMoveColor = GoColorBlack;
  else
    self.nextMoveColor = GoColorWhite;
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
  [encoder encodeInt:self.nextMoveColor forKey:goGameNextMoveColorKey];
  [encoder encodeBool:(self.alternatingPlay ? YES : NO) forKey:goGameAlternatingPlayKey];
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
/// that conforms to the Go rules. For instance, if three pass moves caused the
/// game to end, then the most recent pass move should also be discarded after
/// control returns to the caller.
///
/// If the game has ended due to resignation, invoking this method sets the
/// document dirty flag. This behaviour exists to remain consistent with the
/// resignation action, which also sets the document dirty flag. If the game
/// ended for some reason other than resigning, it is expected that some other
/// action in addition to invoking revertStateFromEndedToInProgress will cause
/// the document dirty flag to be set. For instance, if three pass moves caused
/// the game to end, then the document dirty flag needs to be reset by
/// discarding the third pass move.
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

// -----------------------------------------------------------------------------
/// @brief Switches @e nextMoveColor from #GoColorBlack to #GoColorWhite, or
/// vice versa.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while @e nextMoveColor is neither #GoColorBlack nor #GoColorWhite.
// -----------------------------------------------------------------------------
- (void) switchNextMoveColor
{
  switch (self.nextMoveColor)
  {
    case GoColorBlack:
    {
      self.nextMoveColor = GoColorWhite;
      break;
    }
    case GoColorWhite:
    {
      self.nextMoveColor = GoColorBlack;
      break;
    }
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Next move color can only be changed if it is either black or white. Current next move color  = %d", self.nextMoveColor];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
