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
#import "LoadGameCommand.h"
#import "NewGameCommand.h"
#import "../backup/BackupGameCommand.h"
#import "../backup/CleanBackupCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../newgame/NewGameModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"


static const int maxStepsForReplayMoves = 10;

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
- (void) handleCommandFailed:(NSString*)message;
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize;
- (void) setupHandicap:(NSString*)handicapFromGtp;
- (void) setupKomi:(NSString*)komiFromGtp;
- (void) setupMoves:(NSString*)movesFromGtp;
- (void) triggerComputerPlayer;
- (void) showAlert:(NSString*)message;
- (void) replayMoves:(NSArray*)moveList;
//@}
/// @name Private properties
//@{
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
//@}
@end


@implementation LoadGameCommand

@synthesize asynchronousCommandDelegate;


// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the .sgf file
/// identified by the full file path @a filePath.
///
/// @note This is the designated initializer of LoadGameCommand.
// -----------------------------------------------------------------------------
- (id) initWithFilePath:(NSString*)filePath
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.filePath = filePath;
  self.restoreMode = false;
  self.didTriggerComputerPlayer = false;
  m_boardSize = GoBoardSizeUndefined;
  m_handicap = nil;
  m_komi = nil;
  m_moves = nil;
  m_oldCurrentDirectory = nil;
  self.totalSteps = (6 + maxStepsForReplayMoves);  // 6 fixed steps for GTP commands
  self.stepIncrease = 1.0 / self.totalSteps;
  self.progress = 0.0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a LoadGameCommand object that will load the .sgf file
/// from the archive that is identified by @a gameName.
// -----------------------------------------------------------------------------
- (id) initWithGameName:(NSString*)gameName
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  return [self initWithFilePath:[model filePathForGameWithName:gameName]];
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LoadGameCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.filePath = nil;
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
  if (! self.filePath)
  {
    DDLogError(@"%@: No file provided", [self shortDescription]);
    return false;
  }

  @try
  {
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionStarts
            waitUntilDone:YES];

    NSString* message;
    if (self.restoreMode)
      message = @"Restoring game...";
    else
      message = @"Loading game...";
    [self.asynchronousCommandDelegate asynchronousCommand:self
                                              didProgress:0.0
                                          nextStepMessage:message];

    [GtpUtilities stopPondering];

    // Need to work with temporary file whose name is known and guaranteed to not
    // contain any characters that are prohibited by GTP
    NSString* temporaryDirectory = NSTemporaryDirectory();
    NSString* sgfTemporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (! [fileManager fileExistsAtPath:self.filePath])
    {
      [self handleCommandFailed:@"Internal error: Archived .sgf file not found"];
      return false;
    }
    // Get rid of the temporary file if it exists, otherwise copyItemAtPath:()
    // further down will abort the copy attempt. A temporary file possibly exists
    // if a previous file operation failed to properly clean up.
    NSError* error;
    if ([fileManager fileExistsAtPath:sgfTemporaryFilePath])
    {
      BOOL success = [fileManager removeItemAtPath:sgfTemporaryFilePath error:&error];
      if (! success)
      {
        [self handleCommandFailed:[NSString stringWithFormat:@"Internal error: Failed to remove temporary file before load, reason: %@", [error localizedDescription]]];
        return false;
      }
    }
    BOOL success = [fileManager copyItemAtPath:self.filePath toPath:sgfTemporaryFilePath error:&error];
    if (! success)
    {
      [self handleCommandFailed:[NSString stringWithFormat:@"Internal error: Failed to copy archived .sgf file, reason: %@", [error localizedDescription]]];
      return false;
    }

    m_oldCurrentDirectory = [[fileManager currentDirectoryPath] retain];
    [fileManager changeCurrentDirectoryPath:temporaryDirectory];
    // Use the file *NAME* without the path
    NSString* commandString = [NSString stringWithFormat:@"loadsgf %@", sgfTemporaryFileName];
    [GtpUtilities submitCommand:commandString
                         target:self
                       selector:@selector(loadsgfCommandResponseReceived:)
                  waitUntilDone:true];

    return true;
  }
  @finally
  {
    [self performSelector:@selector(postLongRunningNotificationOnMainThread:)
                 onThread:[NSThread mainThread]
               withObject:longRunningActionEnds
            waitUntilDone:YES];
  }
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "loadsgf" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) loadsgfCommandResponseReceived:(GtpResponse*)response
{
  [self increaseProgressAndNotifyDelegate];

  // Get rid of the temporary file
  NSError* error;
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager removeItemAtPath:sgfTemporaryFileName error:&error];
  [fileManager changeCurrentDirectoryPath:m_oldCurrentDirectory];
  if (! success)
  {
    [self handleCommandFailed:[NSString stringWithFormat:@"Internal error: Failed to remove temporary file after load, reason: %@", [error localizedDescription]]];
    assert(0);
    return;
  }

  // Was GTP command successful? Failure is possible if the file we attempted
  // to load was not an .sgf file.
  if (! response.status)
  {
    // This is the most probable error scenario, so no "Internal error"
    [self handleCommandFailed:@"The archived game could not be loaded. Is the game file in .sgf format?"];
    return;
  }

  // Submit the next GTP command
  NSString* commandString = @"go_point_numbers";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(gopointnumbersCommandResponseReceived:)
                waitUntilDone:true];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "go_point_numbers" GTP
