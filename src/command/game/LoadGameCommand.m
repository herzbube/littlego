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
#import "LoadGameCommand.h"
#import "NewGameCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../backup/CleanBackupSgfCommand.h"
#import "../move/ComputerPlayMoveCommand.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoGameDocument.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpResponse.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpUtilities.h"
#import "../../main/ApplicationDelegate.h"
#import "../../newgame/NewGameModel.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/PathUtilities.h"

// Constants
static const int maxStepsForReplayMoves = 10;

/// @brief Enumerates possible results of parsing a move string provided by
/// Fuego.
enum ParseMoveStringResult
{
  ParseMoveStringResultSuccess,
  ParseMoveStringResultInvalidFormat,
  ParseMoveStringResultInvalidColor,
  ParseMoveStringResultInvalidVertex
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for LoadGameCommand.
// -----------------------------------------------------------------------------
@interface LoadGameCommand()
@property(nonatomic, assign) int totalSteps;
@property(nonatomic, assign) float stepIncrease;
@property(nonatomic, assign) float progress;
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
  m_setup = nil;
  m_setupPlayer = nil;
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
  [m_setup release];
  [m_setupPlayer release];
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
  DDLogVerbose(@"%@: Loading .sgf file %@", [self shortDescription], self.filePath);

  bool runToCompletion = false;
  NSString* errorMessage = @"Internal error";
  @try
  {
    [[LongRunningActionCounter sharedCounter] increment];
    [self setupProgressHUD];
    [GtpUtilities stopPondering];
    bool success = [self doGtpStuff:&errorMessage];
    if (! success)
      return false;
    @try
    {
      [[ApplicationStateManager sharedManager] beginSavePoint];
      [self increaseProgressAndNotifyDelegate];
      [self setupGoGame];
      runToCompletion = true;
      return true;
    }
    @finally
    {
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
      [[ApplicationStateManager sharedManager] commitSavePoint];
    }
  }
  @finally
  {
    if (! runToCompletion)
      [self handleCommandFailed:errorMessage];
    [[LongRunningActionCounter sharedCounter] decrement];
  }

