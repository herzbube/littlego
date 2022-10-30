// -----------------------------------------------------------------------------
// Copyright 2011-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNode.h"
#import "GoNodeModel.h"
#import "GoNodeSetup.h"
#import "GoPlayer.h"
#import "GoPoint.h"
#import "GoScore.h"
#import "GoUtilities.h"
#import "GoVertex.h"
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
  _nodeModel = [[GoNodeModel alloc] initWithGame:self];
  _state = GoGameStateGameHasStarted;
  _reasonForGameHasEnded = GoGameHasEndedReasonNotYetEnded;
  _reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
  // Create GoBoardPosition after GoNodeModel because GoBoardPosition requires
  // GoNodeModel to be already around
  _boardPosition = [[GoBoardPosition alloc] initWithGame:self];
  _rules = [[GoGameRules alloc] init];
  _document = [[GoGameDocument alloc] init];
  _score = [[GoScore alloc] initWithGame:self];
  self.setupFirstMoveColor = GoColorNone;
  _zobristHashAfterHandicap = 0;

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
  _nodeModel = [[decoder decodeObjectForKey:goGameNodeModelKey] retain];
  _state = [decoder decodeIntForKey:goGameStateKey];
  _reasonForGameHasEnded = [decoder decodeIntForKey:goGameReasonForGameHasEndedKey];
  _reasonForComputerIsThinking = [decoder decodeIntForKey:goGameReasonForComputerIsThinking];
  _boardPosition = [[decoder decodeObjectForKey:goGameBoardPositionKey] retain];
  _rules = [[decoder decodeObjectForKey:goGameRulesKey] retain];
  _document = [[decoder decodeObjectForKey:goGameDocumentKey] retain];
  _score = [[decoder decodeObjectForKey:goGameScoreKey] retain];
  self.setupFirstMoveColor = [decoder decodeIntForKey:goGameSetupFirstMoveColorKey];
  // The hash was not archived. Whoever is unarchiving this GoGame is
  // responsible for re-calculating the hash.
  _zobristHashAfterHandicap = 0;

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
  // Deallocate GoBoardPosition before GoNodeModel because GoBoardPosition
  // requires GoNodeModel to still be around
  self.boardPosition = nil;
  self.nodeModel = nil;
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
  // The root node cannot contain a move, therefore it is ok to use GoUtilities
  GoNode* nodeWithNextMove = [GoUtilities nodeWithNextMove:self.nodeModel.rootNode inCurrentGameVariation:self];
  if (nodeWithNextMove)
    return nodeWithNextMove.goMove;
  else
    return nil;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (GoMove*) lastMove
{
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:self.nodeModel.leafNode];
  if (nodeWithMostRecentMove)
    return nodeWithMostRecentMove.goMove;
  else
    return nil;
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
/// Invoking this method has the following effects:
/// - Sets the document dirty flag
/// - If alternating play is enabled, switches the @e nextMovePlayer.
/// - Advances the current board position to display the board position after
///   the move was played. Posts first #numberOfBoardPositionsDidChange then
///   #currentBoardPositionDidChange to the default notification center.
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
    NSString* errorMessage = [NSString stringWithFormat:@"Exception occurred while playing on intersection %@. Exception = %@", aPoint.vertex.string, exception];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* newException = [NSException exceptionWithName:NSInvalidArgumentException
                                                        reason:errorMessage
                                                      userInfo:nil];
    @throw newException;
  }

  GoNode* node = [GoNode nodeWithMove:move];
  [self addNodeToTreeAndUpdateBoardPosition:node];
}

// -----------------------------------------------------------------------------
/// @brief Updates the state of this GoGame and all associated objects in
/// response to the @e nextMovePlayer making a #GoMoveTypePass.
///
/// Invoking this method has the following effects:
/// - Sets the document dirty flag
/// - If alternating play is enabled, switches the @e nextMovePlayer.
/// - Advances the current board position to display the board position after
///   the move was played. Posts first #numberOfBoardPositionsDidChange then
///   #currentBoardPositionDidChange to the default notification center.
/// - May cause the game state to change to #GoGameStateGameHasEnded if, after
///   playing this pass move, the right number of consecutive pass moves have
///   been made according to the game rules.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
///
/// Raises @e NSInvalidArgumentException if playing a #GoMoveTypePass by
/// @e nextMovePlayer is not a legal move.
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
  enum GoMoveIsIllegalReason illegalReason;
  if (! [self isLegalPassMoveIllegalReason:&illegalReason])
  {
    NSString* errorMessage = @"Passing is not a legal move";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoMove* move = [GoMove move:GoMoveTypePass by:self.nextMovePlayer after:self.lastMove];

  GoNode* node = [GoNode nodeWithMove:move];
  [self addNodeToTreeAndUpdateBoardPosition:node];

  // This may change the game state. Such a change must occur after the move was
  // generated; this order is important for observer notifications.
  [self endGameDueToPassMovesIfGameRulesRequireIt];
}