/// command was received.
// -----------------------------------------------------------------------------
- (void) gopointnumbersCommandResponseReceived:(GtpResponse*)response
{
  [self increaseProgressAndNotifyDelegate];

  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed:@"Internal error: Failed to detect board size of archived game"];
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
  // So what we do here is simply count the lines to get the size of the board.
  // Not terribly sophisticated, but I have not found a better, or more
  // reliable way to query for board size.
  NSArray* responseLines = [response.parsedResponse componentsSeparatedByString:@"\n"];
  m_boardSize = responseLines.count;

  // Submit the next GTP command
  NSString* commandString = @"get_komi";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(getkomiCommandResponseReceived:)
                waitUntilDone:true];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "get_komi" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) getkomiCommandResponseReceived:(GtpResponse*)response
{
  [self increaseProgressAndNotifyDelegate];

  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed:@"Internal error: Failed to detect komi of archived game"];
    assert(0);
    return;
  }

  m_komi = [response.parsedResponse copy];

  // Submit the next GTP command
  NSString* commandString = @"list_handicap";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(listhandicapCommandResponseReceived:)
                waitUntilDone:true];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "list_handicap" GTP
/// command was received.
// -----------------------------------------------------------------------------
- (void) listhandicapCommandResponseReceived:(GtpResponse*)response
{
  [self increaseProgressAndNotifyDelegate];

  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed:@"Internal error: Failed to detect handicap of archived game"];
    assert(0);
    return;
  }

  m_handicap = [response.parsedResponse copy];

  // Submit the next GTP command
  NSString* commandString = @"list_moves";
  [GtpUtilities submitCommand:commandString
                       target:self
                     selector:@selector(listmovesCommandResponseReceived:)
                waitUntilDone:true];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for the "list_moves" GTP command
