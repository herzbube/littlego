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
/// game to an .sgf file that is not visible in the archive. It also saves the
/// value for the current board position.
///
/// BackupGameCommand writes an .sgf file to a fixed location in the
/// application's library folder. Because the backup file is not in the shared
/// document folder, it is visible/accessible neither in iTunes, nor on the
/// in-app tab "Archive".
///
/// BackupGameCommand delegates its task to the GTP engine via the "savesgf" GTP
/// command. If the .sgf file already exists, it is overwritten.
///
/// BackupGameCommand executes synchronously.
///
/// @see RestoreGameCommand.
// -----------------------------------------------------------------------------
@interface BackupGameCommand : CommandBase
{
}

- (id) init;

@end