// -----------------------------------------------------------------------------
/// @brief Adds @a newNode to the game tree, then updates the GoBoardPosition
/// properties @e numberOfBoardPositions and @e currentBoardPosition. Posts the
/// corresponding notifications (first #numberOfBoardPositionsDidChange,
/// followed by #currentBoardPositionDidChange), to the default notification
/// center.
///
/// This is a private helper for play:() and pass().
// -----------------------------------------------------------------------------
- (void) addNodeToTreeAndUpdateBoardPosition:(GoNode*)newNode
{
  // Sets the document dirty flag and, if alternating play is enabled, switches
  // the nextMovePlayer
  [self.nodeModel appendNode:newNode];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];

  int oldNumberOfBoardPositions = self.boardPosition.numberOfBoardPositions;
  int newNumberOfBoardPositions = self.nodeModel.numberOfNodes;
  self.boardPosition.numberOfBoardPositions = newNumberOfBoardPositions;
  [center postNotificationName:numberOfBoardPositionsDidChange object:@[[NSNumber numberWithInt:oldNumberOfBoardPositions], [NSNumber numberWithInt:newNumberOfBoardPositions]]];

  // Changing the current board position invokes GoNode modifyBoard for us.
  // Important: GoNode modifyBoard must be invoked only AFTER the node was added
  // to the node tree, otherwise the Zobrist hash (which is based on the
  // previous node) cannot be calculated.
  int oldCurrentBoardPosition = self.boardPosition.currentBoardPosition;
  int newCurrentBoardPosition = self.nodeModel.numberOfNodes - 1;
  self.boardPosition.currentBoardPosition = newCurrentBoardPosition;
  [center postNotificationName:currentBoardPositionDidChange object:@[[NSNumber numberWithInt:oldCurrentBoardPosition], [NSNumber numberWithInt:newCurrentBoardPosition]]];
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

  self.document.dirty = true;

  if (self.nextMoveColor == GoColorBlack)
    self.reasonForGameHasEnded = GoGameHasEndedReasonWhiteWinsByResignation;
  else
    self.reasonForGameHasEnded = GoGameHasEndedReasonBlackWinsByResignation;
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
/// @brief Returns true if changing the stone state of @a point to @a stoneState
/// during board setup would be legal. This includes checking for suicide
/// positions, but not for Ko situations or alternating play, because these
/// things do not exist during board setup.
///
/// If this method returns false, the out parameter @a reason is filled with
/// the reason why changing the stone state of @a point is not legal. If this
/// method returns true, the value of @a reason is undefined.
///
/// If this method returns false and @a reason specifies that a stone or stone
/// group would be made illegal by placing the setup stone, then the out
/// parameter @a illegalStoneOrGroupPoint identifies the stone or stone group.
/// Otherwise the value of @a illegalStoneOrGroupPoint is undefined.
///
/// Raises @e NSInvalidArgumentException if @a point is nil.
// -----------------------------------------------------------------------------
- (bool) isLegalBoardSetupAt:(GoPoint*)point
              withStoneState:(enum GoColor)stoneState
             isIllegalReason:(enum GoBoardSetupIsIllegalReason*)reason
  createsIllegalStoneOrGroup:(GoPoint**)illegalStoneOrGroupPoint
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
  // TODO xxx Why this check? Why not let the caller check GoColorNone? (it would always return true)
  if (stoneState != GoColorBlack && stoneState != GoColorWhite)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Invalid stoneState argument %d", stoneState];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  enum GoColor friendlyColor = stoneState;
  enum GoColor opponentColor = (friendlyColor == GoColorBlack ? GoColorWhite : GoColorBlack);

  // Caller wants to remove a stone - this is always legal because removing a
  // stone creates liberties
  if (stoneState == GoColorNone)
  {
    assert([point hasStone]);
    return true;
  }
  // Point is an already occupied intersection and caller wants to place a
  // stone on it
  else if ([point hasStone])
  {
    // Caller wants to place a stone of the same color
    if (point.stoneState == stoneState)
    {
      return true;
    }
    // Caller wants to change the stone color
    else
    {
      // If the stone that is about to change its color is a connecting stone,
      // the stone group will be split up into two or even more sub-groups.
      // Check if this is the case, and (if it is) if the split is cutting off
      // one of the sub-groups from all liberties.
      NSMutableArray* suicidalSubgroup = [NSMutableArray arrayWithCapacity:0];
      if ([point.region isStoneConnectingSuicidalSubgroups:point suicidalSubgroup:suicidalSubgroup])
      {
        // If the suicidal sub-group has the same size as the region, minus the
        // connecting stone, then the connecting stone is not really connecting
        // sub-groups. Instead it is the single remaining connection of the
        // stone group to a liberty. Changing the connecting stone's color
        // removes that connection and effectively takes away the liberties from
        // the entire remaining stone group.
        if ((point.region.size - 1) == suicidalSubgroup.count)
          *reason = GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup;
        else
          *reason = GoBoardSetupIsIllegalReasonSuicideOpposingColorSubgroup;
        *illegalStoneOrGroupPoint = suicidalSubgroup[0];
        return false;
      }

      // We now know that we are not killing an opposing stone group. We now
      // have to check whether the stone about to change its color can survive.

      // Check if the point has at least one neighbouring empty intersection
      NSArray* neighbourRegionsEmpty = [point neighbourRegionsWithColor:GoColorNone];
      if (neighbourRegionsEmpty.count > 0)
      {
        // Yes there is at least one empty intersection which provides us with
        // one liberty.
        return true;
      }

      // The point is entirely surrounded by stones. Check if we can connect to
      // a friendly colored stone group.
      NSArray* neighbourRegionsFriendly = [point neighbourRegionsWithColor:friendlyColor];
      if (neighbourRegionsFriendly.count > 0)
      {
        // We don't have to check for friendly stone groups' liberties because
        // since we don't allow suicidal groups we know that they must have at
        // least one liberty. We also know that we don't take away that liberty
        // because we don't place a new stone - we only change the color of an
        // already existing stone. This might even create a liberty for a stone
        // group that we connect to.
        return true;
      }

      // We cannot connect to a friendly colored stone group, and there are no
      // neighbouring empty intersections. The point is therefore surrounded by
      // opposing stones.
      *reason = GoBoardSetupIsIllegalReasonSuicideSetupStone;
      *illegalStoneOrGroupPoint = point;
      return false;
    }
  }
  // Point is an empty intersection and caller wants to place a stone on it.
  // This is taking away a liberty from neighbouring stones, just like with
  // normal play.
  else
  {
    // Check if we are about to kill an opposing stone group
    NSArray* neighbourRegionsOpponent = [point neighbourRegionsWithColor:opponentColor];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsOpponent)
    {
      if ([neighbourRegion liberties] == 1)
      {
        if (neighbourRegion.points.count == 1)
          *reason = GoBoardSetupIsIllegalReasonSuicideOpposingStone;
        else
          *reason = GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup;
        *illegalStoneOrGroupPoint = neighbourRegion.points[0];;
        return false;
      }
    }

    // We now know that we are not killing an opposing stone group. We now
    // have to check whether the stone about to be placed can survive.

    // Check if the point has at least one neighbouring empty intersection
    if ([point liberties] > 0)
      return true;

    // The point is an empty intersection that is entirely surrounded by stones.
    // Check if we can connect to a friendly colored stone group without
    // killing it.
    NSArray* neighbourRegionsFriendly = [point neighbourRegionsWithColor:friendlyColor];
    for (GoBoardRegion* neighbourRegion in neighbourRegionsFriendly)
    {
      if ([neighbourRegion liberties] > 1)
        return true;
    }

    // We cannot connect to a friendly colored stone group (or we can connect
    // but would kill the friendly colored stone group) and there are no
    // neighbouring empty intersections. The point is therefore surrounded by
    // opposing stones or friendly stones with insufficient liberties.
    if (neighbourRegionsFriendly.count > 0)
    {
      *reason = GoBoardSetupIsIllegalReasonSuicideFriendlyStoneGroup;
      GoBoardRegion* aFriendlyNeighbourRegion = neighbourRegionsFriendly[0];
      *illegalStoneOrGroupPoint = aFriendlyNeighbourRegion.points[0];
    }
    else
    {
      *reason = GoBoardSetupIsIllegalReasonSuicideSetupStone;
      *illegalStoneOrGroupPoint = point;
    }

    return false;
  }
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
/// neither #GoColorBlack nor #GoColorWhite.
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

  // IMPORTANT: The node we find here is re-used below for Ko detection. Ko
  // detection must be based on the current board position, so we must not
  // use self.lastMove!
  // ALSO IMPORTANT: The current board position's node might be a non-move node,
  // so we have to search through the variation backwards until we find a move.
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:self.boardPosition.currentNode];
  if (nodeWithMostRecentMove)
  {
    if (nodeWithMostRecentMove.goMove.moveNumber == maximumNumberOfMoves)
    {
      *reason = GoMoveIsIllegalReasonTooManyMoves;
      return false;
    }
  }

  // Point is an empty intersection with at least one other empty intersection
  // as neighbour
  if ([point liberties] > 0)
  {
    // Because the point has liberties a simple ko is not possible
    bool isSuperko;
    bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:false isSuperko:&isSuperko nodeWithMostRecentMove:nodeWithMostRecentMove];
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
        bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:false isSuperko:&isSuperko nodeWithMostRecentMove:nodeWithMostRecentMove];
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
        bool isKoMove = [self isKoMove:point moveColor:color simpleKoIsPossible:isSimpleKoStillPossible isSuperko:&isSuperko nodeWithMostRecentMove:nodeWithMostRecentMove];
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
/// This ko detection routine is based on the current board position!
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
nodeWithMostRecentMove:(GoNode*)nodeWithMostRecentMove
{
  enum GoKoRule koRule = self.rules.koRule;
  if (GoKoRuleSimple == koRule && !simpleKoIsPossible)
    return false;

  // The algorithm below for finding ko can kick in only if we have at least
  // two moves: A real move that was already played, and the hypothetical move
  // for which we are performing ko detection. For normal play without setup
  // stones, the earliest possible ko needs even more moves, but with setup
  // stones a ko is already possible in the second move.
  if (! nodeWithMostRecentMove)
    return false;

  long long zobristHashOfHypotheticalMove = [self zobristHashOfHypotheticalMoveAtPoint:point
                                                                               byColor:moveColor
                                                                             afterNode:nodeWithMostRecentMove];

  GoNode* nodeWithPreviousToMostRecentMove = [GoUtilities nodeWithMostRecentMove:nodeWithMostRecentMove.parent];

  long long zobristHashOfPreviousToLastBoardPosition;
  if (nodeWithPreviousToMostRecentMove)
    zobristHashOfPreviousToLastBoardPosition = nodeWithPreviousToMostRecentMove.zobristHash;
  else
    zobristHashOfPreviousToLastBoardPosition = self.zobristHashAfterHandicap;

  // Even if we use one of the superko rules, we still want to check for simple
  // ko first so that we can distinguish between simple ko and superko.
  bool isSimpleKo = (zobristHashOfHypotheticalMove == zobristHashOfPreviousToLastBoardPosition);
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
      // The zobrist hash of the board position with the previous-to-last move
      // has already been examined by the Simple Ko check above, so if there are
      // no additional moves there's nothing else we need to do here
      if (! nodeWithPreviousToMostRecentMove)
        return false;

      for (GoNode* node = [GoUtilities nodeWithMostRecentMove:nodeWithPreviousToMostRecentMove.parent];
           node != nil;
           node = [GoUtilities nodeWithMostRecentMove:node.parent])
      {
        // Situational superko only examines board positions that resulted from
        // moves made by the same color
        if (GoKoRuleSuperkoSituational == koRule && node.goMove.player.color != moveColor)
            continue;

        if (zobristHashOfHypotheticalMove == node.zobristHash)
        {
          *isSuperko = true;
          return true;
        }
      }

      // Situational superko only examines board positions that resulted from
      // moves made by the same color. But which color did the board position
      // prior to the first move result from? The only possible answer can be:
      // The opposing color of the first move. There are two ways how to
      // determine the color of the first move:
      // - Find out which color a logical first move would have had, i.e.
      //   without looking at the actually played first move. The color of the
      //   logical first move is this:
      //   - self.setupFirstMoveColor, if it is not GoColorNone
      //   - GoColorBlack, if handicap is 0
      //   - GoColorWhite, if handicap is >0
      // - Look at the first move as it was actually played. If we think about
      //   what's possible in an .sgf file, we see that the first move can be
      //   any color - even if it defies the game logic (handicap) or
      //   contradicts the .sgf file's own data (first move color is != setup
      //   player color).
      // Both approaches have their merits, but to be on the safe side we
      // choose the same implementation as Fuego: Look at the first move as it
      // was actually played.
      if (GoKoRuleSuperkoSituational == koRule)
      {
        enum GoColor colorOfZobristHashAfterHandicap =
          [GoUtilities alternatingColorForColor:self.firstMove.player.color];
        if (colorOfZobristHashAfterHandicap != moveColor)
          return false;
      }

      if (zobristHashOfHypotheticalMove == self.zobristHashAfterHandicap)
      {
        *isSuperko = true;
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
/// @brief Generates the Zobrist hash for a hypothetical move played by @a color
/// on the intersection @a point, after the previous move @a move.
///
/// This is a private helper for
/// isKoMove:moveColor:checkSuperkoOnly:isSuperko:().
// -----------------------------------------------------------------------------
- (long long) zobristHashOfHypotheticalMoveAtPoint:(GoPoint*)point
                                           byColor:(enum GoColor)color
                                         afterNode:(GoNode*)node
{
  enum GoColor opponentColor = (color == GoColorBlack ? GoColorWhite : GoColorBlack);
  NSArray* stonesWithOneLiberty = [self stonesWithColor:opponentColor withSingleLibertyAt:point];
  return [self.board.zobristTable hashForStonePlayedByColor:color
                                                    atPoint:point
                                            capturingStones:stonesWithOneLiberty
                                                  afterNode:node
                                                     inGame:self];
}

// -----------------------------------------------------------------------------
/// @brief Determines stone groups with color @a color that have only a single
/// liberty, and that liberty is at @a point. Returns an array with all GoPoint
/// objects that make up those regions. The array is empty if no such stone
/// groups exist. The array has no particular order.
///
/// This is a private helper for
/// zobristHashOfHypotheticalMoveAtPoint:byColor:afterNode:().
// -----------------------------------------------------------------------------
- (NSArray*) stonesWithColor:(enum GoColor)color withSingleLibertyAt:(GoPoint*)point
{
  NSMutableArray* stonesWithSingleLiberty = [NSMutableArray arrayWithCapacity:0];
  // The array we get is guaranteed to have no duplicates
  NSArray* neighbourRegionsOpponent = [point neighbourRegionsWithColor:color];
  for (GoBoardRegion* neighbourRegion in neighbourRegionsOpponent)
  {
    if ([neighbourRegion liberties] == 1)
      [stonesWithSingleLiberty addObjectsFromArray:neighbourRegion.points];
  }
  return stonesWithSingleLiberty;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a pass move would be legal for the
/// @e nextMovePlayer in the current board position. This does not include
/// checking for alternating play.
///
/// If this method returns false, the out parameter @a reason is filled with
/// the reason why the move is not legal. If this method returns true, the
/// value of @a reason is undefined.
///
/// Alternating play, if it is desired, must be enforced by the application
/// logic. This method simply assumes that the @e nextMovePlayer has the right
/// to move in the current board position.
// -----------------------------------------------------------------------------
- (bool) isLegalPassMoveIllegalReason:(enum GoMoveIsIllegalReason*)reason
{
  return [self isLegalPassMoveByColor:self.nextMoveColor illegalReason:reason];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if playing a pass move would be legal for the player
/// who plays @a color in the current board position. This does not include
/// checking for alternating play.
///
/// If this method returns false, the out parameter @a reason is filled with
/// the reason why the move is not legal. If this method returns true, the
/// value of @a reason is undefined.
///
/// Alternating play, if it is desired, must be enforced by the application
/// logic. This method simply assumes that the player who plays @a color has the
/// right to move in the current board position.
///
/// Raises @e NSInvalidArgumentException if @a color is neither #GoColorBlack
/// nor #GoColorWhite.
// -----------------------------------------------------------------------------
- (bool) isLegalPassMoveByColor:(enum GoColor)color illegalReason:(enum GoMoveIsIllegalReason*)reason
{
  if (color != GoColorBlack && color != GoColorWhite)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Invalid color argument %d", color];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:self.boardPosition.currentNode];
  if (nodeWithMostRecentMove)
  {
    if (nodeWithMostRecentMove.goMove.moveNumber >= maximumNumberOfMoves)
    {
      *reason = GoMoveIsIllegalReasonTooManyMoves;
      return false;
    }
  }

  return true;
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
  if (GoGameStateGameHasEnded == self.state || nil != self.firstMove)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Attempt to set %lu handicap stones failed: ", (unsigned long)newValue.count];
    if (GoGameStateGameHasEnded == self.state)
      errorMessage = [errorMessage stringByAppendingFormat:@"Game is in state GoGameStateGameHasEnded, reason = %d", self.reasonForGameHasEnded];
    else
      errorMessage = [errorMessage stringByAppendingString:@"Game already has moves"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! newValue)
  {
    NSString* errorMessage = @"Attempt to set handicap stones failed: Point list argument is nil";
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
      if (point.stoneState != GoColorNone)
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Handicap list contains point that is already occupied: %@", point];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }

      point.stoneState = GoColorBlack;
      [GoUtilities movePointToNewRegion:point];
    }
  }

  // If setupFirstMoveColor has not set an explicit color, nextMoveColor is
  // free to change according to the game rules
  if (self.setupFirstMoveColor == GoColorNone)
  {
    if (_handicapPoints && 0 == _handicapPoints.count)
      self.nextMoveColor = GoColorBlack;
    else
      self.nextMoveColor = GoColorWhite;
  }

  self.zobristHashAfterHandicap = [self.board.zobristTable hashForHandicapStonesInGame:self];

  GoNode* rootNode = self.nodeModel.rootNode;
  if (rootNode.goNodeSetup)
    [rootNode.goNodeSetup updatePreviousSetupInformationAfterHandicapStonesDidChange:self];

  rootNode.zobristHash = [self.board.zobristTable hashForNode:rootNode inGame:self];
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
  [encoder encodeObject:self.nodeModel forKey:goGameNodeModelKey];
  [encoder encodeInt:self.state forKey:goGameStateKey];
  [encoder encodeInt:self.reasonForGameHasEnded forKey:goGameReasonForGameHasEndedKey];
  [encoder encodeInt:self.reasonForComputerIsThinking forKey:goGameReasonForComputerIsThinking];
  [encoder encodeObject:self.boardPosition forKey:goGameBoardPositionKey];
  [encoder encodeObject:self.rules forKey:goGameRulesKey];
  [encoder encodeObject:self.document forKey:goGameDocumentKey];
  [encoder encodeObject:self.score forKey:goGameScoreKey];
  [encoder encodeInt:self.setupFirstMoveColor forKey:goGameSetupFirstMoveColorKey];
  // GoZobristTable is not archived, instead a new GoZobristTable object with
  // random values is created each time when a game is unarchived. Zobrist
  // hashes created by the previous GoZobristTable object are thus invalid.
  // This is the reason why we don't archive self.zobristHashAfterHandicap
  // here - it doesn't make sense to archive an invalid value. A side effect of
  // not archiving self.zobristHashAfterHandicap is that the overall archive
  // becomes smaller.
}

// -----------------------------------------------------------------------------
/// @brief Ends the game (i.e. sets it to state #GoGameStateGameHasEnded) if at
/// least two consecutive pass moves were played as the last moves, and if the
/// game rules require the game to end because of this. Does nothing otherwise.
/// If this method ends the game, it also sets @e reasonForGameHasEnded
/// according to the game rules.
///
/// Invoking this method sets the document dirty flag if the game state changes.
///
/// Raises an @e NSInternalInconsistencyException if this method is invoked
/// while this GoGame object is not in state #GoGameStateGameHasStarted or
/// #GoGameStateGameIsPaused.
///
/// @note Invoking this method should not be necessary under normal
/// circumstances. Specifically, pass() already invokes this method, so invoking
/// it again is not necessary.
// -----------------------------------------------------------------------------
- (void) endGameDueToPassMovesIfGameRulesRequireIt
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

  int numberOfConsecutivePassMoves = 0;
  GoMove* potentialPassMove = self.lastMove;
  while (potentialPassMove && GoMoveTypePass == potentialPassMove.type)
  {
    ++numberOfConsecutivePassMoves;
    potentialPassMove = potentialPassMove.previous;
  }

  bool didEndGame = true;

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
  else if (numberOfConsecutivePassMoves >= 2 && 0 == (numberOfConsecutivePassMoves % 2) && GoLifeAndDeathSettlingRuleTwoPasses == self.rules.lifeAndDeathSettlingRule)
  {
    self.reasonForGameHasEnded = GoGameHasEndedReasonTwoPasses;
    self.state = GoGameStateGameHasEnded;
  }
  else
  {
    didEndGame = false;
  }

  if (didEndGame)
    self.document.dirty = true;
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
/// If the game has ended due to resignation, win on time or win by forfeit,
/// invoking this method sets the document dirty flag. This behaviour exists to
/// remain consistent with the action that ends the game (e.g. resignation),
/// which also sets the document dirty flag. If the game ended for some reason
/// other than those mentioned initially, it is expected that some other action
/// in addition to invoking revertStateFromEndedToInProgress will cause the
/// document dirty flag to be set. For instance, if three pass moves caused
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

  switch (self.reasonForGameHasEnded)
  {
    case GoGameHasEndedReasonBlackWinsByResignation:
    case GoGameHasEndedReasonWhiteWinsByResignation:
    case GoGameHasEndedReasonBlackWinsOnTime:
    case GoGameHasEndedReasonWhiteWinsOnTime:
    case GoGameHasEndedReasonBlackWinsByForfeit:
    case GoGameHasEndedReasonWhiteWinsByForfeit:
      self.document.dirty = true;
      break;
    default:
      break;
  }

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

// TODO xxx document
// Checks the entire board in its current state whether the setup stones that
// are present are legal (i.e. no suicidal stone groups). Since Ko is not yet
// possible before moves have been played, the only illegal position possible
// is a stone or group of stones having no liberties.
- (bool) isLegalBoardSetup:(NSString**)suicidalIntersectionsString
{
  int numberOfSuicidalIntersections = 0;
  *suicidalIntersectionsString = @"";

  for (GoBoardRegion* region in self.board.regions)
  {
    if (! region.isStoneGroup)
      continue;
    if (region.liberties > 0)
      continue;

    for (GoPoint* suicidalPoint in region.points)
    {
      if (numberOfSuicidalIntersections > 0)
        *suicidalIntersectionsString = [*suicidalIntersectionsString stringByAppendingString:@", "];
      *suicidalIntersectionsString = [*suicidalIntersectionsString stringByAppendingString:suicidalPoint.vertex.string];
      numberOfSuicidalIntersections++;
    }
  }

  return (numberOfSuicidalIntersections == 0);
}

// -----------------------------------------------------------------------------
/// @brief Adds or removes @a point to/from the list of handicap points
/// (@e handicapPoints). Changes the @e stoneState property of @a point
/// accordingly and recalculates the property @e zobristHashAfterHandicap.
///
/// If @e setupFirstMoveColor is #GoColorBlack or #GoColorWhite this method
/// does not change the value of the @e nextMoveColor property, because if a
/// side is explicitly set to play first this has precedence over the normal
/// game rules. If however @e setupFirstMoveColor is #GoColorNone, this method
/// may change the value of the @e nextMoveColor property:
/// - Sets @e nextMoveColor to #GoColorWhite if @e handicapPoints changes from
///   empty to non-empty.
/// - Sets @e nextMoveColor to #GoColorBlack if @e handicapPoints changes from
///   non-empty to empty.
///
/// Posts #handicapPointDidChange to the global notification centre after the
/// operation is complete.
///
/// KVO observers of the property @e handicapPoints will be triggered.
///
/// Raises @e NSInvalidArgumentException if @a point is @e nil.
///
/// Raises @e NSInternalInconsistencyException if this method is invoked when
/// this GoGame object is not in state #GoGameStateGameHasStarted, or if it is
/// in that state but already has moves. Summing it up, this method can be
/// invoked only at the start of the game.
///
/// Also raises @e NSInternalInconsistencyException if something about @a point
/// is wrong:
/// - The current stone state of @a point indicates that there is a black
///   handicap stone on the intersection, but @a point is not listed in
///   @e handicapPoints.
/// - The current stone state of @a point indicates that the intersection is
///   empty, but @a point is listed in @e handicapPoints.
/// - The current stone state of @a point indicates that there is a white
///   stone on the intersection.
// -----------------------------------------------------------------------------
- (void) toggleHandicapPoint:(GoPoint*)point
{
  if (GoGameStateGameHasEnded == self.state || nil != self.firstMove)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Attempt to add or remove handicap stone at intersection %@ failed: ", point.vertex.string];
    if (GoGameStateGameHasEnded == self.state)
      errorMessage = [errorMessage stringByAppendingFormat:@"Game is in state GoGameStateGameHasEnded, reason = %d", self.reasonForGameHasEnded];
    else
      errorMessage = [errorMessage stringByAppendingString:@"Game already has moves"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (! point)
  {
    NSString* errorMessage = @"Attempt to add or remove handicap stone failed: Point argument is nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  switch (point.stoneState)
  {
    case GoColorBlack:
    {
      NSMutableArray* newHandicapPoints = [NSMutableArray arrayWithArray:self.handicapPoints];
      [newHandicapPoints removeObject:point];

      if (self.handicapPoints.count == newHandicapPoints.count)
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Attempt to remove handicap stone at intersection %@ failed: There is a black stone on the intersection, but the point is not in the list of handicap stones", point.vertex.string];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }

      self.handicapPoints = newHandicapPoints;
      assert(point.stoneState == GoColorNone);

      break;
    }
    case GoColorNone:
    {
      if ([self.handicapPoints containsObject:point])
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Attempt to add handicap stone at intersection %@ failed: There is no stone on the intersection, but the point is in the list of handicap stones", point.vertex.string];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
      }

      self.handicapPoints = [self.handicapPoints arrayByAddingObject:point];
      assert(point.stoneState == GoColorBlack);

      break;
    }
    case GoColorWhite:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Attempt to add or remove handicap stone at intersection %@ failed: There is a white stone on the intersection", point.vertex.string];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:handicapPointDidChange object:point];
}

// -----------------------------------------------------------------------------
/// @brief Changes the side that is set up to play the first move to
/// @e newValue. See the documentation of property @e setupFirstMoveColor for
/// details, also on which exceptions can be thrown.
///
/// If @a newValue is either #GoColorBlack or #GoColorWhite, this changes the
/// property @e nextMoveColor to the same value. If @a newValue is #GoColorNone
/// this changes the value of the property @e nextMoveColor according to the
/// game rules, like this:
/// - Sets @e nextMoveColor to #GoColorWhite if @e handicapPoints is non-empty.
/// - Sets @e nextMoveColor to #GoColorBlack if @e handicapPoints is empty.
// -----------------------------------------------------------------------------
- (void) changeSetupFirstMoveColor:(enum GoColor)newValue
{
  GoNode* currentNode = self.boardPosition.currentNode;
  GoNodeSetup* nodeSetup = currentNode.goNodeSetup;
  if (! nodeSetup)
  {
    nodeSetup = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFrom:self];
    currentNode.goNodeSetup = nodeSetup;
  }

  nodeSetup.setupFirstMoveColor = newValue;

  if (nodeSetup.isEmpty)
    currentNode.goNodeSetup = nil;

  // The property setter performs all sorts of validation
  self.setupFirstMoveColor = newValue;

  if (_setupFirstMoveColor != GoColorNone)
    self.nextMoveColor = _setupFirstMoveColor;
  // If no color is set up explicitly, the game rules apply
  else if (self.handicapPoints.count > 0)
    self.nextMoveColor = GoColorWhite;
  else
    self.nextMoveColor = GoColorBlack;
}

// -----------------------------------------------------------------------------
/// @brief Changes the @e stoneState property of @a point to the specified value
/// @a stoneState. Does nothing if @a point already has the desired stone state.
///
/// Posts #setupPointDidChange to the global notification centre after the
/// operation is complete.
///
/// Raises @e NSInvalidArgumentException if @a point is nil, or if changing the
/// @e stoneState property of @a point to the specified value @a stoneState is
/// not a legal board setup operation.
///
/// Raises @e NSInternalInconsistencyException if this method is invoked when
/// this GoGame object is not in state #GoGameStateGameHasStarted, or if it is
/// in that state but already has moves. Summing it up, this method can be
/// invoked only at the start of the game.
///
/// Also raises @e NSInternalInconsistencyException if something about @a point
/// is wrong:
/// - @a point is listed in @e handicapPoints.
// -----------------------------------------------------------------------------
- (void) changeSetupPoint:(GoPoint*)point toStoneState:(enum GoColor)stoneState
{
  if (GoGameStateGameHasEnded == self.state || nil != self.firstMove)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Attempt to change stone state of setup point %@ to %d failed: ", point.vertex.string, stoneState];
    if (GoGameStateGameHasEnded == self.state)
      errorMessage = [errorMessage stringByAppendingFormat:@"Game is in state GoGameStateGameHasEnded, reason = %d", self.reasonForGameHasEnded];
    else
      errorMessage = [errorMessage stringByAppendingString:@"Game already has moves"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  if (! point)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Attempt to change stone state of setup point to %d failed: Point argument is nil", stoneState];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  if (point.stoneState == stoneState)
    return;

  if ([self.handicapPoints containsObject:point])
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Attempt to change stone state of setup point %@ to %d failed: Point is already in the list of handicap points", point.vertex.string, stoneState];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  if (stoneState != GoColorNone)
  {
    enum GoBoardSetupIsIllegalReason reason;
    GoPoint* illegalStoneOrGroupPoint;

    bool isLegalBoardSetup = [self isLegalBoardSetupAt:point
                                        withStoneState:stoneState
                                       isIllegalReason:&reason
                            createsIllegalStoneOrGroup:&illegalStoneOrGroupPoint];
    if (! isLegalBoardSetup)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Attempt to change stone state of setup point %@ to %d failed: Point argument is not a legal setup stone", point.vertex.string, stoneState];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }

  GoNode* currentNode = self.boardPosition.currentNode;
  GoNodeSetup* nodeSetup = currentNode.goNodeSetup;
  if (! nodeSetup)
  {
    nodeSetup = [GoNodeSetup nodeSetupWithPreviousSetupCapturedFrom:self];
    currentNode.goNodeSetup = nodeSetup;
  }

  if (stoneState == GoColorBlack)
    [nodeSetup setupBlackStone:point];
  else if (stoneState == GoColorWhite)
    [nodeSetup setupWhiteStone:point];
  else
    [nodeSetup setupNoStone:point];

  if (nodeSetup.isEmpty)
    currentNode.goNodeSetup = nil;

  point.stoneState = stoneState;
  [GoUtilities movePointToNewRegion:point];

  currentNode.zobristHash = [self.board.zobristTable hashForNode:currentNode inGame:self];

  [[NSNotificationCenter defaultCenter] postNotificationName:setupPointDidChange object:point];
}

// -----------------------------------------------------------------------------
/// @brief Discards all setup that exists for the current board position,
/// reverting the board to the state of the previous board position. The discard
/// includes any change to the property @e setupFirstMoveColor. Does nothing if
/// no setup exists for the current board position.
///
/// If the current board position is the first board position, this will cause
/// any handicap stones that existed and were removed by the board setup to be
/// restored.
///
/// Posts #allSetupStonesWillDiscard to the global notification centre before
/// any changes are made. Posts #allSetupStonesDidDiscard to the global
/// notification centre after the discard is complete.
///
/// Raises @e NSInternalInconsistencyException if it is invoked when this GoGame
/// object is not in state #GoGameStateGameHasStarted, or if it is in that state
/// but already has moves. Summing it up, this property can be set only at the
/// start of the game.
// -----------------------------------------------------------------------------
- (void) discardAllSetup
{
  if (GoGameStateGameHasEnded == self.state || nil != self.firstMove)
  {
    NSString* errorMessage = @"Attempt to discard all setup stones failed: ";
    if (GoGameStateGameHasEnded == self.state)
      errorMessage = [errorMessage stringByAppendingFormat:@"Game is in state GoGameStateGameHasEnded, reason = %d", self.reasonForGameHasEnded];
    else
      errorMessage = [errorMessage stringByAppendingString:@"Game already has moves"];
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:allSetupStonesWillDiscard object:self];

  GoNode* currentNode = self.boardPosition.currentNode;
  GoNodeSetup* nodeSetup = currentNode.goNodeSetup;
  if (! nodeSetup)
    return;

  [nodeSetup revertSetup];
  currentNode.goNodeSetup = nil;

  currentNode.zobristHash = [self.board.zobristTable hashForNode:currentNode inGame:self];

  [[NSNotificationCenter defaultCenter] postNotificationName:allSetupStonesDidDiscard object:self];
}

@end
