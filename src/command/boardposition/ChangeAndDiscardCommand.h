// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The ChangeAndDiscardCommand class is responsible for discarding the
/// current node, possibly the parent node, and all child nodes. As a side
/// effect, the current board position changes to the node that is the @b parent
/// node of the earliest node that was just discarded. The second responsibility
/// of ChangeAndDiscardCommand is to manage the game state and the game result.
///
/// If the user preference DiscardMyLastMove is turned on (the default) and the
/// current node was created by a computer player's move, then all parent nodes
/// that were created by a human player's move are discarded as well. This can
/// only occur in a computer vs. human game with alternating moves. Usually two
/// nodes will be discarded, but more than two nodes can be discarded if there
/// are several consecutive human player moves.
///
/// If the first node that is discarded (first node = the node closest to the
/// root node) has a next or previous sibling, then the current game variation
/// will change to the variation that contains the next sibling (if one exists)
/// or the previous sibling (if no next sibling exists), plus all the
/// first-child descendants of the next/previous sibling. As a consequence, the
/// number of board positions in the current game variation may @b not change.
///
/// ChangeAndDiscardCommand performs game state and game result handling as
/// follows:
/// - Revert the game state to "in progress" if the game is currently ended.
///   This can occur even if the current node is the root node and no other
///   nodes have been created yet, e.g. because a player resigned immediately
///   without playing a move.
/// - As part of the revert, if the current game variation is the main
///   variation, also updates the game result to match the new game state.
///   Rationale: The current game variation's data is about to change due to
///   the discard.
/// - After discarding nodes, update the game state to match the data in the
///   current game variation. As outlined above, the current game variation
///   may change due to the discard, therefore the game state must be updated.
///   If the new game variation is the main variation, the game result will
///   be considered when determining the game state (may cause the game to
///   become e.g. resigned). Otherwise only the most recent pass moves (if any)
///   are considered.
/// - Rationale why the game result is @b not updated after discarding: The
///   main game variation content is not changed anymore at this point.
///
/// After it has made the discard and/or managed the game state and game result,
/// ChangeAndDiscardCommand performs a backup of the current game.
///
/// ChangeAndDiscardCommand posts a number of notifications to the default
/// notification center. This is the sequence
/// - 0-n times #currentBoardPositionWillChange and
///   #currentBoardPositionDidChange (via ChangeBoardPositionCommand).
///   The notification is never posted if the current node is the root node.
///   The notification is posted once if the number of nodes that need to be
///   discarded is below a certain threshold and the board position change can
///   be made in one go. The notification is posted multiple times if the number
///   of nodes that need to be discarded is larger than the threshold and the
///   board position change must be made in multiple steps.
/// - 0-1 times #currentGameVariationWillChange. The notification is posted
///   only if the first node that is discarded has a next or previous sibling.
/// - 0-1 times #numberOfBoardPositionsDidChange. The notification is never
///   posted if either 1) the only node that exists is the root node; or 2) the
///   first node that is discarded has a next or previous sibling and the
///   discard causes the same number of new nodes to be added to the current
///   game variation that were discarded.
/// - 0-1 times #currentGameVariationDidChange. The notification is posted
///   only to balance #currentGameVariationWillChange, i.e. it will be posted
///   only if the first node that is discarded has a next or previous sibling.
/// - 0-1 times #goNodeTreeLayoutDidChange. The notification is never posted if
///   no nodes are discarded because there are no other nodes than the root
///   node.
///
/// @note The root node represents the start of the game and cannot be
/// discarded. Therefore, if ChangeAndDiscardCommand is executed when the
/// current node is the root node, ChangeAndDiscardCommand behaves as if the
/// current node were the root node's child node that comes next in the current
/// game variation.
///
/// @note In a computer vs. human game where the user preference
/// DiscardMyLastMove is turned off, executing this command may result in a
/// situation where it is now the computer's turn to play. The computer player
/// is not triggered in this situation, though, to give the user the flexibility
/// to further edit the game.
// -----------------------------------------------------------------------------
@interface ChangeAndDiscardCommand : CommandBase
{
}

@end
