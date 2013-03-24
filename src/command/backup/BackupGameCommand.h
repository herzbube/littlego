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


// -----------------------------------------------------------------------------
/// @brief The BackupGameCommand class is responsible for saving the current
/// game and application state so that a restore can be made when the
/// application re-launches after a crash or after it was killed while
/// suspended.
///
/// BackupGameCommand writes a primary NSCoding archive, and optionally an .sgf
/// file. The files are stored in a fixed location in the application's library
/// folder. Because the files are not in the shared document folder, they are
/// visible/accessible neither in iTunes, nor on the in-app tab "Archive".
///
/// BackupGameCommand delegates the .sgf saving task to the GTP engine via the
/// "savesgf" GTP command. Both the NSCoding archiveand the .sgf file are
/// overwritten if they already exist.
///
/// BackupGameCommand executes synchronously.
///
/// @see RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface BackupGameCommand : CommandBase
{
}

/// @brief Indicates whether BackupGameCommand should save an .sgf file. This
/// flag is false by default.
///
/// This flag should be set only by actors who trigger a backup after a move has
/// been played or discarded.
@property(nonatomic, assign) bool saveSgf;

@end
