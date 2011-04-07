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
#import "GoPlayer.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoPlayer.
// -----------------------------------------------------------------------------
@interface GoPlayer()
/// @name Initialization and deallocation
//@{
- (id) init;
- (void) dealloc;
//@}
@end


@implementation GoPlayer

@synthesize black;
@synthesize human;
@synthesize name;

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color black.
// -----------------------------------------------------------------------------
+ (GoPlayer*) blackPlayer
{
  GoPlayer* player = [[GoPlayer alloc] init];
  if (player)
  {
    player.black = true;
    [player autorelease];
  }
  return player;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color white.
// -----------------------------------------------------------------------------
+ (GoPlayer*) whitePlayer
{
  GoPlayer* player = [[GoPlayer alloc] init];
  if (player)
  {
    player.black = false;
    [player autorelease];
  }
  return player;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoPlayer object.
///
/// @note This is the designated initializer of GoPlayer.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.black = true;
  self.human = false;
  self.name = @"Fuego";

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPlayer object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.name = nil;
  [super dealloc];
}

@end
