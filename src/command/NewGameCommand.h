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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The NewGameCommand class is responsible for starting a new game
/// using the values currently stored in NewGameModel.
///
/// Starting a new game is a complex operation that can be broken down into
/// the following steps:
/// - Deallocate the old GoGame object (if it exists)
/// - Create a new GoGame object
/// - Set up the board in the GTP engine
/// - If at least one of the players of the new game is a computer player:
///   Configure the GTP engine with settings obtained from the computer player
///
/// A client may suppress some of these steps by clearing the corresponding
/// property flag before a NewGameCommand object is executed.
// -----------------------------------------------------------------------------
@interface NewGameCommand : CommandBase
{
}

- (id) init;

@property(assign) bool shouldSetupGtpBoard;
@property(assign) bool shouldSetupComputerPlayer;

@end
