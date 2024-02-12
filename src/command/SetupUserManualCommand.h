// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "AsynchronousCommand.h"


// -----------------------------------------------------------------------------
/// @brief The SetupUserManualCommand class is responsible for setting up the
/// user manual if it has not been set up yet, or updating the currently set up
/// user manual if it is outdated. Command execution occurs asynchronously.
///
/// The user manual content is obtained from the resource bundle.
///
/// @note Even though command execution occurs asynchronously this command
/// does not disable a progress HUD. The submitter of the command is responsible
/// to handle UI feedback during command execution.
// -----------------------------------------------------------------------------
@interface SetupUserManualCommand : CommandBase <AsynchronousCommand>
{
}

@end
