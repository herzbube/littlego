// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BackupGameToSgfCommand class is responsible for saving the
/// current game to an .sgf file so that the most important aspects of the game
/// can be restored when the application re-launches after a crash or after it
/// was killed while suspended.
///
/// BackupGameToSgfCommand stores the .sgf file in a fixed location in the
/// application's library folder. Because the file is not in the shared document
/// folder, it is visible/accessible neither in iTunes, nor on the in-app tab
/// "Archive".
///
/// BackupGameToSgfCommand delegates the .sgf saving task to SaveSgfCommand.
/// The resulting .sgf file includes all moves of the game, even if the user
/// currently views an old board position. If the backup file already exists it
/// is overwritten. If an error occurs BackupGameToSgfCommand does not display
/// an alert, this is the task of whoever invokes BackupGameToSgfCommand.
///
/// BackupGameToSgfCommand executes synchronously.
///
/// @see SaveSgfCommand
/// @see RestoreGameFromSgfCommand.
/// @see ApplicationStateManager.
// -----------------------------------------------------------------------------
@interface BackupGameToSgfCommand : CommandBase
{
}

@end
