// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
/// SaveGameCommand uses SgfcKit to encode the information in the current
/// GoGame and its associated objects to the SGF format. If a game with the same
/// name already exists, it is overwritten. If an error occurs, SaveGameCommand
/// displays an alert.
///
/// SaveGameCommand makes sure that the resulting .sgf file includes all moves
/// of the game, even if the user currently views an old board position.
///
/// SaveGameCommand takes the following precautions in order not to overwrite
/// an already existing game needlessly:
/// - It first validates the generated SGF content using SgfcKit's validation
///   mechanism. This is essentially a dry run of a full write cycle, the only
///   exception being that the SGF content is not written to disk but to memory.
/// - If validation is successful the SGF content is then written to a temporary
///   file. Only if that filesystem interaction succeeds is the existing game
///   overwritten with the temporary file.
///
/// SaveGameCommand executes synchronously.
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
