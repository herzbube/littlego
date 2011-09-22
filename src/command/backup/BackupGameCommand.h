// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The BackupGameCommand class is responsible for backing up the game
/// that is currently in progress.
///
/// BackupGameCommand writes an .sgf file to a fixed location in the
/// application's library folder. Because the backup file is not in the shared
/// document folder, it is not visible/accessible in iTunes.
///
/// @see RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface BackupGameCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;
@property(assign) UIBackgroundTaskIdentifier backgroundTask;

@end
