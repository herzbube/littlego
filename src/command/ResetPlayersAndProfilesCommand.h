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


// -----------------------------------------------------------------------------
/// @brief The ResetPlayersAndProfilesCommand class is responsible for directing
/// the process of resetting all players and profiles to their factory defaults.
///
/// The process involves the following steps:
/// - Remove all players and profiles from the current user defaults so that the
///   registration domain defaults become visible
/// - Direct the involved model objects to reload their settings
/// - Start a new game using the new settings
///
/// ResetPlayersAndProfilesCommand does not display any alerts. It is the
/// responsibility of the client executing ResetPlayersAndProfilesCommand to
/// warn the user about the consequences of this action, and possibly to ask for
/// confirmation.
///
/// ResetPlayersAndProfilesCommand posts the following notifications at the very
/// beginning and end of its execution: #playersAndProfilesWillReset and
/// #playersAndProfilesDidReset.
// -----------------------------------------------------------------------------
@interface ResetPlayersAndProfilesCommand : CommandBase
{
}

@end
