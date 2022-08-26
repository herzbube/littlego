// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The SaveSgfCommand class is responsible for saving the current
/// game to a specified destination file in the SGF format.
///
/// SaveSgfCommand uses SgfcKit to encode the information in the current
/// GoGame and its associated objects to the SGF format. If a file with the same
/// name already exists, it is overwritten. If an error occurs, SaveSgfCommand
/// makes an error message describing the problem available to the caller which
/// can then be displayed in the UI.
///
/// SaveSgfCommand makes sure that the resulting .sgf file includes all moves
/// of the game, even if the user currently views an old board position.
///
/// SaveSgfCommand takes the following precautions in order not to overwrite
/// an already existing .sgf file needlessly:
/// - It first validates the generated SGF content using SgfcKit's validation
///   mechanism. This is essentially a dry run of a full write cycle, the only
///   exception being that the SGF content is not written to disk but to memory.
/// - If validation is successful the SGF content is then written to a temporary
///   file. Only if that filesystem interaction succeeds is the existing .sgf
///   file overwritten with the temporary file.
///
/// SaveSgfCommand executes synchronously.
///
/// The resulting SGF file is structured as follows:
/// - Contains only one game
/// - Contains only one variation
/// - Root node: Contains root properties, e.g. GM and SZ. May also contain
///   node annotation properties (e.g. C, N, GB) and/or markup properties (e.g.
///   CR, AR, LB) if the user for some reason decided to define these things for
///   board position 0.
/// - Game info node: Contains game info properties, e.g. KM, HA, PB, PW.
///   Currently the root node is also used as the game info node.
/// - Setup node: An extra node after the root and game info nodes that contains
///   board setup properties, e.g. AB, AW, PL.
/// - 0-n remaining nodes with move properties (e.g. B, W), node and move
///   annotation properties (e.g. C, N, GB, TE), and/or markup properties (e.g.
///   CR, AR, LB).
// -----------------------------------------------------------------------------
@interface SaveSgfCommand : CommandBase
{
}

/// @brief Initializes the SaveSgfCommand object. @a sgfFilePath is the full
/// path of the .sgf file to be saved. @a sgfFileAlreadyExists indicates whether
/// a file already exists at the destination.
- (id) initWithSgfFilePath:(NSString*)sgfFilePath sgfFileAlreadyExists:(bool)sgfFileAlreadyExists;

/// @brief The full path of the .sgf file to which the current game should be
/// saved. This affects the wording of some of the error messages that
/// SaveSgfCommand generates.
@property(nonatomic, retain) NSString* sgfFilePath;

/// @brief True if an .sgf file already exists at the path in @a sgfFilePath,
/// false if no .sgf file exists.
@property(nonatomic, assign) bool sgfFileAlreadyExists;

/// @brief True if the command has touched the folder to which the destination
/// .sgf file should be written. False if the command has not touched the
/// folder.
///
/// If command execution is successful this flag is always true, obviously,
/// because the .sgf file has been written to the destination folder. However,
/// if command execution fails the stage in which the error occurred determines
/// whether the destination folder has already been touched or not. In case of
/// failure this flag becomes true only at the very last stage, when the command
/// attempts to move the .sgf file from the temporary folder where it was
/// created to its final destination folder.
///
/// If @e sgfFileAlreadyExists is true this flag has the following additional
/// meaning:
/// - If command execution fails and this flag is false then the already
///   existing .sgf file still exists.
/// - If command execution fails and this flag is true then the already
///   existing .sgf file may still exist, or it may already have been deleted.
///   It is unclear which of the two is true.
/// - If command execution succeeds then this flag is always true and the
///   already existing .sgf file has been overwritten.
@property(nonatomic, assign) bool destinationFolderWasTouched;

/// @brief An error message that describes the problem why command execution
/// fails. The error message is suitable for display in the UI. Is @e nil if
/// command execution was successful.
@property(nonatomic, retain) NSString* errorMessage;

@end
