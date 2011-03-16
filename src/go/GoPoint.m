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


#import "GoPoint.h"

@implementation GoPoint

@synthesize numVertexX;
@synthesize numVertexY;
@synthesize vertexX;
@synthesize vertexY;
@synthesize move;

+ (GoPoint*) pointFromVertex:(NSString*)vertex
{
  assert(vertex != nil);
  if (! vertex)
    return nil;
  assert([vertex length] >= 2);
  if ([vertex length] < 2)
    return nil;
  GoPoint* point = [[GoPoint alloc] init];
  if (point)
  {
    point.vertexX = [vertex substringWithRange:NSMakeRange(0, 1)];
    point.vertexY = [vertex substringFromIndex:1];
    unichar charVertex = [point.vertexX characterAtIndex:0];
    unichar charA = [@"A" characterAtIndex:0];
    point.numVertexX = charVertex - charA + 1;  // +1 because vertex is not zero-based
    point.numVertexY = [point.vertexY intValue];
    [point autorelease];
  }
  return point;
}

- (GoPoint*) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.numVertexX = 1;
  self.numVertexY = 1;
  self.vertexX = @"A";
  self.vertexY = @"1";
  self.move = nil;

  return self;
}

- (void) dealloc
{
  self.vertexX = nil;
  self.vertexY = nil;
  self.move = nil;  // not strictly necessary since we don't retain it
  [super dealloc];
}

- (NSString*) vertex
{
  return [self.vertexX stringByAppendingString:self.vertexY];
}

@end
