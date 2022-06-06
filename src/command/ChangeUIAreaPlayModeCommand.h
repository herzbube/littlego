// -----------------------------------------------------------------------------
// Copyright 2019-2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The ChangeUIAreaPlayModeCommand class is responsible for changing
/// the UI area "Play" to a desired mode, and for notifying the rest of the
/// application about the change. ChangeUIAreaPlayModeCommand does nothing if
/// the UI area "Play" is already in the desired mode.
///
/// ChangeUIAreaPlayModeCommand displays an alert, and command execution fails,
/// if #UIAreaPlayModeBoardSetup is requested but the current board position
/// is not 0, or if #UIAreaPlayModeEditMarkup is requested but the current
/// board position is 0.
// -----------------------------------------------------------------------------
@interface ChangeUIAreaPlayModeCommand : CommandBase
{
}

- (id) initWithUIAreaPlayMode:(enum UIAreaPlayMode)uiAreaPlayMode;

@property(nonatomic, assign) bool newGameSetupIsInProgress;

@end
