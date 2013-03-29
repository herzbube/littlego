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
#import "../newgame/NewGameController.h"


// -----------------------------------------------------------------------------
/// @brief The HandleDocumentInteraction class is responsible for opening an
/// .sgf file that was passed into the application via the system's document
/// interaction mechanism.
///
/// The URL referring to .sgf file is the value of the ApplicationDelegate
/// property @e documentInteractionURL.
///
/// @note Control will return from HandleDocumentInteraction's doIt() method
/// before the game from the .sgf file is fully loaded. The reason is that
/// HandleDocumentInteraction displays a NewGameController, i.e. the program
/// control flow needs to be broken to let the controller handle user
/// interaction.
// -----------------------------------------------------------------------------
@interface HandleDocumentInteraction : CommandBase <NewGameDelegate>
{
}

@end
