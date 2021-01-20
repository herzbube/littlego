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


// Project includes
#import "../CommandBase.h"
#import "../AsynchronousCommand.h"


// -----------------------------------------------------------------------------
/// @brief The LoadGameCommand class is responsible for loading a game from
/// SGF data provided by SgfcKit, and starting a new game using the information
/// in that file.
///
/// LoadGameCommand is executed asynchronously (unless the executor is another
/// asynchronous command).
///
/// The sequence of operations performed by LoadGameCommand is this:
/// - Parse the SgfcKit objects to obtain the information that is needed to
///   start a new game (e.g. board size)
/// - Start a new game by executing a NewGameCommand instance
/// - Parse the SgfcKit objects to obtain additional information that was stored
///   in the .sgf file (handicap, komi, moves)
/// - Setup the game with the additional information
/// - Invoke SyncGTPEngineCommand to synchronize the computer player with the
///   information that was read from the .sgf file
/// - Make a backup
/// - Notify observers that a game has been loaded
/// - Trigger the computer player, if it is his turn to move, by executing a
///   ComputerPlayMoveCommand instance
///
/// @attention If the computer player is triggered, the calling thread must
/// survive long enough for ComputerPlayMoveCommand to complete, otherwise
/// the GTP client will be unable to deliver the GTP response and the
/// application will hang forever.
///
///
/// @par SGF data with illegal content
///
/// LoadGameCommand performs two kinds of sanitary checks for every move it
/// finds in the SGF data:
/// - Is the move played by the expected player color?
/// - Is the move legal?
///
/// If any one of these checks fails, the entire load operation fails. A new
/// game is started nonetheless, to bring the app back into a defined state.
///
/// An exception that is raised while the moves in the .sgf file are replayed
/// is caught and handled. The result is the same as if one of the sanitary
/// checks had failed.
// -----------------------------------------------------------------------------
@interface LoadGameCommand : CommandBase <AsynchronousCommand>
{
}

- (id) initWithGameInfoNode:(SGFCNode*)sgfGameInfoNode goGameInfo:(SGFCGoGameInfo*)sgfGoGameInfo;

/// @brief True if the command is executed to restore a backup game. False
/// (the default) if the command is executed to load a game from the archive.
@property(nonatomic, assign) bool restoreMode;
/// @brief True if the command triggered the computer player, false if not.
@property(nonatomic, assign) bool didTriggerComputerPlayer;

@end
