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
#import "GoMove.h"
#import "GoPoint.h"


@implementation GoMove

@synthesize type;
@synthesize black;
@synthesize point;
@synthesize previous;
@synthesize next;

+ (GoMove*) move:(enum GoMoveType)type after:(GoMove*)move
{
  GoMove* newMove = [[GoMove alloc] init:type];
  if (newMove)
  {
    newMove.previous = move;
    move.next = newMove;  // set reference to self
    newMove.black = ! move.isBlack;
    [newMove autorelease];
  }
  return newMove;
}

- (GoMove*) init:(enum GoMoveType)initType
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.type = initType;
  self.black = true;
  self.point = nil;
  self.previous = nil;
  self.next = nil;

  return self;
}

- (void) dealloc
{
  if (self.point)
  {
    // Check if there is a reference to self; currently there is no guarantee
    // that this is the case - any number of moves may use the same point, but
    // the point references back to only one move: usually this should be the
    // last of the moves that use the point
    if (self == self.point.move)
      self.point.move = nil;  // remove reference to self
    self.point = nil;
  }
  self.previous = nil;  // not strictly necessary since we don't retain it
  if (self.next)
  {
    self.next.previous = nil;  // remove reference to self
    self.next = nil;
  }
  [super dealloc];
}

@end
