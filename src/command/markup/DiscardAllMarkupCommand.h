// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The DiscardAllMarkupCommand class is responsible for discarding
/// all markup associated with the current board position.
/// DiscardAllMarkupCommand first displays an alert that asks the user for
/// confirmation.
///
/// After it has made the discard, DiscardAllMarkupCommand posts the
/// notifications #allMarkupDidDiscard and #nodeMarkupDataDidChange, performs
/// a backup of the current game and saves the application state.
///
/// @note Because DiscardAllMarkupCommand always shows an alert as its
/// first action, command execution will always succeed and control will always
/// return to the client who submitted the command before the markup is actually
/// discarded.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in markup editing mode. If any of these conditions is not met an alert
/// is displayed and command execution fails.
// -----------------------------------------------------------------------------
@interface DiscardAllMarkupCommand : CommandBase
{
}

@end
