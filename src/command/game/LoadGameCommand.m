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
#import "../../main/ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../gtp/GtpUtilities.h"
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
/// @name MBProgressHUDDelegate protocol
//@{
- (void) hudWasHidden:(MBProgressHUD*)progressHUD;
//@}
/// @name Helpers
//@{
- (void) handleCommandSucceeded;
- (void) handleCommandFailed;
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize;
- (void) setupHandicap:(NSString*)handicapFromGtp;
- (void) setupKomi:(NSString*)komiFromGtp;
- (void) setupMoves:(NSString*)movesFromGtp;
- (void) triggerComputerPlayer;
- (void) cleanup;
- (void) showAlert;
- (void) replayMoves:(NSArray*)moveList;
//@}
@end


@implementation LoadGameCommand

@synthesize filePath;
@synthesize blackPlayer;
@synthesize whitePlayer;
@synthesize gameName;
@synthesize waitUntilDone;


// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFilePath:(NSString*)aFilePath gameName:(NSString*)aGameName
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.filePath = aFilePath;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  self.gameName = aGameName;
  self.waitUntilDone = false;
  m_boardSize = GoBoardSizeUndefined;
  m_handicap = nil;
  m_komi = nil;
  m_moves = nil;
  m_oldCurrentDirectory = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.filePath = nil;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  self.gameName = nil;
  [m_handicap release];
  [m_komi release];
  [m_moves release];
  [m_oldCurrentDirectory release];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.filePath || ! self.blackPlayer || ! self.whitePlayer)
    return false;

  // Disable play view updates while this command executes its multiple steps
  [[PlayView sharedView] actionStarts];

  // Need to work with temporary file whose name is known and guaranteed to not
  // contain any characters that are prohibited by GTP
  NSString* temporaryDirectory = NSTemporaryDirectory();
  NSString* sgfTemporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:self.filePath])
  {
    [self handleCommandFailed];
    return false;
  }
  // Get rid of the temporary file if it exists, otherwise copyItemAtPath:()
  // further down will abort the copy attempt. A temporary file possibly exists
  // if a previous file operation failed to properly clean up.
  if ([fileManager fileExistsAtPath:sgfTemporaryFilePath])
  {
    NSError* error;
    BOOL success = [fileManager removeItemAtPath:sgfTemporaryFileName error:&error];
    if (! success)
    {
      DDLogError(@"LoadGameCommand::doIt(): Failed to remove temporary file %@, reason: %@", sgfTemporaryFileName, [error localizedDescription]);
      [self handleCommandFailed];
      return false;
    }
  }
  BOOL success = [fileManager copyItemAtPath:self.filePath toPath:sgfTemporaryFilePath error:nil];
  if (! success)
  {
    [self handleCommandFailed];
    return false;
  }

  m_oldCurrentDirectory = [[fileManager currentDirectoryPath] retain];
  [fileManager changeCurrentDirectoryPath:temporaryDirectory];
  // Use the file *NAME* without the path
  NSString* commandString = [NSString stringWithFormat:@"loadsgf %@", sgfTemporaryFileName];
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(loadsgfCommandResponseReceived:)
                waitUntilDone:self.waitUntilDone];

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
  [fileManager changeCurrentDirectoryPath:m_oldCurrentDirectory];
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
  NSString* commandString = @"go_point_numbers";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(gopointnumbersCommandResponseReceived:)
                waitUntilDone:self.waitUntilDone];
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
  NSString* commandString = @"get_komi";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(getkomiCommandResponseReceived:)
                waitUntilDone:self.waitUntilDone];
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

  m_komi = [response.parsedResponse copy];

  // Submit the next GTP command
  NSString* commandString = @"list_handicap";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(listhandicapCommandResponseReceived:)
                waitUntilDone:self.waitUntilDone];
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
  NSString* commandString = @"list_moves";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(listmovesCommandResponseReceived:)
                waitUntilDone:self.waitUntilDone];
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
  [self setupKomi:m_komi];
  [self setupMoves:m_moves];
  [[NSNotificationCenter defaultCenter] postNotificationName:gameLoadedFromArchive object:self.gameName];
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
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  model.boardSize = boardSize;
  model.blackPlayerUUID = self.blackPlayer.uuid;
  model.whitePlayerUUID = self.whitePlayer.uuid;

  NewGameCommand* command = [[NewGameCommand alloc] init];
  // If command was successful, the board was already set up by the "loadsgf"
  // GTP command. We must not setup the board again, or we will lose all moves
  // that were just loaded.
  // If command failed, we must setup the board again to bring the application
  // and the GTP engine into a defined state
  command.shouldSetupGtpBoard = (! success);
  // Ditto for handicap and komi
  command.shouldSetupGtpHandicapAndKomi = (! success);
  command.shouldTriggerComputerPlayer = false;  // we have to do this ourselves after setting up handicap + moves
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Sets up handicap for the new game, using the information in
/// @a handicapFromGtp.
///
/// Expected format for @a handicapFromGtp is: "vertex vertex vertex[...]"
///
/// @a handicapFromGtp may be empty to indicate that there is no handicap.
// -----------------------------------------------------------------------------
- (void) setupHandicap:(NSString*)handicapFromGtp
{
  GoGame* game = [GoGame sharedGame];
  NSMutableArray* handicapPoints = [NSMutableArray arrayWithCapacity:0];
  if (0 == handicapFromGtp.length)
  {
    // do nothing, just leave the empty array to be applied to the GoGame
    // instance; this is important because the GoGame instance might have been
    // set up by NewGameCommand with a different default handicap
  }
  else
  {
    GoBoard* board = game.board;
    NSArray* handicapVertices = [handicapFromGtp componentsSeparatedByString:@" "];
    for (NSString* vertex in handicapVertices)
    {
      GoPoint* point = [board pointAtVertex:vertex];
      [handicapPoints addObject:point];
    }
  }
  // GoGame takes care to place black stones on the points
  game.handicapPoints = handicapPoints;
}

