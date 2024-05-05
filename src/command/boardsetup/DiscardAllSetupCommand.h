// -----------------------------------------------------------------------------
// Copyright 2019-2024 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The DiscardAllSetupCommand class is responsible for discarding all
/// stones that the board is currently set up with. DiscardAllSetupCommand
/// first displays an alert that asks the user for confirmation.
///
/// Before it discards setup stones, DiscardAllSetupCommand also discards any
/// nodes that the current game variation has. Whoever invoked
/// DiscardAllSetupCommand must have previously made sure that it's OK to
/// discard future nodes.
///
/// After it has made the discard, DiscardAllSetupCommand syncs the GTP engine,
/// saves the application state and performs a backup of the current game.
///
/// Posts #allSetupStonesWillDiscard to the global notification centre before
/// any changes are made. Posts #allSetupStonesDidDiscard and
/// #nodeSetupDataDidChange to the global notification centre after the discard
/// is complete.
///
/// @note Because DiscardAllSetupCommand always shows an alert as its first
/// action, command execution will always succeed and control will always
/// return to the client who submitted the command before the setup stones are
/// actually discarded.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in board setup mode and the current board position is 0. If any of these
/// conditions is not met an alert is displayed (but command execution still
/// succeeds, as explained further up).
// -----------------------------------------------------------------------------
@interface DiscardAllSetupCommand : CommandBase
{
}

@end
