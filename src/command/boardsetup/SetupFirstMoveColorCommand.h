// -----------------------------------------------------------------------------
// Copyright 2019-2022 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The SetupFirstMoveColorCommand class is responsible for setting up
/// the game with a side that is to play the first move.
///
/// Before it discards setup stones, SetupFirstMoveColorCommand also discards
/// any nodes that the current game variation has. Whoever invoked
/// SetupFirstMoveColorCommand must have previously made sure that it's OK to
/// discard future nodes.
///
/// After it has processed the board setup interaction,
/// SetupFirstMoveColorCommand syncs the GTP engine, saves the application state
/// and performs a backup of the current game.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in board setup mode and the current board position is 0. If any of these
/// conditions is not met an alert is displayed and command execution fails.
// -----------------------------------------------------------------------------
@interface SetupFirstMoveColorCommand : CommandBase
{
}

- (id) initWithFirstMoveColor:(enum GoColor)firstMoveColor;

@end
