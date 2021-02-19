// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The ComputerSuggestMoveCommand class is responsible for letting the
/// computer player generate a move suggestion and for initiating display of
/// the suggestion to the user.
///
/// ComputerSuggestMoveCommand submits a "reg_genmove" command to the GTP
/// engine. The GTP command is executed asynchronously, i.e. control returns to
/// the submitter of ComputerSuggestMoveCommand before the computer player
/// has actually generated a suggestion. When the GTP response finally arrives
/// ComputerSuggestMoveCommand initiates the display of the received suggestion
/// by sending the notification #computerPlayerGeneratedMoveSuggestion.
///
/// While the GTP command is executing GoGame::reasonForComputerIsThinking()
/// property is set so that observers can react and disable user interaction
/// where appropriate.
// -----------------------------------------------------------------------------
@interface ComputerSuggestMoveCommand : CommandBase
{
}

- (id) initWithColor:(enum GoColor)color;

@end
