// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The NewGameCommand class is responsible for starting a new game
/// using the values currently stored in NewGameModel.
///
/// Starting a new game is a complex operation that can be broken down into
/// the following steps:
/// - Deallocate the old GoGame object (if it exists)
/// - Create a new GoGame object
/// - Set up the board in the GTP engine
/// - Set up handicap and komi
/// - Configure the GTP engine with settings obtained from a profile
/// - Trigger the computer player, if it is his turn to move, by executing a
///   ComputerPlayMoveCommand instance
///
/// A client may suppress some of these steps by clearing the corresponding
/// property flag before a NewGameCommand object is executed. A client may
/// suppress the creation of a new GoGame by initializing NewGameCommand with
/// a pre-fabricated GoGame object.
///
/// @attention If @e shouldTriggerComputerPlayer is true, the calling thread
/// must survive long enough for ComputerPlayMoveCommand to complete, otherwise
/// the GTP client will be unable to deliver the GTP response and the
/// application will hang forever.
// -----------------------------------------------------------------------------
@interface NewGameCommand : CommandBase
{
}

- (id) init;
- (id) initWithGame:(GoGame*)game;

@property(nonatomic, assign) bool shouldResetUIAreaPlayMode;
@property(nonatomic, assign) bool shouldHonorAutoEnableBoardSetupMode;
@property(nonatomic, assign) bool shouldSetupGtpBoard;
@property(nonatomic, assign) bool shouldSetupGtpHandicapAndKomi;
@property(nonatomic, assign) bool shouldSetupComputerPlayer;
@property(nonatomic, assign) bool shouldTriggerComputerPlayer;

@end
