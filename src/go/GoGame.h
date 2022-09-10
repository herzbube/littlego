// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoBoard;
@class GoBoardPosition;
@class GoGameDocument;
@class GoGameRules;
@class GoMove;
@class GoNodeModel;
@class GoPlayer;
@class GoPoint;
@class GoScore;


// -----------------------------------------------------------------------------
/// @brief The GoGame class represents a game of Go.
///
/// @ingroup go
///
/// GoGame can be viewed as taking the role of a model in an MVC pattern that
/// includes the views and controllers in #UIAreaPlay. Clients that run one of
/// the various commands (e.g. #PlayMoveCommand) will trigger updates in GoGame
/// that can be observed by registering with the default NSNotificationCenter.
/// See Constants.h for a list of notifications that can be observed.
///
/// Although it is possible to create multiple instances of GoGame, there is
/// usually no point in doing so, except for unit testing purposes. During the
/// normal course of the applications's lifetime the following situations can
/// therefore be observed:
/// - No GoGame object exists: This is the case only for a brief period while
///   the application starts up.
/// - One GoGame object exists: This situtation exists during most of the
///   application's lifetime. This GoGame instance represents the game that is
///   currently in progress or that has just ended. The instance can be accessed
///   by invoking the class method sharedGame().
/// - Two GoGame objects exist: This situation occurs only for a brief moment
///   while a new game is being started. One of the GoGame objects is the game
///   that is going to be discarded, but is still available via sharedGame().
///   The other GoGame objects is the new game that is still in the process of
///   being configured. Access to this new GoGame object is not available yet.
///   The new GoGame object becomes officially available via sharedGame() when
///   the notification #goGameDidCreate is being sent.
// -----------------------------------------------------------------------------
@interface GoGame : NSObject <NSCoding>
{
}

+ (GoGame*) sharedGame;
- (void) play:(GoPoint*)point;
- (void) pass;
- (void) resign;
- (void) pause;
- (void) continue;
- (bool) isLegalBoardSetupAt:(GoPoint*)point
              withStoneState:(enum GoColor)stoneState
             isIllegalReason:(enum GoBoardSetupIsIllegalReason*)reason
  createsIllegalStoneOrGroup:(GoPoint**)illegalStoneOrGroupPoint;
- (bool) isLegalMove:(GoPoint*)point isIllegalReason:(enum GoMoveIsIllegalReason*)reason;
- (bool) isLegalMove:(GoPoint*)point byColor:(enum GoColor)color isIllegalReason:(enum GoMoveIsIllegalReason*)reason;
- (bool) isLegalPassMoveIllegalReason:(enum GoMoveIsIllegalReason*)reason;
- (bool) isLegalPassMoveByColor:(enum GoColor)color illegalReason:(enum GoMoveIsIllegalReason*)reason;
- (void) revertStateFromEndedToInProgress;
- (void) switchNextMoveColor;
- (void) toggleHandicapPoint:(GoPoint*)point;
- (void) changeSetupPoint:(GoPoint*)point toStoneState:(enum GoColor)stoneState;
- (void) discardAllSetupStones;

