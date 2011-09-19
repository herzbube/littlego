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
#import "LoadGameCommand.h"
#import "NewGameCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../newgame/NewGameModel.h"
#import "../../player/Player.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../play/PlayView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for LoadGameCommand.
// -----------------------------------------------------------------------------
@interface LoadGameCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name GTP response handlers
//@{
- (void) loadsgfCommandResponseReceived:(GtpResponse*)response;
- (void) gopointnumbersCommandResponseReceived:(GtpResponse*)response;
- (void) getkomiCommandResponseReceived:(GtpResponse*)response;
- (void) listhandicapCommandResponseReceived:(GtpResponse*)response;
- (void) listmovesCommandResponseReceived:(GtpResponse*)response;
//@}
/// @name Helpers
//@{
- (void) handleCommandSucceeded;
- (void) handleCommandFailed;
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize;
- (void) setupHandicap:(NSString*)handicapFromGtp;
- (void) setupMoves:(NSString*)movesFromGtp;
- (void) triggerComputerPlayer;
- (void) cleanup;
- (void) showAlert;
//@}
@end


@implementation LoadGameCommand

@synthesize fileName;
@synthesize blackPlayer;
@synthesize whitePlayer;


// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFile:(NSString*)aFileName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.fileName = aFileName;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  m_boardSize = BoardSizeUndefined;
  m_komi = 0;
  m_handicap = nil;
  m_moves = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fileName = nil;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  [m_handicap release];
  [m_moves release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.fileName || ! self.blackPlayer || ! self.whitePlayer)
    return false;

  // Disable play view updates while this command executes its multiple steps
  [[PlayView sharedView] actionStarts];

  // Need to work wih temporary file whose name is known and guaranteed to not
  // contain any characters that are prohibited by GTP
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:self.fileName])
    return false;
  BOOL success = [fileManager copyItemAtPath:self.fileName toPath:sgfTemporaryFileName error:nil];
  if (! success)
    return false;
  NSString* commandString = [NSString stringWithFormat:@"loadsgf %@", sgfTemporaryFileName];
  GtpCommand* command = [GtpCommand command:commandString
                             responseTarget:self
                                   selector:@selector(loadsgfCommandResponseReceived:)];
  [command submit];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "loadsgf" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) loadsgfCommandResponseReceived:(GtpResponse*)response
{
  // Get rid of the temporary file
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager removeItemAtPath:sgfTemporaryFileName error:nil];
  if (! success)
  {
    [self handleCommandFailed];
    assert(0);
    return;
  }

  // Was GTP command successful? Failure is possible if the file we attempted
  // to load was not an .sgf file.
  if (! response.status)
  {
    [self handleCommandFailed];
    return;
  }

  // Submit the next GTP command
  GtpCommand* command = [GtpCommand command:@"go_point_numbers"
                             responseTarget:self
                                   selector:@selector(gopointnumbersCommandResponseReceived:)];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "go_point_numbers" GTP
/// command was received.
// -----------------------------------------------------------------------------
- (void) gopointnumbersCommandResponseReceived:(GtpResponse*)response
{
  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed];
    assert(0);
    return;
  }

  // Command and response are expected to look like this for a 19x19 board:
  //
  // go_point_numbers
  // = 381 382 383 384 385 386 387 388 389 390 391 392 393 394 395 396 397 398 399
  // 361 362 363 364 365 366 367 368 369 370 371 372 373 374 375 376 377 378 379
  // [...]
  // [...]
  //
  // So what we do here is simply count the lines to get the dimension of the
  // board. Not terribly sophisticated, but I have not found a better, or more
  // reliable way to query for board size.
  NSArray* responseLines = [response.parsedResponse componentsSeparatedByString:@"\n"];
  m_boardSize = [GoBoard sizeForDimension:[responseLines count]];

  // Submit the next GTP command
  GtpCommand* command = [GtpCommand command:@"get_komi"
                             responseTarget:self
                                   selector:@selector(getkomiCommandResponseReceived:)];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "get_komi" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) getkomiCommandResponseReceived:(GtpResponse*)response
{
  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed];
    assert(0);
    return;
  }

  m_komi = [response.parsedResponse doubleValue];

  // Submit the next GTP command
  GtpCommand* command = [GtpCommand command:@"list_handicap"
                             responseTarget:self
                                   selector:@selector(listhandicapCommandResponseReceived:)];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "list_handicap" GTP