  // We should never get here - unless an exception occurs, all paths in the
  // @try block above should return either true or false
  assert(0);
  return false;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (void) setupProgressHUD
{
  NSString* message;
  if (self.restoreMode)
    message = @"Restoring game...";
  else
    message = @"Loading game...";
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:message];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) doGtpStuff:(NSString**)errorMessage
{
  bool success = [self copyArchiveToTempFile:errorMessage];
  if (! success)
    return false;
  success = [self loadSgf:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self removeTempFile:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForBoardSize:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForKomi:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForHandicap:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForSetup:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForSetupPlayer:errorMessage];
  if (! success)
    return false;
  [self increaseProgressAndNotifyDelegate];
  success = [self askGtpEngineForMoves:errorMessage];
  if (! success)
    return false;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) copyArchiveToTempFile:(NSString**)errorMessage
{
  // Need to work with temporary file whose name is known and guaranteed to not
  // contain any characters that are prohibited by GTP
  NSString* temporaryDirectory = NSTemporaryDirectory();
  NSString* sgfTemporaryFilePath = [temporaryDirectory stringByAppendingPathComponent:sgfTemporaryFileName];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  if (! [fileManager fileExistsAtPath:self.filePath])
  {
    *errorMessage = @"Internal error: .sgf file not found";
    return false;
  }
  NSError* error;
  BOOL success = [PathUtilities copyItemAtPath:self.filePath overwritePath:sgfTemporaryFilePath error:&error];
  if (! success)
  {
    *errorMessage = [NSString stringWithFormat:@"Internal error: Failed to copy .sgf file, reason: %@", [error localizedDescription]];
    return false;
  }
  m_oldCurrentDirectory = [[fileManager currentDirectoryPath] retain];
  [fileManager changeCurrentDirectoryPath:temporaryDirectory];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) loadSgf:(NSString**)errorMessage
{
  // Use the file *NAME* without the path
  NSString* commandString = [NSString stringWithFormat:@"loadsgf %@", sgfTemporaryFileName];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"The game could not be loaded. Does the game use a board that is too large (maximum board size is 19)? Is the game file in .sgf format?";
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) removeTempFile:(NSString**)errorMessage
{
  NSError* error;
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL success = [fileManager removeItemAtPath:sgfTemporaryFileName error:&error];
  [fileManager changeCurrentDirectoryPath:m_oldCurrentDirectory];
  if (! success)
  {
    *errorMessage = [NSString stringWithFormat:@"Internal error: Failed to remove temporary file after load, reason: %@", [error localizedDescription]];
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForBoardSize:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"go_point_numbers"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect board size of the game to be loaded";
    return false;
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
  NSArray* responseLines = [command.response.parsedResponse componentsSeparatedByString:@"\n"];
  // Cast is required because NSUInteger and int (the underlying type of enums)
  // differ in size in 64-bit.
  m_boardSize = (enum GoBoardSize)responseLines.count;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForKomi:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"get_komi"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect komi of the game to be loaded";
    return false;
  }
  m_komi = [command.response.parsedResponse copy];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForHandicap:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"list_handicap"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect handicap of the game to be loaded";
    return false;
  }
  m_handicap = [command.response.parsedResponse copy];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForSetup:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"list_setup"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect setup of the game to be loaded";
    return false;
  }
  m_setup = [command.response.parsedResponse copy];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForSetupPlayer:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"list_setup_player"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect setup player of the game to be loaded";
    return false;
  }
  m_setupPlayer = [command.response.parsedResponse copy];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (bool) askGtpEngineForMoves:(NSString**)errorMessage
{
  GtpCommand* command = [GtpCommand command:@"list_moves"];
  [command submit];
  if (! command.response.status)
  {
    *errorMessage = @"Internal error: Failed to detect moves of the game to be loaded";
    return false;
  }
  m_moves = [command.response.parsedResponse copy];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (void) setupGoGame
{
  // The following sequence must always be run in its entirety. If an error
  // occurs it is handled right at the source and is never escalated to this
  // method. In practice, this can only happen when setupSetup:() encounters
  // an illegal setup or setupMoves:() encounters illegal moves. If an error
  // occurs, handleCommandFailed:() is invoked behind our back to set up a new
  // clean game. All game characteristics that have been set up to then are
  // discarded.
  [self startNewGameForSuccessfulCommand:true boardSize:m_boardSize];
  [self setupHandicap:m_handicap];
  [self setupSetup:m_setup];
  [self setupSetupPlayer:m_setupPlayer];
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
    [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  }
  [GtpUtilities setupComputerPlayer];
  [self performSelector:@selector(triggerComputerPlayerOnMainThread)
               onThread:[NSThread mainThread]
             withObject:nil
          waitUntilDone:YES];
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
    [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
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
/// @brief Sets up the setup stones prior to the first move of the game, using
/// the information in @a setupFromGtp.
///
/// Expected format for @a setupFromGtp:
///   "color vertex, color vertex, color vertex[...]"
///
/// @a setupFromGtp may be empty to indicate that there are no stones to set up.
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupSetup:(NSString*)setupFromGtp
{
  if (setupFromGtp.length == 0)
    return;

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;
  NSArray* handicapPoints = game.handicapPoints;

  NSMutableArray* blackSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* whiteSetupPoints = [NSMutableArray arrayWithCapacity:0];
  NSMutableArray* setupVertexes = [NSMutableArray arrayWithCapacity:0];
  NSArray* setupStoneStrings = [setupFromGtp componentsSeparatedByString:@", "];

  for (NSString* setupStoneString in setupStoneStrings)
  {
    NSArray* setupStoneStringComponents = [setupStoneString componentsSeparatedByString:@" "];

    NSString* colorString = [setupStoneStringComponents objectAtIndex:0];
    NSString* vertexString = [setupStoneStringComponents objectAtIndex:1];

    enum GoColor stoneColor;
    bool success = [self parseColorString:colorString
                                    color:&stoneColor];
    if (! success)
    {
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe stone at intersection %@ has an invalid color. Invalid color designation: %@. Supported are 'B' for black and 'W' for white.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString, colorString];
      [self handleCommandFailed:errorMessage];
      return;
    }

    GoPoint* point;
    @try
    {
      point = [board pointAtVertex:vertexString];
    }
    @catch (NSException* exception)
    {
      // If the vertex is not legal an exception is raised:
      // - NSInvalidArgumentException if vertex is malformed
      // - NSRangeException if vertex compounds are out of range
      // For our purposes, both exception types are the same.
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe intersection %@ is invalid.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString];
      [self handleCommandFailed:errorMessage];
      return;
    }

    // Fuego should not list stones twice - if two different SGF setup
    // properties set up the same intersection Fuego should only list the
    // last setup. We perform the check anyway, to be on the safe side.
    if ([setupVertexes containsObject:point.vertex.string])
    {
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nAn intersection must be set up with a stone only once, but intersection %@ is set up with a stone at least twice.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString];
      [self handleCommandFailed:errorMessage];
      return;
    }
    [setupVertexes addObject:point.vertex.string];

    if ([handicapPoints containsObject:point])
    {
      NSString* colorName = [[NSString stringWithGoColor:stoneColor] lowercaseString];
      NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\nThe intersection %@ is set up with a %@ stone although it is already occupied by a black handicap stone.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, vertexString, colorName];
      [self handleCommandFailed:errorMessage];
      return;
    }

    if (stoneColor == GoColorBlack)
      [blackSetupPoints addObject:point];
    else
      [whiteSetupPoints addObject:point];
  }

  @try
  {
    // GoGame takes care to place black and white stones on the points
    game.blackSetupPoints = blackSetupPoints;
    game.whiteSetupPoints = whiteSetupPoints;
  }
  @catch (NSException* exception)
  {
    // This can happen if the setup results in a position where a stone has
    // 0 (zero) liberties
    NSString* errorMessageFormat = @"Game contains an invalid board setup prior to the first move.\n\n%@";
    NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, exception.reason];
    [self handleCommandFailed:errorMessage];
    return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up the player to play first for the new game, using the
