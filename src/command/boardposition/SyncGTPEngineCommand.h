// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The SyncGTPEngineCommand class is responsible for synchronizing the
/// state of the GTP engine with the state of the current GoGame.
///
/// By default SyncGTPEngineCommand synchronizes the GTP engine with the moves
/// up to the current board position. Handicap is always synchronized, even if
/// board position 0 is synchronized.
///
/// Optionally SyncGTPEngineCommand may be configured so that it synchronizes
/// the GTP engine with all moves of the entire game.
// -----------------------------------------------------------------------------
@interface SyncGTPEngineCommand : CommandBase
{
}

@property(nonatomic, assign) bool syncMovesUpToCurrentBoardPosition;

@end
