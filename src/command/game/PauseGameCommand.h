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
/// @brief The PauseGameCommand class is responsible for pausing a game with
/// fully automated play, where two computer players play against each other.
///
/// Even though the game is paused, the computer player whose turn it is will
/// finish its thinking and play its move. Pausing the game then takes effect
/// because the second computer player's move is not triggered.
///
/// This solution is necessary because there is no way to tell the GTP engine
/// to stop its thinking once the "genmove" command has been sent. The only
/// way how to handle this in a graceful way is to let the GTP engine finish
/// its thinking.
// -----------------------------------------------------------------------------
@interface PauseGameCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;

@end
