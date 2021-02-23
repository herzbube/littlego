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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The SaveGameCommand class is responsible for saving the current
/// game to the archive.
///
/// SaveGameCommand delegates the .sgf saving task to SaveSgfCommand. The
/// resulting .sgf file includes all moves of the game, even if the user
/// currently views an old board position. If a game with the same name already
/// exists in the archive, it is overwritten. If an error occurs SaveGameCommand
/// displays an alert.
///
/// SaveGameCommand executes synchronously.
///
/// @see SaveSgfCommand
// -----------------------------------------------------------------------------
@interface SaveGameCommand : CommandBase
{
}

- (id) initWithSaveGame:(NSString*)aGameName gameAlreadyExists:(bool)gameAlreadyExists;

/// @brief The name under which the current game should be saved. This is not
/// the file name!
@property(nonatomic, retain) NSString* gameName;

/// @brief True if a game with the same name already exists, false if no game
/// exists under the same name.
@property(nonatomic, assign) bool gameAlreadyExists;

@end