/// command was received.
// -----------------------------------------------------------------------------
- (void) listhandicapCommandResponseReceived:(GtpResponse*)response
{
  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed];
    assert(0);
    return;
  }

  m_handicap = [response.parsedResponse copy];

  // Submit the next GTP command
  GtpCommand* command = [GtpCommand command:@"list_moves"
                             responseTarget:self
                                   selector:@selector(listmovesCommandResponseReceived:)];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "list_moves" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) listmovesCommandResponseReceived:(GtpResponse*)response
{
  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed];
    assert(0);
    return;
  }

  m_moves = [response.parsedResponse copy];

  [self handleCommandSucceeded];
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle successful command execution.
// -----------------------------------------------------------------------------
- (void) handleCommandSucceeded
{
  [self startNewGameForSuccessfulCommand:true boardSize:m_boardSize];
  [self setupHandicap:m_handicap];
  [self setupMoves:m_moves];
  // TODO: Add Komi
  [self triggerComputerPlayer];
  [self cleanup];
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle failed command execution.
///
/// Failure may occur during any of the steps in this command.
// -----------------------------------------------------------------------------
- (void) handleCommandFailed
{
  // Start a new game anyway, with the goal to bring the app into a controlled
  // state that matches the state of the GTP engine.
  [self startNewGameForSuccessfulCommand:false boardSize:gDefaultBoardSize];

  [self cleanup];
  [self showAlert];
}

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize
{
  // Configure NewGameModel with information that is used when NewGameCommand
  // creates a new GoGame object
  NewGameModel* model = [ApplicationDelegate sharedDelegate].newGameModel;
  model.boardSize = boardSize;
  model.blackPlayerUUID = self.blackPlayer.uuid;
  model.whitePlayerUUID = self.whitePlayer.uuid;

  NewGameCommand* command = [[NewGameCommand alloc] init];
  // If command was successful, the board was already set up by the "loadsgf"
  // GTP command. We must not setup the board again, or we will lose all moves
  // that were just loaded.
  // If command failed, we must setup the board again to bring the application
  // and the GTP engine into a defined state that matches
  if (! success)
    command.shouldSetupGtpBoard = false;
  command.shouldTriggerComputerPlayer = false;  // we have to do this ourselves after setting up handicap + moves
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the handicap for the new game, using the information in
/// @a handicapFromGtp.
///
/// Expected format for @a handicapFromGtp:
///   "vertex vertex vertex[...]"
///
/// @a handicapFromGtp may be empty to indicate that there is no handicap.
// -----------------------------------------------------------------------------
- (void) setupHandicap:(NSString*)handicapFromGtp
{
  if (0 == m_handicap.length)
    return;

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  NSArray* vertexList = [m_handicap componentsSeparatedByString:@" "];
  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:vertexList.count];
  for (NSString* vertex in vertexList)
  {
    GoPoint* point = [board pointAtVertex:vertex];
    point.stoneState = BlackStone;
    [GoUtilities movePointToNewRegion:point];
    [handicapPoints addObject:point];
  }
  game.handicapPoints = handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the moves for the new game, using the information in
/// @a movesFromGtp.
///
/// Expected format for @a movesFromGtp:
///   "color vertex, color vertex, color vertex[...]"
///
/// @a movesFromGtp may be empty to indicate that there are no moves.
// -----------------------------------------------------------------------------
- (void) setupMoves:(NSString*)movesFromGtp
{
  if (0 == m_moves.length)
    return;

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  bool hasResigned = false;
  NSArray* moveList = [m_moves componentsSeparatedByString:@", "];
  for (NSString* move in moveList)
  {
    if (hasResigned)
    {
      // If a resign move came in, it should have been the last move.
      // Our reaction to this is to simply discard any follow-up moves.
      assert(0);
      break;
    }

    NSArray* moveComponents = [move componentsSeparatedByString:@" "];
    NSString* vertexString = [[moveComponents objectAtIndex:1] lowercaseString];

    if ([vertexString isEqualToString:@"pass"])
      [game pass];
    else if ([vertexString isEqualToString:@"resign"])  // not sure if this is ever sent
    {
      [game resign];
      hasResigned = true;
    }
    else
    {
      GoPoint* point = [board pointAtVertex:vertexString];
      [game play:point];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayer
{
  if ([[GoGame sharedGame] isComputerPlayersTurn])
  {
    ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
    [command submit];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs mandatory cleanup steps. This method is intended to be
/// invoked just before the command finishes executing.
// -----------------------------------------------------------------------------
- (void) cleanup
{
  // Re-enable play view updates
  [[PlayView sharedView] actionEnds];
}

// -----------------------------------------------------------------------------
/// @brief Displays alert with "failed to load game" message.
// -----------------------------------------------------------------------------
- (void) showAlert
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to load game"
                                                  message:@"The archived game could not be loaded. Is the game file in .sgf format?"
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = LoadGameFailedAlertView;
  [alert show];
}

@end
