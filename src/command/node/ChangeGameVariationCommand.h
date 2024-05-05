// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The ChangeGameVariationCommand class is responsible for directing
/// the change of the current game variation in GoNodeModel.
///
/// The process consists of the following steps:
/// - Send notification #currentGameVariationWillChange.
/// - Change the currently configured game variation in GoNodeModel to the new
///   game variation.
/// - Update the number of board positions in GoBoardPosition to match the
///   newly configured variation in GoNodeModel.
/// - Send notification #numberOfBoardPositionsDidChange (optional, only if the
///   number of nodes in the old and new game variations differ).
/// - Send notification #currentGameVariationDidChange.
/// - Update the game state to match the end of the new game variation.
/// - Mark the application state as having changed, so that the game variation
///   can be restored when the application launches the next time. Whoever
///   executes ChangeNodeSelectionCommand is responsible for actually saving
///   the application state to disk.
///
/// ChangeGameVariationCommand relies on the current board position matching
/// a node that exists in both the old and the new game variation. This can be
/// any common ancestor node, it need not be the actual branching node after
/// which the two game variations differ.
///
/// ChangeGameVariationCommand does nothing if the current game variation in
/// GoNodeModel already contains the GoNode that ChangeGameVariationCommand is
/// initialized with.
// -----------------------------------------------------------------------------
@interface ChangeGameVariationCommand : CommandBase
{
}

- (id) initWithNode:(GoNode*)node;

@end
