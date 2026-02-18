// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
@class GoPlayer;


// -----------------------------------------------------------------------------
/// @brief Enumerates the possible reasons why the player clock is requested to
/// be started.
// -----------------------------------------------------------------------------
enum PlayerClockStartReason
{
  /// @brief The clock is requested to be started because a new game has been
  /// started and it is the beginning of a human player's turn.
  PlayerClockStartReasonNewGameHumanPlayerTurnBegins,
  /// @brief The clock is requested to be started because a game has been loaded
  /// from the archive and it is the beginning of a human player's turn.
  PlayerClockStartReasonLoadGameHumanPlayerTurnBegins,
  /// @brief The clock is requested to be started because it is the beginning
  /// of a human player's turn (not immediately when a new game starts or is
  /// loaded from the archive).
  PlayerClockStartReasonHumanPlayerTurnBegins,
  /// @brief The clock is requested to be started because it is the beginning
  /// of a computer player's turn.
  PlayerClockStartReasonComputerPlayerTurnBegins,
  /// @brief The clock is requested to be started because the computer player
  /// starts thinking on behalf of a human player (e.g. "play for me" function)
  /// after the human player's turn has already started.
  PlayerClockStartReasonComputerPlayerStartsThinkingOnBehalfOfHumanPlayer,
  /// @brief The user interactively requests the clock to be started.
  PlayerClockStartReasonUserRequest,
};


// -----------------------------------------------------------------------------
/// @brief Enumerates the possible reasons why the player clock is requested to
/// be stopped.
// -----------------------------------------------------------------------------
enum PlayerClockStopReason
{
  /// @brief The clock is requested to be stopped because the turn of a player
  /// ends.
  PlayerClockStopReasonPlayerTurnEnds,
  /// @brief The clock is requested to be stopped because the player resigns.
  PlayerClockStopReasonPlayerResigns,
  /// @brief The clock is requested to be stopped because the selected node
  /// changes.
  PlayerClockStopReasonSelectedNodeChanges,
  /// @brief The clock is requested to be stopped because a new game is about
  /// to be created.
  PlayerClockStopReasonNewGameWillBeCreated,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the possible reasons why the player clock is requested to
/// be suspended.
// -----------------------------------------------------------------------------
enum PlayerClockSuspendReason
{
  /// @brief The user interactively requests the clock to be suspended.
  PlayerClockSuspendReasonUserRequest,
};


// -----------------------------------------------------------------------------
/// @brief Enumerates the possible reasons why the player clock is requested to
/// be reset to reflect the time data in the currently selected node.
// -----------------------------------------------------------------------------
enum PlayerClockResetReason
{
  /// @brief The game was lost on time by the player whose clock is to be reset,
  /// but is now reverted back to in progress.
  PlayerClockResetReasonRevertLostOnTime,
};


// -----------------------------------------------------------------------------
/// @brief Enumerates the possible results of certain PlayerClockService
/// operations
// -----------------------------------------------------------------------------
enum PlayerClockServiceOperationResult
{
  /// @brief There is no more time left and the player loses the game on time.
  PlayerClockServiceOperationResultGameLostOnTime,
  /// @brief There is still time left (e.g. switching from absolute time to
  /// overtime, or the player has more periods (aka "lifes") left) and the
  /// game continues.
  PlayerClockServiceOperationResultGameContinues,
};


// -----------------------------------------------------------------------------
/// @brief The PlayerClockService protocol provides operations with which
/// clients can request changes to the state of the player clocks. The
/// application-wide instance of PlayerClockService can be obtained from the
/// shared Registry.
// -----------------------------------------------------------------------------
@protocol PlayerClockService

// -----------------------------------------------------------------------------
/// @brief Requests that the clock of @a player be started, because of
/// @a startReason. The request may or may not be honored, depending on the
/// current state of the application as seen by the service. Does nothing if
/// the current game does not use timed play.
///
/// Some examples why the request may not be honored are: The game has already
/// ended, or the user has previously suspended the clock, or the user attempts
/// to start the clock of a player when it's not that player's turn.
///
/// In some cases a stopped clock is not started, but instead suspended. Notably
/// this happens if the user preferences indicate that the human player's clock
/// not be automatically started.
// -----------------------------------------------------------------------------
- (void) startClockOfPlayer:(GoPlayer*)player
                     reason:(enum PlayerClockStartReason)startReason;

// -----------------------------------------------------------------------------
/// @brief Requests that the clock of @a player be stopped, because of
/// @a stopReason. The request may or may not be honored, depending on the
/// current state of the application as seen by the service. Does nothing if
/// the current game does not use timed play.
///
/// Currently the only reason why the request may not be honored is if the clock
/// is already suspended. If that is the case, the clock remains suspended.
/// It can therefore be said that the clock is guaranteed to be "not started"
/// when this method returns. If the clock is not stopped as requested, then it
/// is at least suspended.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) stopClockOfPlayer:(GoPlayer*)player
                                                      reason:(enum PlayerClockStopReason)stopReason;

// -----------------------------------------------------------------------------
/// @brief Requests that the clock of @a player be suspended, because of
/// @a suspendReason. The request may or may not be honored, depending on the
/// current state of the application as seen by the service. Does nothing if
/// the current game does not use timed play.
///
/// Some examples why the request may not be honored are: The user attempts to
/// suspend the clock of a player when it's not that player's turn, or the user
/// preferences indicate that the user is not allowed to suspend player clocks
/// at all.
// -----------------------------------------------------------------------------
- (enum PlayerClockServiceOperationResult) suspendClockOfPlayer:(GoPlayer*)player
                                                         reason:(enum PlayerClockSuspendReason)suspendReason;

// -----------------------------------------------------------------------------
/// @brief Requests that the clock of @a player is reset to reflect the time
/// data in the currently selected node, because of @a resetReason. The request
/// may or may not be honored, depending on the current state of the application
/// as seen by the service. Does nothing if the current game does not use timed
/// play.
///
/// An example why the request may not be honored is if it is not the turn of
/// @a player.
// -----------------------------------------------------------------------------
- (void) resetClockOfPlayer:(GoPlayer*)player
                     reason:(enum PlayerClockResetReason)resetReason;

@end
