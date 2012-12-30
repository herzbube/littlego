// -----------------------------------------------------------------------------
// Copyright 2012-2013 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The DiscardAndPlayCommand class is responsible for first discarding
/// all moves in the future of the board position currently displayed on the
/// Play view, then playing a move.
///
/// DiscardAndPlayCommand looks at the current board position in
/// BoardPositionModel, then discards all moves in GoMoveModel that are in the
/// future of that board position. No moves are discarded if BoardPositionModel
/// is already at the last board position.
///
/// After moves are discarded, DiscardAndPlayCommand makes sure that the GTP
/// engine is synchronized with the new board position.
///
/// Finally, DiscardAndPlayCommand executes one of several possible play
/// commands. Which one is chosen depends on the initializer that was used to
/// construct the DiscardAndPlayCommand object. The following options exist:
/// - initWithPoint:() results in a #GoMoveTypePlay move made by a human player
/// - initPass:() results in a #GoMoveTypePass move made by a human player
/// - initPlayForMe() results in a move made by the computer on behalf of the
///   human player
// -----------------------------------------------------------------------------
@interface DiscardAndPlayCommand : CommandBase
{
}

- (id) initWithPoint:(GoPoint*)aPoint;
- (id) initPass;
- (id) initPlayForMe;

@end
