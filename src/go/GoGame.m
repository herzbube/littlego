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


#import "GoGame.h"
#import "GoBoard.h"
#import "GoPlayer.h"
#import "GoMove.h"
#import "GoPoint.h"
#import "../gtp/GtpClient.h"
#import "../play/PlayView.h"
#import "../ApplicationDelegate.h"

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

  return self;
}

- (void) move:(enum GoMoveType)type atPoint:(GoPoint*)point;
{
  GoMove* move = nil;
  move = [GoMove newMove:type after:self.lastMove];
  if (PlayMove == type && ! point)
  {
    NSString* vertex = [[[ApplicationDelegate sharedDelegate] gtpClient] generateMove:move.isBlack];
    point = [self.board pointWithVertex:vertex];
  }
  if (point)
  {
    move.point = point;
    point.move = move;
  }

  if (! self.firstMove)
    self.firstMove = move;
  self.lastMove = move;

  if (! self.hasStarted)
    self.started = true;
  // TODO: What about self.ended?

  [[PlayView sharedView] drawMove:move];
}

- (void) setGtpEngineResponse:(NSString*)response
{
  // TODO probably remove this
}

@end
