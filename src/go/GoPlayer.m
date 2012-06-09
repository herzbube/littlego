// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/ApplicationDelegate.h"
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
/// @name NSCoding protocol
//@{
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
//@}
/// @name Other methods
//@{
- (NSString*) description;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) Player* player;
@property(nonatomic, assign, readwrite, getter=isBlack) bool black;
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
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
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
  NewGameModel* newGameModel = [ApplicationDelegate sharedDelegate].theNewGameModel;
  PlayerModel* playerModel = [ApplicationDelegate sharedDelegate].playerModel;
  Player* player = [playerModel playerWithUUID:newGameModel.whitePlayerUUID];
  return [GoPlayer whitePlayer:player];
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoPlayer instance which takes the
/// color black and refers to @a player.
///
/// Raises an @e NSInvalidArgumentException if @a player is nil.
// -----------------------------------------------------------------------------
+ (GoPlayer*) blackPlayer:(Player*)player
{
  if (! player)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Player argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

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
///
/// Raises an @e NSInvalidArgumentException if @a player is nil.
// -----------------------------------------------------------------------------
+ (GoPlayer*) whitePlayer:(Player*)player
{
  if (! player)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Player argument is nil"
                                                   userInfo:nil];
    @throw exception;
  }

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

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;
  self.player = [decoder decodeObjectForKey:goPlayerPlayerKey];
  self.black = [decoder decodeBoolForKey:goPlayerIsBlackKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoPlayer object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.player = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoPlayer object.
///
/// This method is invoked when GoPlayer needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoPlayer(%p): isBlack = %d", self, black];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSString*) colorString
{
  // TODO what about a GoColor class?
  if (self.black)
    return @"B";
  else
    return @"W";
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.player forKey:goPlayerPlayerKey];
  [encoder encodeBool:self.isBlack forKey:goPlayerIsBlackKey];
}

@end
