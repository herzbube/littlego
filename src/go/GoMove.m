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

#import "GoMove.h"

@implementation GoMove

@synthesize type;
@synthesize black;
@synthesize point;
@synthesize previous;
@synthesize next;

+ (GoMove*) newMove:(enum GoMoveType)type after:(GoMove*)move
{
  GoMove* newMove = [[GoMove alloc] init:type];
  if (newMove)
    newMove.previous = move;  // also sets playMove's black property
  return newMove;
}

- (GoMove*) init:(enum GoMoveType)xtype
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.type = xtype;
  self.black = true;
  self.point = nil;
  self.previous = nil;
  self.next = nil;

  return self;
}

// also updates the next pointer of the old and new previous, and the black
// property of this move (alternate color of the new previous if it is not nil,
// black otherwise)
- (void) setPrevious:(GoMove*)newValue
{
  @synchronized(self)
  {
    if (previous == newValue)
      return;
    if (previous)
    {
      previous.next = nil;
      [previous release];
      previous = nil;
    }
    if (newValue)
    {
      newValue.next = self;
      [newValue retain];
      previous = newValue;
      self.black = ! newValue.black;
    }
    else
    {
      self.black = true;
    }

  }
}

@end
