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
#import "../../ui/MBProgressHUD.h"

// Forward declarations
@class GtpCommand;
@class Player;


// -----------------------------------------------------------------------------
/// @brief The LoadGameCommand class is responsible for loading a game from an
/// .sgf file and starting a new game using the information in that file.
///
/// The sequence of operations performed by LoadGameCommand is this:
/// - Submit the "loadsgf" GTP command to the GTP engine
/// - Query the GTP engine for the information that was stored in the .sgf file
///   and that is needed to start a new game
/// - Store the information in NewGameModel
/// - Start a new game by executing a NewGameCommand instance
/// - Query the GTP engine for other information that was stored in the .sgf
///   file (handicap, komi, moves)
/// - Setup the game with the information gathered via GTP
///
/// If the @e waitUntilDone property is set to true (by default it's false) the
/// entire sequence of operations will be executed synchronously. This may take
/// a long time.
///
/// Even if synchronous execution is requested, GTP commands
/// whose responses do not yield a result that is requi
// -----------------------------------------------------------------------------
@interface LoadGameCommand : CommandBase <MBProgressHUDDelegate>
{
@private
  enum GoBoardSize m_boardSize;
  NSString* m_handicap;
  NSString* m_komi;
  NSString* m_moves;
  NSString* m_oldCurrentDirectory;
  MBProgressHUD* m_progressHUD;
}

- (id) initWithFilePath:(NSString*)aFilePath;

/// @brief Full path to the .sgf file to be loaded.
@property(retain) NSString* filePath;
@property(retain) Player* blackPlayer;
@property(retain) Player* whitePlayer;
/// @brief True if command execution should be synchronous. The default is
/// false.
@property bool waitUntilDone;

@end
