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
#import "../ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../newgame/NewGameModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GoPlayer.
// -----------------------------------------------------------------------------
@interface GoPlayer()
/// @name Initialization and deallocation
//@{
- (id) initWithPlayer:(Player*)aPlayer;
- (void) dealloc;
//@}
@end


@implementation GoPlayer

@synthesize player;
@synthesize black;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color black and refers to the "New Game" default black player.
// -----------------------------------------------------------------------------
+ (GoPlayer*) newGameBlackPlayer
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].newGameModel;
  PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
  Player* player = [playerModel playerWithUUID:newGameModel.blackPlayerUUID];
  return [GoPlayer blackPlayer:player];
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color white and refers to the "New Game" default white player.
// -----------------------------------------------------------------------------
+ (GoPlayer*) newGameWhitePlayer
{
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].newGameModel;
  PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
  Player* player = [playerModel playerWithUUID:newGameModel.whitePlayerUUID];
  return [GoPlayer whitePlayer:player];
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color black and refers to @a player.
// -----------------------------------------------------------------------------
+ (GoPlayer*) blackPlayer:(Player*)player
{
  GoPlayer* goPlayer = [[GoPlayer alloc] initWithPlayer:player];
  if (goPlayer)
  {
    goPlayer.black = true;
    [goPlayer autorelease];
  }
  return goPlayer;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color white and refers to @a player.
// -----------------------------------------------------------------------------
+ (GoPlayer*) whitePlayer:(Player*)player
{
  GoPlayer* goPlayer = [[GoPlayer alloc] initWithPlayer:player];
  if (goPlayer)
  {
    goPlayer.black = false;
    [goPlayer autorelease];
  }
  return goPlayer;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoPlayer object. The player takes color black and
/// refers to @a player.
///
/// @note This is the designated initializer of GoPlayer.
// -----------------------------------------------------------------------------
- (id) initWithPlayer:(Player*)aPlayer
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.player = aPlayer;
  self.black = true;

  // Mark the Player object as taking part in a game. This assumes that GoPlayer
  // objects are created only when a new GoGame is started.
  self.player.playing = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPlayer object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.player.playing = false;
  self.player = nil;
  [super dealloc];
}

@end
