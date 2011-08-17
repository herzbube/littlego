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
/// @brief The GoGame class represents a game of Go. Only one instance of GoGame
/// is created throughout the application's lifetime. This instance can be
/// accessed by invoking the class method sharedGame().
///
/// @ingroup go
///
/// GoGame can be viewed as taking the role of a model in an MVC pattern that
/// includes the views and controllers on the Play tab of the GUI. Clients that
/// invoke one of the various "action" methods (e.g. play:()) will trigger
/// (possibly asynchronous) events that can be observed by registering with the
/// default NSNotificationCenter. See Constants.h for a list of notifications
/// that can be observed.
// -----------------------------------------------------------------------------
@interface GoGame : NSObject
{
}

+ (GoGame*) sharedGame;
+ (GoGame*) newGame;
- (void) play:(GoPoint*)point;
- (void) pass;
- (void) computerPlay;
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
/// @brief The GoPlayer object that plays for black.
@property(retain) GoPlayer* playerBlack;
/// @brief The GoPlayer object that plays for white.
@property(retain) GoPlayer* playerWhite;
/// @brief The player whose turn it is now.
@property(readonly, assign) GoPlayer* currentPlayer;
/// @brief The GoMove object that represents the first move of the game. nil if
/// the game is still in state #GameHasNotYetStarted.
@property(retain) GoMove* firstMove;
/// @brief The GoMove object that represents the last move of the game. nil if
/// the game is still in state #GameHasNotYetStarted.
@property(retain) GoMove* lastMove;
/// @brief The state of the game.
@property enum GoGameState state;
/// @brief Returns true if the computer player is currently busy thinking about
/// its next move.
@property(getter=isComputerThinking) bool computerThinks;
/// @brief Returns the game score as a string that can be displayed to the
/// user. Returns nil if no score is available. The score becomes available
/// only after the game state changes to #GameHasEnded.
@property(retain) NSString* score;

@end