/// @brief The type of this GoGame object.
@property(nonatomic, assign) enum GoGameType type;
/// @brief The GoBoard object associated with this GoGame instance.
@property(nonatomic, retain) GoBoard* board;
/// @brief List of GoPoint objects with handicap stones.
///
/// Setting this property causes a black stone to be set on each GoPoint object
/// in the specified list, and the black stone to be removed from each GoPoint
/// object in the previously set list. Setting this property also recalculates
/// @e zobristHashBeforeFirstMove.
///
/// If @e setupFirstMoveColor is #GoColorBlack or #GoColorWhite, setting this
/// property does not change the value of the @e nextMoveColor property, because
/// if a side is explicitly set to play first this has precedence over the
/// normal game rules. If however @e setupFirstMoveColor is #GoColorNone,
/// setting this property may change the value of the @e nextMoveColor property:
/// - Sets @e nextMoveColor to #GoColorWhite if the handicap list changes from
///   empty to non-empty.
/// - Sets @e nextMoveColor to #GoColorBlack if the handicap list changes from
///   non-empty to empty.
///
/// The setter raises @e NSInternalInconsistencyException if it is invoked when
/// this GoGame object is not in state #GoGameStateGameHasStarted, or if it is
/// in that state but already has moves. Summing it up, this property can be set
/// only at the start of the game.
///
/// The setter raises @e NSInvalidArgumentException if the specified list
/// contains one or more GoPoint objects that are already occupied (this can
/// occur only if a GoPoint already appears in @e blackSetupPoints or
/// @e whiteSetupPoints).
///
/// If the setter raises an @e NSInvalidArgumentException for one of the reasons
/// documented above, the exception message is usable for displaying as error
/// message to the user. Also, the old property value has already been replaced
/// with the new value, and the @e stoneState property of GoPoint objects in the
/// old list have already been restored to #GoColorNone. The @e stoneState
/// property of some GoPoint objects in the new list may already have been set
/// to #GoColorBlack. The state of the board is probably difficult to repair and
/// it is recommended to allocate a new GoGame instance.
///
/// Raises @e NSInvalidArgumentException if this property is set with a nil
/// value.
@property(nonatomic, retain) NSArray* handicapPoints;
/// @brief The komi used for this game.
@property(nonatomic, assign) double komi;
/// @brief The GoPlayer object that plays black.
@property(nonatomic, retain) GoPlayer* playerBlack;
/// @brief The GoPlayer object that plays white.
@property(nonatomic, retain) GoPlayer* playerWhite;
/// @brief The side who will make the next move. Note that this property is tied
/// to the CURRENT board position, which if the user is viewing an old board
/// position is not the same as the LAST board position.
///
/// The setter raises @e NSInvalidArgumentException if a color is set that is
/// neither black nor white.
@property(nonatomic, assign) enum GoColor nextMoveColor;
/// @brief The player who will make the next move. Note that this property is
/// tied to the CURRENT board position, which if the user is viewing an old
/// board position is not the same as the LAST board position.
@property(nonatomic, assign, readonly) GoPlayer* nextMovePlayer;
/// @brief True if the player who makes the next move is a computer player.
@property(nonatomic, assign, readonly) bool nextMovePlayerIsComputerPlayer;
/// @brief Denotes whether alternating play is enabled or disabled. If
/// alternating play is enabled, invoking play:() and pass() or modifying the
/// content of the GoNodeModel object causes the @e nextMovePlayer and
/// @e nextMoveColor properties to change. If alternating play is not enabled,
/// the mentioned properties do not change so that the same player can make
/// several consecutive moves.
@property(nonatomic, assign) bool alternatingPlay;
/// @brief The model object that stores the nodes of the game tree.
@property(nonatomic, retain) GoNodeModel* nodeModel;
/// @brief The GoMove object that represents the first move of the game. nil if
/// no moves have been made yet.
///
/// This is a convenience property that serves as a shortcut so that clients do
/// not have to obtain the desired GoMove object from @e nodeModel.
@property(nonatomic, assign, readonly) GoMove* firstMove;
/// @brief The GoMove object that represents the last move of the game. nil if
/// no moves have been made yet.
///
/// This is a convenience property that serves as a shortcut so that clients do
/// not have to obtain the desired GoMove object from @e nodeModel.
@property(nonatomic, assign, readonly) GoMove* lastMove;
/// @brief The state of the game. Note that this property is tied to the LAST
/// board position, not the CURRENT board position.
@property(nonatomic, assign) enum GoGameState state;
/// @brief The reason why the game has reached the state
/// #GoGameStateGameHasEnded. Is #GoGameHasEndedReasonNotYetEnded if property
/// @e state has not the value #GoGameStateGameHasEnded.
@property(nonatomic, assign) enum GoGameHasEndedReason reasonForGameHasEnded;
/// @brief Returns true if the computer player is currently busy thinking about
/// something (typically its next move).
@property(nonatomic, assign, readonly, getter=isComputerThinking) bool computerThinks;
/// @brief The reason why the computer is busy. Is
/// #GoGameComputerIsThinkingReasonIsNotThinking if property
/// @e isComputerThinking is not true.
@property(nonatomic, assign) enum GoGameComputerIsThinkingReason reasonForComputerIsThinking;
/// @brief The model object that defines defines which position of the Go board
/// is currently described by the GoPoint and GoBoardRegion objects attached to
/// this GoGame.
@property(nonatomic, retain) GoBoardPosition* boardPosition;
/// @brief Defines the rules that are in effect for this GoGame.
@property(nonatomic, retain) GoGameRules* rules;
/// @brief Represents this GoGame as a document that can be saved to / loaded
/// from disk.
@property(nonatomic, retain) GoGameDocument* document;
/// @brief The GoScore object that provides scoring information about this
/// GoGame.
@property(nonatomic, retain) GoScore* score;
/// @brief List of GoPoint objects on which black stones are to be placed
/// as part of the game setup prior to the first move.
///
/// Setting this property causes a black stone to be placed on the GoPoint
/// objects in the specified list and the property
/// @e zobristHashBeforeFirstMove to be recalculated.
///
/// The setter raises @e NSInternalInconsistencyException if it is invoked when
/// this GoGame object is not in state #GoGameStateGameHasStarted, or if it is
/// in that state but already has moves. Summing it up, this property can be set
/// only at the start of the game.
///
/// The setter raises @e NSInvalidArgumentException if the specified list
/// contains one or more GoPoint objects that are already occupied (this can
/// occur only if a GoPoint already appears in @e handicapPoints or
/// @e whiteSetupPoints).
///
/// The setter raises @e NSInvalidArgumentException if placing one of the stones
/// results in an illegal position (since Ko is not yet possible before moves
/// have been played, the only illegal position possible is a stone or group of
/// stones having no liberties).
///
/// If the setter raises an @e NSInvalidArgumentException for one of the reasons
/// documented above, the exception message is usable for displaying as error
/// message to the user. Also, the old property value has already been replaced
/// with the new value, and the @e stoneState property of GoPoint objects in the
/// old list have already been restored to #GoColorNone. The @e stoneState
/// property of some GoPoint objects in the new list may already have been set
/// to #GoColorBlack. The state of the board is probably difficult to repair and
/// it is recommended to allocate a new GoGame instance.
///
/// Raises @e NSInvalidArgumentException if this property is set with a nil
/// value.
@property(nonatomic, retain) NSArray* blackSetupPoints;
/// @brief List of GoPoint objects on which white stones are to be placed
/// as part of the game setup prior to the first move.
///
/// @see Property @e blackSetupPoints - the same rules specified there apply to
/// this property as well. 
@property(nonatomic, retain) NSArray* whiteSetupPoints;
/// @brief The side that is set up to play the first move. Is #GoColorNone
/// if no side is set up to play first. Note that this is @b not necessarily the
/// side that actually plays the first move - notably in a game that was loaded
/// from an .sgf file the two can be different.
///
/// Setting this property to either #GoColorBlack or #GoColorWhite changes the
/// property @e nextMoveColor to the same value. Setting this property to
/// #GoColorNone changes the value of the @e nextMoveColor property like this:
/// - Sets @e nextMoveColor to #GoColorWhite if @e handicapPoints is non-empty.
/// - Sets @e nextMoveColor to #GoColorBlack if @e handicapPoints is empty.
///
/// The setter raises @e NSInternalInconsistencyException if it is invoked when
/// this GoGame object is not in state #GoGameStateGameHasStarted, or if it is
/// in that state but already has moves. Summing it up, this property can be set
/// only at the start of the game.
@property(nonatomic, assign) enum GoColor setupFirstMoveColor;
/// @brief The Zobrist hash for the board before the first move is played. Is
/// recalculated every time one of the properties @e handicapPoints,
/// @e blackSetupPoints and @e whiteSetupPoints changes.
@property(nonatomic, assign) long long zobristHashBeforeFirstMove;

@end
