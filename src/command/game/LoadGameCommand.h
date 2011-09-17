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
// -----------------------------------------------------------------------------
@interface LoadGameCommand : CommandBase
{
@private
  int m_boardDimension;
  double m_komi;
  NSString* m_handicap;
  NSString* m_moves;
}

- (id) initWithFile:(NSString*)aFileName;

@property(retain) NSString* fileName;
@property(retain) Player* blackPlayer;
@property(retain) Player* whitePlayer;

@end