/// was received.
// -----------------------------------------------------------------------------
- (void) listmovesCommandResponseReceived:(GtpResponse*)response
{
  [self increaseProgressAndNotifyDelegate];

  // Was GTP command successful?
  if (! response.status)
  {
    [self handleCommandFailed:@"Internal error: Failed to detect moves of archived game"];
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
  [self increaseProgressAndNotifyDelegate];
  [self startNewGameForSuccessfulCommand:true boardSize:m_boardSize];
  [self setupHandicap:m_handicap];
  [self setupKomi:m_komi];
  [self setupMoves:m_moves];
  if (self.restoreMode)
  {
    // Can't invoke notifyGoGameDocument 1) because we are not loading from the
    // archive so we don't have an archive game name; and 2) because we don't
    // know whether the restored game has previously been saved, so we also
    // cannot save the document dirty flag. The consequences: The document dirty
    // flag remains set (which will cause a warning when the next new game is
    // started), and the document name remains uninitialized (which will make
    // it appear to anybody who evaluates the document name as if the game has
    // has never been saved before).

    // No need to create a backup, we already have the one we are restoring from
  }
  else
  {
    [self notifyGoGameDocument];
    [[[[BackupGameCommand alloc] init] autorelease] submit];
  }
  [GtpUtilities setupComputerPlayer];
  [self triggerComputerPlayer];
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle failed command execution.
///
/// Failure may occur during any of the steps in this command. An alert with
/// @a message is displayed to notify the user of the problem. In addition, the
/// message is written to the application log.
// -----------------------------------------------------------------------------
- (void) handleCommandFailed:(NSString*)message
{
  // Start a new game anyway, with the goal to bring the app into a controlled
  // state that matches the state of the GTP engine.
  [self startNewGameForSuccessfulCommand:false boardSize:gDefaultBoardSize];

  // Alert must be shown on main thread, otherwise there is the possibility of
  // a crash (it's real, I've seen the crash reports!)
  [self performSelectorOnMainThread:@selector(showAlert:) withObject:message waitUntilDone:YES];
  DDLogError(@"%@", message);
}

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (void) startNewGameForSuccessfulCommand:(bool)success boardSize:(enum GoBoardSize)boardSize
{
  // Temporarily re-configure NewGameModel with the new board size from the
  // loaded game
  NewGameModel* model = [ApplicationDelegate sharedDelegate].theNewGameModel;
  enum GoBoardSize oldBoardSize = model.boardSize;
  model.boardSize = boardSize;

  if (self.restoreMode)
  {
    // Since we are restoring from a backup we want to keep it
  }
  else
  {
    // Delete the current backup, a new backup with the moves from the archive
    // we are currently loading will be made later on
    [[[[CleanBackupCommand alloc] init] autorelease] submit];
  }
  NewGameCommand* command = [[[NewGameCommand alloc] init] autorelease];
  // If command was successful, the board was already set up by the "loadsgf"
  // GTP command. We must not setup the board again, or we will lose all moves
  // that were just loaded.
  // If command failed, we must setup the board again to bring the application
  // and the GTP engine into a defined state
  command.shouldSetupGtpBoard = (! success);
  // Ditto for handicap and komi
  command.shouldSetupGtpHandicapAndKomi = (! success);
  // We have to do this ourselves, after setting up handicap + moves
  command.shouldTriggerComputerPlayer = false;
  // We want the load game command to proceed as quickly as possible, therefore
  // we set up the computer player ourselves, at the very end just before we
  // trigger the computer player. If we would allow the computer player to be
  // set up earlier, it might start pondering, taking away precious CPU cycles
  // from the already slow load game command.
  command.shouldSetupComputerPlayer = false;
  [command submit];

  // Restore the original board size (is a user preference which should should
  // not be overwritten by the loaded game's setting)
  model.boardSize = oldBoardSize;
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
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupMoves:(NSString*)movesFromGtp
{
  NSArray* moveList;
  if (0 == movesFromGtp.length)
    moveList = [NSArray array];
  else
    moveList = [movesFromGtp componentsSeparatedByString:@", "];
  [self replayMoves:moveList];
}

// -----------------------------------------------------------------------------
/// @brief Replays the moves in @a moveList.
///
/// @a moveList is expected to contain NSString objects, each having the format
/// "color vertex" (e.g. "W C13").
///
/// The asynchronous command delegate is updated continuously with progress
/// information as the moves are replayed. In an ideal world we would have
/// fine-grained progress updates with as many steps as there are moves.
/// However, when there are many moves to be replayed this wastes a lot of
/// precious CPU cycles for GUI updates, considerably slowing down the process
/// of loading a game - on older devices to an intolerable level. In the real
/// world, we therefore limit the number of progress updates to a fixed,
/// hard-coded number.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) replayMoves:(NSArray*)moveList
{
  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  float movesPerStep;
  int remainingNumberOfSteps;
  if (moveList.count <= maxStepsForReplayMoves)
  {
    movesPerStep = 1;
    remainingNumberOfSteps = moveList.count;
  }
  else
  {
    movesPerStep = moveList.count / maxStepsForReplayMoves;
    remainingNumberOfSteps = maxStepsForReplayMoves;
  }
  float remainingProgress = 1.0 - self.progress;
  // Adjust for increaseProgressAndNotifyDelegate()
  self.stepIncrease = remainingProgress / remainingNumberOfSteps;

  @try
  {
    bool hasResigned = false;
    int movesReplayed = 0;
    float nextProgressUpdate = movesPerStep;  // use float in case movesPerStep has fractions
    for (NSString* move in moveList)
    {
      if (hasResigned)
      {
        DDLogError(@"%@: One or more moves after resign, discarding this and any follow-up moves", [self shortDescription]);
        assert(0);
        break;
      }

      NSArray* moveComponents = [move componentsSeparatedByString:@" "];
      NSString* colorString = [[moveComponents objectAtIndex:0] lowercaseString];
      NSString* vertexString = [[moveComponents objectAtIndex:1] lowercaseString];


      // Sanitary check 1: Is the move by the correct player?
      NSString* expectedColorString;
      NSString* expectedColorName;
      NSString* otherColorName;
      if ([game currentPlayer].isBlack)
      {
        expectedColorString = @"b";
        expectedColorName = @"Black";
        otherColorName = @"White";
      }
      else
      {
        expectedColorString = @"w";
        expectedColorName = @"White";
        otherColorName = @"Black";
      }
      if (! [colorString isEqualToString:expectedColorString])
      {
        NSString* errorMessageFormat = @"Game contains a move by the wrong player: Move %d, should have been played by %@, but was played by %@.";
        NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, (movesReplayed + 1), expectedColorName, otherColorName];
        [self handleCommandFailed:errorMessage];
        return;
      }
      // End sanitary check 1

      
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
        
        // Sanitary check 2: Is the move legal?
        if (! [game isLegalMove:point])
        {
          NSString* errorMessageFormat = @"Game contains an illegal move: Move %d, played by %@, on intersection %@.";
          NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, (movesReplayed + 1), expectedColorName, [vertexString uppercaseString]];
          [self handleCommandFailed:errorMessage];
          return;
        }
        // End sanitary check 2

        [game play:point];
      }
      ++movesReplayed;

      if (movesReplayed >= nextProgressUpdate)
      {
        nextProgressUpdate += movesPerStep;
        [self increaseProgressAndNotifyDelegate];
      }
    }
  }
  @catch (NSException* exception)
  {
    NSString* errorMessageFormat = @"An unexpected error occurred loading the game. To improve this app, please consider submitting a bug report, if possible with the game file attached.\n\nException name: %@.\n\nException reason: %@.";
    NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, [exception name], [exception reason]];
    [self handleCommandFailed:errorMessage];
    return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Notifies the GoGameDocument associated with the new game that the
/// game was loaded.
// -----------------------------------------------------------------------------
- (void) notifyGoGameDocument
{
  NSString* gameName = [[self.filePath lastPathComponent] stringByDeletingPathExtension];
  [[GoGame sharedGame].document load:gameName];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the computer player to make a move, if it is his turn.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayer
{
  GoGame* game = [GoGame sharedGame];
  if ([game isComputerPlayersTurn])
  {
    if (self.restoreMode)
    {
      // On application launch we want to be able to restore the board position
      // last viewed by the user, so we never trigger the computer player.
      if (GoGameTypeComputerVsComputer == game.type)
        [game pause];
    }
    else
    {
      [[[[ComputerPlayMoveCommand alloc] init] autorelease] submit];
      self.didTriggerComputerPlayer = true;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays "failed to load game" alert with the error details stored
/// in @a message.
// -----------------------------------------------------------------------------
- (void) showAlert:(NSString*)message
{
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Failed to load game"
                                                  message:message
                                                 delegate:nil
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = AlertViewTypeLoadGameFailed;
  [alert show];
  [alert release];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for various methods.
// -----------------------------------------------------------------------------
- (void) increaseProgressAndNotifyDelegate
{
  self.progress += self.stepIncrease;
  [self.asynchronousCommandDelegate asynchronousCommand:self didProgress:self.progress nextStepMessage:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Is invoked in the context of the main thread.
// -----------------------------------------------------------------------------
- (void) postLongRunningNotificationOnMainThread:(NSString*)notificationName
{
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

@end
