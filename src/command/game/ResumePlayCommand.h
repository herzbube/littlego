// -----------------------------------------------------------------------------
// Copyright 2015-2016 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The ResumePlayCommand class is responsible for resuming play after
/// the game has ended, allowing the players to settle life & death disputes.
///
/// ResumePlayCommand checks if the game rules allow non-alternating play on
/// game resumption. If not, ResumePlayCommand simply resumes play. If yes,
/// ResumePlayCommand shows an alert that lets the user select which side
/// should play first after the game is resumed. When the user has selected a
/// side, ResumePlayCommand resumes play and sets the color to move according
/// to the user's choice.
///
/// @note Because ResumePlayCommand may show an alert, code execution may
/// return to the client who submitted the command before play is actually
/// resumed.
///
/// If scoring mode is currently enabled, ResumePlayCommand disables it upon
/// resuming play so that the user can continue playing smoothly.
///
/// If after the game is resumed it is the computer player's turn,
/// ResumePlayCommand triggers the computer to play a move.
// -----------------------------------------------------------------------------
@interface ResumePlayCommand : CommandBase
{
}

@end
