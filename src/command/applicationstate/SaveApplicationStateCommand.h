// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The SaveApplicationStateCommand class is responsible for saving the
/// current application state to an NSCoding archive so that the application
/// state can be restored when the application re-launches after a crash or
/// after it was killed while suspended.
///
/// SaveApplicationStateCommand stores the NSCoding archive in a fixed location
/// in the application's library folder. Because the file is not in the shared
/// document folder, it is visible/accessible neither in iTunes, nor in-app in
/// #UIAreaArchive.
///
/// The NSCoding archive is overwritten if it already exists.
///
/// SaveApplicationStateCommand executes synchronously.
///
/// @see RestoreApplicationStateCommand.
/// @see ApplicationStateManager.
// -----------------------------------------------------------------------------
@interface SaveApplicationStateCommand : CommandBase
{
}

@end
