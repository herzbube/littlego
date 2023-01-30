// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The ChangeNodeSelectionAsyncCommand class is responsible for
/// directing the change of the selected node to a given GoNode.
///
/// ChangeNodeSelectionAsyncCommand is executed asynchronously (unless the
/// executor is another asynchronous command).
///
/// The process consists of the following steps:
/// - Find out if the current game variation in GoNodeModel contains the GoNode
///   to be selected.
/// - If it does: The node selection process ends with a simple board position
///   change, so that the current board position matches the GoNode to be
///   selected.
/// - If it does not: The node selection process continues with the following
///   steps.
/// - Determine the new game variation in GoNodeModel that contains the GoNode
///   to be selected.
/// - Determine the ancestor GoNode that is the branching node after which the
///   current and new game variations differ.
/// - Invoke ChangeBoardPositionCommand, to change the current board position
///   to match the branching GoNode (rewind). This causes the notification
///   #boardPositionChangeProgress to be sent <n> times, and the notification
///   #currentBoardPositionDidChange to be sent once.
/// - Invoke ChangeGameVariationCommand, to change the currently configured game
///   variation in GoNodeModel to the new game variation. This causes the
///   notifications #currentGameVariationWillChange and
///   #currentGameVariationDidChange to be sent once, optionally with the
///   notification #numberOfBoardPositionsDidChange being sent once in between
///   if the number of nodes in the old and new game variations differ. Also
///   the game state may change during this step to match the newly selected
///   game variation.
/// - Invoke ChangeBoardPositionCommand, to change the current board position
///   to match the GoNode to be selected (forward). This causes the notification
///   #boardPositionChangeProgress to be posted <n> times, and the notification
///   #currentBoardPositionDidChange to be posted once.
/// - Mark the application state as having changed, so that the board position
///   and game variation can be restored when the application launches the next
///   time. Whoever executes ChangeNodeSelectionAsyncCommand is responsible for
///   actually saving the application state to disk.
// -----------------------------------------------------------------------------
@interface ChangeNodeSelectionAsyncCommand : CommandBase <AsynchronousCommand>
{
}

- (id) initWithNode:(GoNode*)node;

@end
