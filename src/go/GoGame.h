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


// Forward declarations
@class GoBoard;
@class GoPlayer;
@class GoMove;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoGame class represents a game of Go.
///
/// @ingroup go
///
/// Only one instance of GoGame can exist at the same time. This instance can
/// be accessed by invoking the class method sharedGame().
///
/// Currently the shared game instance is made available early on during the
/// GoGame initialization process so that other Go objects, which are also
/// created during GoGame initialization, may access the shared instance. There
/// is a todo with the intention to change this behaviour!
///
/// GoGame can be viewed as taking the role of a model in an MVC pattern that
/// includes the views and controllers on the Play tab of the GUI. Clients that
/// run one of the various commands (e.g. PlayMoveCommand) will trigger updates
/// in GoGame that can be observed by registering with the default
/// NSNotificationCenter. See Constants.h for a list of notifications that can
/// be observed.
// -----------------------------------------------------------------------------
@interface GoGame : NSObject
{
}

+ (GoGame*) sharedGame;
+ (GoGame*) newGame;
- (void) play:(GoPoint*)point;
- (void) pass;
- (void) resign;
- (void) undo;
- (void) pause;
- (void) continue;
- (bool) isLegalMove:(GoPoint*)point;
- (bool) isComputerPlayersTurn;

/// @brief The type of this GoGame object.
@property(readonly) enum GoGameType type;
/// @brief The GoBoard object associated with this GoGame instance.
@property(retain) GoBoard* board;
/// @brief List of GoPoint objects with handicap stones.
@property(retain) NSArray* handicapPoints;
/// @brief The komi used for this game.
@property double komi;
/// @brief The GoPlayer object that plays for black.
@property(retain) GoPlayer* playerBlack;
/// @brief The GoPlayer object that plays for white.
@property(retain) GoPlayer* playerWhite;
/// @brief The player whose turn it is now.
///
/// After the game has ended, querying this property in some cases is a
/// convenient way to find out who brought about the end of the game. For
/// instance, if the game was resigned this denotes the player who resigned.
@property(readonly, assign) GoPlayer* currentPlayer;
/// @brief The GoMove object that represents the first move of the game. nil if
/// the game is still in state #GameHasNotYetStarted.
@property(retain) GoMove* firstMove;
/// @brief The GoMove object that represents the last move of the game. nil if
/// the game is still in state #GameHasNotYetStarted.
@property(retain) GoMove* lastMove;
/// @brief The state of the game.
@property enum GoGameState state;
/// @brief The reason why the game has reached the state #GameHasEnded.
@property enum GoGameHasEndedReason reasonForGameHasEnded;
/// @brief Returns true if the computer player is currently busy thinking about
/// its next move.
@property(getter=isComputerThinking) bool computerThinks;
/// @brief Returns the game score as a string that can be displayed to the
/// user. Returns nil if no score is available. The score becomes available
/// only after the game state changes to #GameHasEnded.
@property(retain) NSString* score;
/// @brief Is true to indicate that the next GoMove object created should have
/// its @e computerGenerated flag set to true.
///
/// TODO This is a nasty little hack to allow GoGame to set the GoMove object's
/// flag before sending #goGameFirstMoveChanged or #goGameLastMoveChanged. This
/// timing hack allows observers to check the GoMove object's flag when they
/// react to one of those notifications. To remove this hack we need to do some
/// redesigning...
@property bool nextMoveIsComputerGenerated;

@end
