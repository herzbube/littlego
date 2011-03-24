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
#import "GoGame.h"
#import "GoBoard.h"
#import "GoPlayer.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "GoVertex.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"
#import "../ApplicationDelegate.h"


@interface GoGame(Private)
// Setters needed for posting notifications to notify our observers
- (void) setStarted:(bool)newValue;
- (void) setEnded:(bool)newValue;
- (void) setFirstMove:(GoMove*)newValue;
- (void) setLastMove:(GoMove*)newValue;
// Submit GTP commands
- (void) submitPlayMove:(NSString*)vertex;
- (void) submitPassMove;
- (void) submitResignMove;
- (void) submitGenMove;
// Update state
- (void) updatePlayMove:(GoPoint*)point;
- (void) updatePassMove;
- (void) updateResignMove;
- (void) updateGenMove;
// Others and helpers
- (void) gtpResponseReceived:(NSNotification*)notification;
- (NSString*) colorStringForMoveAfter:(GoMove*)move;
- (bool) isComputerPlayersTurn;
@end

@implementation GoGame

@synthesize board;
@synthesize playerBlack;
@synthesize playerWhite;
@synthesize firstMove;
@synthesize lastMove;
@synthesize state;
@synthesize boardSize;

+ (GoGame*) sharedGame;
{
  static GoGame* sharedGame = nil;
  @synchronized(self)
  {
    // TODO: We are the owner of sharedGame, but we never release the object
    if (! sharedGame)
    {
      sharedGame = [[GoGame alloc] init];
      sharedGame.boardSize = 19;
    }
    return sharedGame;
  }
}

- (GoGame*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.board = [GoBoard board];
  self.playerBlack = [GoPlayer blackPlayer];
  self.playerWhite = [GoPlayer whitePlayer];
  self.firstMove = nil;
  self.lastMove = nil;
  self.state = GameHasNotYetStarted;

  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(gtpResponseReceived:)
                                               name:gtpResponseReceivedNotification
                                             object:nil];

  return self;
}

- (void) dealloc
{
  self.board = nil;
  self.playerBlack = nil;
  self.playerWhite = nil;
  self.firstMove = nil;
  self.lastMove = nil;
  [super dealloc];
}

- (void) setFirstMove:(GoMove*)newValue
{
  @synchronized(self)
  {
    if (firstMove == newValue)
      return;
    [firstMove release];
    firstMove = [newValue retain];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameFirstMoveChanged object:self];
}

- (void) setLastMove:(GoMove*)newValue
{
  @synchronized(self)
  {
    if (lastMove == newValue)
      return;
    [lastMove release];
    lastMove = [newValue retain];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameLastMoveChanged object:self];
}

- (void) setState:(enum GoGameState)newValue
{
  @synchronized(self)
  {
    if (state == newValue)
      return;
    state = newValue;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameStateChanged object:self];
}

- (void) setBoardSize:(int)newValue
{
  @synchronized(self)
  {
    board.size = newValue;
  }
}

- (void) play:(GoPoint*)point
{
  [self submitPlayMove:point.vertex.string];
  [self updatePlayMove:point];
  if ([self isComputerPlayersTurn])
    [self computerPlay];
}

- (void) pass
{
  [self submitPassMove];
  [self updatePassMove];
  if ([self isComputerPlayersTurn])
    [self computerPlay];
}

- (void) resign
{
  [self submitResignMove];
  [self updateResignMove];
  // TODO calculate score
}

- (void) computerPlay
{
  [self submitGenMove];
  [self updateGenMove];
}

- (void) undo
{
  // TODO not yet implementend
}

- (bool) hasStarted
{
  return (GameHasStarted == self.state);
}

- (bool) hasEnded
{
  return (GameHasEnded == self.state);
}

- (void) submitPlayMove:(NSString*)vertex
{
  NSString* commandString = @"play ";
  commandString = [commandString stringByAppendingString:
                   [self colorStringForMoveAfter:self.lastMove]];
  commandString = [commandString stringByAppendingString:@" "];
  commandString = [commandString stringByAppendingString:vertex];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
}

- (void) submitPassMove
{
  [self submitPlayMove:@"pass"];
}

- (void) submitResignMove
{
  GtpCommand* command = [GtpCommand command:@"resign"];
  [command submit];
}

- (void) submitGenMove
{
  NSString* commandString = @"genmove ";
  commandString = [commandString stringByAppendingString:
                   [self colorStringForMoveAfter:self.lastMove]];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
}

// updates both state in this model, and view; does not care about GTP
- (void) updatePlayMove:(GoPoint*)point
{
  GoMove* move = [GoMove move:PlayMove after:self.lastMove];
  move.point = point;
  
  // Game state must change before any of the other things; this order is
  // important for observer notifications
  self.state = GameHasStarted;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;
}

// updates both state in this model, and view; does not care about GTP
- (void) updatePassMove
{
  GoMove* move = [GoMove move:PassMove after:self.lastMove];

  // Game state must change before any of the other things; this order is
  // important for observer notifications
  self.state = GameHasStarted;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;
}

// updates both state in this model, and view; does not care about GTP
- (void) updateResignMove
{
  GoMove* move = [GoMove move:ResignMove after:self.lastMove];

  // Game state must change before any of the other things; this order is
  // important for observer notifications
  self.state = GameHasEnded;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;
}

// updates both state in this model, and view; does not care about GTP
- (void) updateGenMove
{
  // todo: at the moment there is no need to update the model state - something
  // will happen when the response from the gtp engine comes in; check if this
  // is still ok before making the next release
  
  // todo: update view (status line = "pondering..." or something)
}

- (void) gtpResponseReceived:(NSNotification*)notification
{
  GtpResponse* response = (GtpResponse*)[notification object];
  if (! response.status)
    return;
  NSString* commandString = response.command.command;
  if ([commandString hasPrefix:@"genmove"])
  {
    NSString* responseString = response.parsedResponse;
    if (NSOrderedSame == [responseString compare:@"pass"])
      [self updatePassMove];
    else if (NSOrderedSame == [responseString compare:@"resign"])
      [self updateResignMove];
    else
    {
      GoPoint* point = [self.board pointAtVertex:responseString];
      if (point)
        [self updatePlayMove:point];
      else
        ;  // TODO vertex was invalid; do something...
    }
    if ([self isComputerPlayersTurn])
      [self computerPlay];
  }
}

- (NSString*) colorStringForMoveAfter:(GoMove*)move
{
  // TODO what about a GoColor class?
  bool playForBlack = true;
  if (self.lastMove)
    playForBlack = ! self.lastMove.isBlack;
  if (playForBlack)
    return @"B";
  else
    return @"W";
}

- (bool) isComputerPlayersTurn
{
  // TODO: Find a better way to determine when it is the computer player's
  // turn. This works only as long as white is fixed to be the computer
  if (! self.lastMove)
    return false;  // first turn always goes to black
  return self.lastMove.black;
}

@end
