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


/// @brief Enumerates the different ways how SyncGTPEngineCommand can
/// synchronize board positions.
enum SyncBoardPositionType
{
  SyncBoardPositionsUpToCurrentBoardPosition,
  SyncBoardPositionsOfEntireGame
};


// -----------------------------------------------------------------------------
/// @brief The SyncGTPEngineCommand class is responsible for synchronizing the
/// state of the GTP engine with the state of the current GoGame.
///
/// By default SyncGTPEngineCommand synchronizes the GTP engine with the setup
/// and/or moves from the current game variation up to the current board
/// position. Handicap is always synchronized, even if board position 0 is
/// synchronized.
///
/// Optionally SyncGTPEngineCommand may be configured so that it synchronizes
/// the GTP engine with the setup and/or moves from all board positions of the
/// current game variation.
///
/// Board positions for nodes that contain neither setup nor a move are ignored.
///
/// If execution of SyncGTPEngineCommand fails, the GTP engine is left in an
/// unknown state.
// -----------------------------------------------------------------------------
@interface SyncGTPEngineCommand : CommandBase
{
}

@property(nonatomic, assign) enum SyncBoardPositionType syncBoardPositionType;
@property(nonatomic, retain, readonly) NSString* errorDescription;

@end
