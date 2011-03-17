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
#import "../play/PlayView.h"
#import "../ApplicationDelegate.h"


@interface GoGame(Private)
- (void) generateMove;
- (void) gtpResponseReceived:(NSNotification*)notification;
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

- (void) play:(GoPoint*)point
{
  GoMove* move = [GoMove move:PlayMove after:self.lastMove];
  move.point = point;
  point.move = move;

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  if (! self.hasStarted)
    self.started = true;
  // TODO: What about self.ended?

  [[PlayView sharedView] drawMove:move];

  // todo invoke generateMove() if it is the computer player's turn
}

- (void) playForMe
{
  [self generateMove];
}

- (void) pass
{
  // not yet implementend
}

- (void) undo
{
  // not yet implementend
}

- (void) resign
{
  // not yet implementend
}

- (void) generateMove
{
  bool playForBlack = true;
  if (self.lastMove)
    playForBlack = ! self.lastMove.isBlack;

  NSString* commandString = @"genmove ";
  if (playForBlack)
    commandString = [commandString stringByAppendingString:@"B"];
  else
    commandString = [commandString stringByAppendingString:@"W"];

  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
}

- (void) gtpResponseReceived:(NSNotification*)notification
{
  GtpResponse* response = (GtpResponse*)[notification object];

  // todo check if it's the response for a genmove

  NSString* vertex = [response.response substringFromIndex:2];
  GoPoint* point = [self.board pointWithVertex:vertex];
  [self play:point];
}

@end
