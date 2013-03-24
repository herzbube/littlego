// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
/// If RestoreGameCommand finds no backed up game, it simply starts a new
/// game.
///
/// If RestoreGameCommand finds a backed up game, it assumes that the
/// application crashed, or was killed while it was suspended. There are many
/// reasons why the latter could have happened, among them are: The system
/// needed to reclaim memory; the user killed the application from the
/// multitasking UI; or the application was upgraded via App Store. Whatever the
/// reason, RestoreGameCommand tries as hard as possible to restore the
/// application to as close as possible to the state it had when it was last
/// seen alive by the user.
///
/// The procedure is as follows:
/// - A backed up game consists of two files: A primary NSCoding archive file,
///   and a secondary .sgf file.
/// - RestoreGameCommand first tries to restore the application state from
///   the NSCoding archive. If this succeeds it ignores the .sgf file.
/// - If restoring from the NSCoding archive fails, RestoreGameCommand falls
///   back to the .sgf file: It performs a LoadGameCommand to at least recover
///   the moves stored in the .sgf file. All the other aspects of the
///   application state that are beyond the raw game moves cannot be restored
///   in this fallback scenario (e.g. the board position that the user was
///   viewing, any scoring mode information, the GoGameDocument dirty flag).
///
/// The main reason why the fallback scenario exists is so that a game can be
/// restored after the application was upgraded to a new version via App Store,
/// and that new app version uses a different NSCoding version. Having a
/// different NSCoding version makes the backup NSCoding archive useless because
/// it is incompatible with the new app version. The .sgf file, on the other
/// hand, is expected to remain readable at all times.
///
/// @see BackupGameCommand.
// -----------------------------------------------------------------------------
@interface RestoreGameCommand : CommandBase
{
}

@end