// -----------------------------------------------------------------------------
/// @brief Sets up komi for the new game, using the information in
/// @a komiFromGtp.
///
/// Expected format for @a komiFromGtp is a fractional number (e.g. "6.5").
///
/// @a komiFromGtp may be empty to indicate that there is no komi.
// -----------------------------------------------------------------------------
- (void) setupKomi:(NSString*)komiFromGtp
{
  double komi;
  if (0 == komiFromGtp.length)
    komi = 0;
  else
    komi = [komiFromGtp doubleValue];

  GoGame* game = [GoGame sharedGame];
  game.komi = komi;
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
  if (0 == movesFromGtp.length)
    return;
  NSArray* moveList = [movesFromGtp componentsSeparatedByString:@", "];

  UIView* theSuperView = [ApplicationDelegate sharedDelegate].tabBarController.view;
	m_progressHUD = [[MBProgressHUD alloc] initWithView:theSuperView];
	[theSuperView addSubview:m_progressHUD];
	// Set determinate mode
	m_progressHUD.mode = MBProgressHUDModeDeterminate;
	m_progressHUD.determinateStyle = MBDeterminateStyleBar;
	m_progressHUD.dimBackground = YES;
	m_progressHUD.delegate = self;
	m_progressHUD.labelText = @"Loading game...";
	[m_progressHUD showWhileExecuting:@selector(replayMoves:) onTarget:self withObject:moveList animated:YES];

  [self retain];
}

// -----------------------------------------------------------------------------
/// @brief Replays the moves in @a moveList.
///
/// @a moveList is expected to contain NSString objects, each having the format
/// "color vertex" (e.g. "W C13").
///
/// @note This method runs in a secondary thread. For every move that is
/// replayed, the progress view in @e m_progressHUD is updated by one step.
// -----------------------------------------------------------------------------
- (void) replayMoves:(NSArray*)moveList
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  int totalSteps = moveList.count;
  float stepIncrease = 1.0 / totalSteps;
  float progress = 0.0;

  bool hasResigned = false;
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

    progress += stepIncrease;
    m_progressHUD.progress = progress;
  }
}

// -----------------------------------------------------------------------------
/// @brief MBProgressHUDDelegate method
// -----------------------------------------------------------------------------
- (void) hudWasHidden:(MBProgressHUD*)progressHUD
{
  [progressHUD removeFromSuperview];
  [progressHUD release];
  [self autorelease];
  [self triggerComputerPlayer];
  [self cleanup];
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
  alert.tag = AlertViewTypeLoadGameFailed;
  [alert show];
}

@end
