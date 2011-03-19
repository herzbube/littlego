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
- (void) submitPlay:(NSString*)vertex;
- (void) submitGenMove;
- (void) submitResign;
- (void) updatePlay:(GoPoint*)point;
// Update state
- (void) updateGenMove;
- (void) updatePass;
- (void) updateResign;
// Others and helpers
- (void) gtpResponseReceived:(NSNotification*)notification;
- (NSString*) colorStringForMoveAfter:(GoMove*)move;
@end

@implementation GoGame

@synthesize board;
@synthesize playerBlack;
@synthesize playerWhite;
@synthesize started;
@synthesize ended;
@synthesize firstMove;
@synthesize lastMove;

+ (GoGame*) sharedGame;
{
  static GoGame* sharedGame = nil;
  @synchronized(self)
  {
    // TODO: We are the owner of sharedGame, but we never release the object
    if (! sharedGame)
      sharedGame = [[GoGame alloc] init];
    return sharedGame;
  }
}

- (GoGame*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.board = [GoBoard boardWithSize:19];
  self.playerBlack = [GoPlayer blackPlayer];
  self.playerWhite = [GoPlayer whitePlayer];
  self.started = false;
  self.ended = false;
  self.firstMove = nil;
  self.lastMove = nil;

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

- (void) setStarted:(bool)newValue
{
  @synchronized(self)
  {
    if (started == newValue)
      return;
    started = newValue;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameStateChanged object:self];
}

- (void) setEnded:(bool)newValue
{
  @synchronized(self)
  {
    if (ended == newValue)
      return;
    ended = newValue;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:goGameStateChanged object:self];
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

- (void) play:(GoPoint*)point
{
  [self submitPlay:[point vertex]];
  [self updatePlay:point];
  // todo invoke submitGenMove() and updateGenMove() if it is the computer player's turn
}

- (void) playForMe
{
  [self submitGenMove];
  [self updateGenMove];
}

- (void) pass
{
  [self submitPlay:@"pass"];
  [self updatePass];
  // todo invoke submitGenMove() and updateGenMove() if it is the computer player's turn
}

- (void) undo
{
  // not yet implementend
}

- (void) resign
{
  [self submitResign];
  [self updateResign];
}

- (void) submitPlay:(NSString*)vertex
{
  NSString* commandString = @"play ";
  commandString = [commandString stringByAppendingString:
                   [self colorStringForMoveAfter:self.lastMove]];
  commandString = [commandString stringByAppendingString:@" "];
  commandString = [commandString stringByAppendingString:vertex];
  GtpCommand* command = [GtpCommand command:commandString];
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

- (void) submitResign
{
  GtpCommand* command = [GtpCommand command:@"resign"];
  [command submit];
}

// updates both state in this model, and view; does not care about GTP
- (void) updatePlay:(GoPoint*)point
{
  GoMove* move = [GoMove move:PlayMove after:self.lastMove];
  move.point = point;
  point.move = move;

  if (! self.hasStarted)
    self.started = true;
  // TODO: What about self.ended?

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  // TODO: captured stones: GoPoints need to be updated; view needs to be updated
}

// updates both state in this model, and view; does not care about GTP
- (void) updateGenMove
{
  // todo: at the moment there is no need to update the model state - something
  // will happen when the response from the gtp engine comes in; check if this
  // is still ok before making the next release

  // todo: update view (status line = "pondering..." or something)
}

// updates both state in this model, and view; does not care about GTP
- (void) updatePass
{
  GoMove* move = [GoMove move:PassMove after:self.lastMove];

  if (! self.hasStarted)
    self.started = true;
  // TODO: What about self.ended?

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;
}

// updates both state in this model, and view; does not care about GTP
- (void) updateResign
{
  GoMove* move = [GoMove move:ResignMove after:self.lastMove];

  if (! self.hasStarted)
    self.started = true;
  // TODO: What about self.ended?

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;
}

- (void) gtpResponseReceived:(NSNotification*)notification
{
  GtpResponse* response = (GtpResponse*)[notification object];
  if (! response.status)
    return;
  NSString* commandString = response.command.command;
  if ([commandString hasPrefix:@"genmove"])
  {
    NSString* responseString = response.response;
    if (NSOrderedSame == [responseString compare:@"pass"])
      [self updatePass];
    else if (NSOrderedSame == [responseString compare:@"resign"])
      [self updateResign];
    else
    {
      GoPoint* point = [self.board pointWithVertex:responseString];
      if (point)
        [self updatePlay:point];
      else
        ;  // TODO vertex was invalid; do something...
    }
    // todo invoke submitGenMove() if it is the computer player's turn
    // todo invoke submitGenMove() and updateGenMove() if it is the computer player's turn
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

@end
