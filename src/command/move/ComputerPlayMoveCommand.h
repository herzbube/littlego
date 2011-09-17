// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The ComputerPlayMoveCommand class is responsible for letting the
/// computer player make a move (even if it is not his turn).
///
/// ComputerPlayMoveCommand submits a "genmove" command to the GTP engine, then
/// updates GoGame so that it generates a GoMove of the appropriate type for
/// the player whose turn it is (not necessarily a computer player).
///
/// The computer player is triggered if it is now its turn to move.
// -----------------------------------------------------------------------------
@interface ComputerPlayMoveCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;

@end
