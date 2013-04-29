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
#import "../CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The RestoreApplicationStateCommand class is responsible for restoring
/// the application state to the state previously saved to an NSCoding archive.
/// RestoreApplicationStateCommand is executed during application startup.
///
/// RestoreApplicationStateCommand fails if the NSCoding archive is not
/// compatible to the current application version. If this occurs,
/// RestoreApplicationStateCommand removes the NSCoding archive file.
///
/// @see SaveApplicationStateCommand.
/// @see ApplicationStateManager.
// -----------------------------------------------------------------------------
@interface RestoreApplicationStateCommand : CommandBase
{
}

@end
