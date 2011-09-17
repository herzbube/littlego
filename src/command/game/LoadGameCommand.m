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
#import "../NewGameCommand.h"
#import "../../ApplicationDelegate.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../newgame/NewGameModel.h"
#import "../../player/Player.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"


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
- (void) gtpResponseReceived:(NSNotification*)notification;
//@}
/// @name Helpers
//@{
- (void) startNewGame;
- (void) setupNewGame;
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
  m_boardDimension = 0;
  m_komi = 0;
  m_handicap = nil;
  m_moves = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CommandBase object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.fileName = nil;
  self.blackPlayer = nil;
  self.whitePlayer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (! self.fileName || ! self.blackPlayer || ! self.whitePlayer)
    return false;

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
    assert(0);
    return;
  }

  // Was GTP command successful?
  if (! response.status)
  {
    assert(0);
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
  m_boardDimension = [responseLines count];

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
    assert(0);
    return;
  }

  m_moves = [response.parsedResponse copy];

  [self startNewGame];
}

// -----------------------------------------------------------------------------
/// @brief Starts the new game.
// -----------------------------------------------------------------------------
- (void) startNewGame
{
  // Configure NewGameModel with information that is used when a new GoGame
  // instance is created
  NewGameModel* model = [ApplicationDelegate sharedDelegate].newGameModel;
  model.boardSize = [GoBoard sizeForDimension:m_boardDimension];
  model.blackPlayerUUID = self.blackPlayer.uuid;
  model.whitePlayerUUID = self.whitePlayer.uuid;

  // Add ourselves as observers before we submit the command
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseReceived:)
                                               name:gtpResponseReceivedNotification
                                             object:nil];
  // Make sure that this command object survives until it gets the
  // notification.
  [self retain];

  NewGameCommand* command = [[NewGameCommand alloc] init];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Handle the event that the response for "clear_board" GTP command was
/// received.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(NSNotification*)notification
{
  // Let's hope this really is for "clear_board" :-)
  GtpResponse* response = [notification object];
  NSLog(@"LoadGameCommand, gtpResponseReceived: invoked for GTP command @%", response.command.command);

  // We got what we wanted, we are no longer interested in notifications
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // Balance the retain message in startNewGame() to trigger deallocation
  [self autorelease];

  [self setupNewGame];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the new game with the information that was previously
/// gathered.
// -----------------------------------------------------------------------------
- (void) setupNewGame
{
  NSLog(@"---------------------------------------------------------");
  NSLog(@"board dimensions = %d", m_boardDimension);
  NSLog(@"komi = %.1f", m_komi);
  NSLog(@"handicap stones = %@", m_handicap);
  NSLog(@"moves = %@", m_moves);
  NSLog(@"---------------------------------------------------------");

  GoGame* game = [GoGame sharedGame];
  GoBoard* board = game.board;

  // TODO: Add Komi and handicap

  // Expected format = "color vertex, color vertex, color vertex[...]"
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
    // TODO: Handle handicap and color of first move !!!!
//    NSString* colorString = [moveComponents objectAtIndex:0];
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

@end
