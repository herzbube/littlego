// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The DiscardAllSetupStonesCommand class is responsible for discarding
/// all stones that the board is currently set up with.
/// DiscardAllSetupStonesCommand first displays an alert that asks the user for
/// confirmation.
///
/// After it has made the discard, DiscardAllSetupStonesCommand performs a
/// backup of the current game.
///
/// @note Because DiscardAllSetupStonesCommand always shows an alert as its
/// first action, command execution will always succeed and code execution will
/// always return to the client who submitted the command before the setup
/// stones are actually discarded.
// -----------------------------------------------------------------------------
@interface DiscardAllSetupStonesCommand : CommandBase
{
}

@end