/// information in @a setupPlayerFromGtp.
///
/// Expected format for @a setupPlayerFromGtp is: "B" or "W"
///
/// @a setupPlayerFromGtp may be empty to indicate that no player is set up to
/// play first. In that case, since there is no explicit setup, the game logic
/// determines the player who plays first (e.g. in a normal game with no
/// handicap, black plays first).
///
/// @note If an error occurs while this method runs, handleCommandFailed:() is
/// invoked with an appropriate error message.
// -----------------------------------------------------------------------------
- (void) setupSetupPlayer:(NSString*)setupPlayerFromGtp
{
  enum GoColor setupFirstMoveColor;
  if (0 == setupPlayerFromGtp.length)
  {
    setupFirstMoveColor = GoColorNone;
  }
  else
  {
    bool success = [self parseColorString:setupPlayerFromGtp
                                    color:&setupFirstMoveColor];
    if (! success)
    {
      NSString* errorMessageFormat = @"Game attempts to set up an invalid player to play the first move. Invalid player designation: %@. Supported are 'B' for black and 'W' for white.";
      NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, setupPlayerFromGtp];
      [self handleCommandFailed:errorMessage];
      return;
    }
  }

  GoGame* game = [GoGame sharedGame];
  game.setupFirstMoveColor = setupFirstMoveColor;
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

  float movesPerStep;
  NSUInteger remainingNumberOfSteps;
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
    int movesReplayed = 0;
    float nextProgressUpdate = movesPerStep;  // use float in case movesPerStep has fractions
    for (NSString* moveString in moveList)
    {
      enum GoColor moveColor;
      bool isResignMove;
      enum GoMoveType moveType;
      GoPoint* point;
      enum ParseMoveStringResult result = [self parseMoveString:moveString
                                                      moveColor:&moveColor
                                           isResignMove:&isResignMove
                                                       moveType:&moveType
                                                          point:&point];
      if (ParseMoveStringResultSuccess != result)
      {
        [self handleInvalidMoveString:moveString parseMoveStringResult:result];
        return;
      }

      // Here we support if the .sgf contains moves by non-alternating colors,
      // anywhere in the game. Thus the user can ***VIEW*** almost any .sgf
      // game, even though the app itself is not capable of producing such
      // games.
      game.nextMoveColor = moveColor;

      NSString* colorName = [NSString stringWithGoColor:moveColor];
      if (isResignMove)
      {
        if (GoGameStateGameHasEnded == game.state)
        {
          NSString* errorMessageFormat = @"Game contains a resignation after the game has already ended (%@): Move %d, played by %@.";
          NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName];
          [self handleCommandFailed:errorMessage];
          return;
        }
        [game resign];
      }
      else
      {
        if (GoGameStateGameHasEnded == game.state)
        {
          if (GoGameHasEndedReasonTwoPasses != game.reasonForGameHasEnded)
          {
            NSString* errorMessage;
            if (GoMoveTypePass == moveType)
            {
              errorMessage = [NSString stringWithFormat:@"Game contains a pass move after the game has already ended (%@): Move %d, played by %@.",
                              [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName];
            }
            else
            {
              errorMessage = [NSString stringWithFormat:@"Game contains a move after the game has already ended (%@): Move %d, played by %@, on intersection %@.",
                              [self gameHasEndedReasonDescription:game.reasonForGameHasEnded], (movesReplayed + 1), colorName, point.vertex.string];
            }
            [self handleCommandFailed:errorMessage];
            return;
          }
          [game revertStateFromEndedToInProgress];
        }
        if (GoMoveTypePass == moveType)
        {
          [game pass];
        }
        else
        {
          enum GoMoveIsIllegalReason illegalReason;
          if (! [game isLegalMove:point byColor:moveColor isIllegalReason:&illegalReason])
          {
            NSString* errorMessageFormat = @"Game contains an illegal move: Move %d, played by %@, on intersection %@. Reason: %@.";
            NSString* illegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
            NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, (movesReplayed + 1), colorName, point.vertex.string, illegalReasonString];
            [self handleCommandFailed:errorMessage];
            return;
          }
          [game play:point];
        }
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
    NSString* errorMessageFormat = @"An unexpected error occurred loading the game. To improve this app, please consider submitting a bug report with the game file attached.\n\nException name: %@.\n\nException reason: %@.";
    NSString* errorMessage = [NSString stringWithFormat:errorMessageFormat, [exception name], [exception reason]];
    [self handleCommandFailed:errorMessage];
    return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Attempts to parse @a moveString. If the parse attempt succeeds,
/// returns #ParseMoveStringResultSuccess and fills the out parameters with the
/// result. If the parse attempt fails, returns one of the remaining values from
/// the #ParseMoveStringResult enumeration. The content of the out parameters is
/// undefined in this case.
///
/// If parsing is successful, the out parameters are filled as follows:
/// - @a moveColor is always filled
/// - If @a isResignMove is true, the content of the remaining parameters is
///   undefined
/// - If @a isResignMove is false, @a moveType is either #GoMoveTypePass or
///   #GoMoveTypePlay
/// - If @a moveType is #GoMoveTypePass, the content of @a point is undefined
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (enum ParseMoveStringResult) parseMoveString:(NSString*)moveString
                                     moveColor:(enum GoColor*)moveColor
                                  isResignMove:(bool*)isResignMove
                                      moveType:(enum GoMoveType*)moveType
                                         point:(GoPoint**)point
{
  NSArray* moveStringComponents = [moveString componentsSeparatedByString:@" "];
  if (moveStringComponents.count != 2)
    return ParseMoveStringResultInvalidFormat;

  bool success = [self parseColorString:[moveStringComponents objectAtIndex:0]
                                  color:moveColor];
  if (! success)
    return ParseMoveStringResultInvalidColor;

  NSString* vertexString = [[moveStringComponents objectAtIndex:1] lowercaseString];
  if ([vertexString isEqualToString:@"resign"])  // not sure if this is ever sent
  {
    *isResignMove = true;
    return ParseMoveStringResultSuccess;
  }
  else if ([vertexString isEqualToString:@"pass"])
  {
    *isResignMove = false;
    *moveType = GoMoveTypePass;
    return ParseMoveStringResultSuccess;
  }
  else
  {
    *isResignMove = false;
    *moveType = GoMoveTypePlay;
    @try
    {
      *point = [[GoGame sharedGame].board pointAtVertex:vertexString];
      return ParseMoveStringResultSuccess;
    }
    @catch (NSException* exception)
    {
      // If the vertex is not legal an exception is raised:
      // - NSInvalidArgumentException if vertex is malformed
      // - NSRangeException if vertex compounds are out of range
      // For our purposes, both exception types are the same.
      return ParseMoveStringResultInvalidVertex;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs all steps required to handle the case that a move string
/// provided by Fuego could not be parsed.
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (void) handleInvalidMoveString:(NSString*)moveString parseMoveStringResult:(enum ParseMoveStringResult)parseMoveStringResult
{
  NSString* errorMessage;
  switch (parseMoveStringResult)
  {
    case ParseMoveStringResultInvalidFormat:
    {
      errorMessage = @"Move string has invalid format";
      break;
    }
    case ParseMoveStringResultInvalidColor:
    {
      errorMessage = @"Move string contains unsupported player color";
      break;
    }
    case ParseMoveStringResultInvalidVertex:
    {
      errorMessage = @"Move string contains invalid intersection";
      break;
    }
    default:
    {
      errorMessage = @"Unknown error";
      assert(0);
      break;
    }
  }
  errorMessage = [NSString stringWithFormat:@"Internal error: %@. Move string = %@", errorMessage, moveString];
  [self handleCommandFailed:errorMessage];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for @a gameHasEndedReason that can be
/// incorporated into an error message.
///
/// This is a private helper for replayMoves:().
// -----------------------------------------------------------------------------
- (NSString*) gameHasEndedReasonDescription:(enum GoGameHasEndedReason)gameHasEndedReason
{
  switch (gameHasEndedReason)
  {
    case GoGameHasEndedReasonTwoPasses:
      return @"by two pass moves";
    case GoGameHasEndedReasonThreePasses:
      return @"by three pass moves";
    case GoGameHasEndedReasonFourPasses:
      return @"by four pass moves";
    case GoGameHasEndedReasonResigned:
      return @"by resignation";
    default:
      return @"by an unkown reason";
  }
}

// -----------------------------------------------------------------------------
/// @brief Attempts to parse @a colorString. If the parse attempt succeeds,
/// returns true and fills the out parameter with the result. If the parse
/// attempt fails, returns false. The content of the out parameters is
/// undefined in this case.
///
/// This is a private helper.
// -----------------------------------------------------------------------------
- (bool) parseColorString:(NSString*)colorString
                    color:(enum GoColor*)color
{
  colorString = [colorString lowercaseString];

  if ([colorString isEqualToString:@"b"])
  {
    *color = GoColorBlack;
    return true;
  }
  else if ([colorString isEqualToString:@"w"])
  {
    *color = GoColorWhite;
    return true;
  }
  else
  {
    return false;
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
///
/// This method, and with it ComputerPlayMoveCommand, must be executed on the
/// main thread. Reason:
/// - When ComputerPlayMoveCommand receives the GTP response with the computer
///   player's move, it triggers various UIKit updates
/// - These updates must happen on the main thread because UIKit drawing must
///   happen on the main thread
/// - ComputerPlayMoveCommand receives the GTP response in the same thread
///   context that it is executed in. So for the GTP response to be received
///   on the main thread, ComputerPlayMoveCommand itself must also be executed
///   on the main thread.
///
/// LoadGameCommand's long-running action cannot help us delay UIKit updates in
/// this scenario, because by the time that ComputerPlayMoveCommand receives its
/// GTP response, LoadGameCommand has long since terminated its long-running
/// action.
// -----------------------------------------------------------------------------
- (void) triggerComputerPlayerOnMainThread
{
  GoGame* game = [GoGame sharedGame];
  if (game.nextMovePlayerIsComputerPlayer)
  {
    if (self.restoreMode)
    {
      if (GoGameTypeComputerVsComputer == game.type)
      {
        // The game may already have ended, in which case there is no need to
        // pause (in fact, we must not pause, otherwise we trigger an exception)
        if (GoGameStateGameHasEnded != game.state)
          [game pause];
      }
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
  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Failed to load game"
                                                                           message:message
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {}];
  [alertController addAction:okAction];

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentViewController:alertController animated:YES completion:nil];
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

@end
