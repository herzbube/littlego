// -----------------------------------------------------------------------------
// Copyright 2012-2023 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The PlayCommand class is responsible for playing a move made by the
/// user, or initiating the playing of a move made by the computer.
///
/// PlayCommand executes one of several possible play commands. Which one is
/// chosen depends on the initializer that was used to construct the
/// PlayCommand object. The following options exist:
/// - initWithPoint:() results in a #GoMoveTypePlay move made by a human player
/// - initPass:() results in a #GoMoveTypePass move made by a human player
/// - initComputerPlay() results in a move made by the computer either for
///   itself, or on behalf of the human player whose turn it currently is
/// - initContinue() results in a paused computer vs. computer game being
///   continued
///
/// If the user is currently viewing a board position in the middle of the
/// current game variation, the "new move insert policy" user preference decides
/// how the new move is inserted into the node tree. Notably, if the user
/// preference is set to #GoNewMoveInsertPolicyReplaceFutureBoardPositions,
/// future nodes after the current board position are discarded!
// -----------------------------------------------------------------------------
@interface PlayCommand : CommandBase
{
}

- (id) initWithPoint:(GoPoint*)aPoint;
- (id) initPass;
- (id) initComputerPlay;
- (id) initContinue;

@end
