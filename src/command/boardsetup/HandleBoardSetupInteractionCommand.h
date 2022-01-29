// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The HandleBoardSetupInteractionCommand class is responsible for
/// handling a board setup interaction at the intersection identified by the
/// GoPoint object that is passed to the initializer.
///
/// Before it discards setup stones, HandleBoardSetupInteractionCommand also
/// discards any moves that the game currently has. Whoever invoked
/// HandleBoardSetupInteractionCommand must have previously made sure that it's
/// OK to discard future moves.
///
/// After it has processed the board setup interaction,
/// HandleBoardSetupInteractionCommand syncs the GTP engine, saves the
/// application state and performs a backup of the current game.
///
/// @note Because HandleBoardSetupInteractionCommand may show an alert, command
/// execution may succeed and control may return to the client who submitted
/// the command before handling of the tap gesture has actually finished.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in board setup mode and the current board position is 0. If any of these
/// conditions is not met an alert is displayed and command execution fails.
// -----------------------------------------------------------------------------
@interface HandleBoardSetupInteractionCommand : CommandBase
{
}

- (id) initWithPoint:(GoPoint*)point;

@end
