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
/// @brief The RestoreGameCommand class is responsible for restoring a backed
/// up game during application startup.
///
/// If RestoreGameCommand finds a backup .sgf file in the application's library
/// folder, it assumes that the application crashed or was killed while
/// suspended. It starts a new game with the content of the backup .sgf file
/// and using the current user defaults for "new games". The net effect is that
/// the application is restored as close as possible to the state it had when it
/// was last seen alive by the user.
///
/// If RestoreGameCommand finds no backup .sgf file, it simply starts a new
/// game.
///
/// @see BackupGameCommand.
///
/// @attention In some cases execution of RestoreGameCommand will not wait for
/// all operations to complete before control is returned to the caller. The
/// calling thread must therefore be sufficiently long-lived (preferrably the
/// main thread) to make sure that all responses to asynchronous GTP commands
/// can be delivered. If care is not taken, the application may hang forever!
/// Refer to the class documentation of NewGameCommand and LoadGameCommand for
/// additional information.
// -----------------------------------------------------------------------------
@interface RestoreGameCommand : CommandBase
{
}

- (id) init;

@end
