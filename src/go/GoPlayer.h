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


// Forward declarations
@class Player;


// -----------------------------------------------------------------------------
/// @brief The GoPlayer class represents one of the two players of a Go game.
///
/// GoPlayer combines a Player object (which refers to a player's @e identity)
/// with attributes that are valid in the context of a Go game.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoPlayer : NSObject
{
}

+ (GoPlayer*) newGameBlackPlayer;
+ (GoPlayer*) newGameWhitePlayer;
+ (GoPlayer*) blackPlayer:(Player*)player;
+ (GoPlayer*) whitePlayer:(Player*)player;

/// @brief Reference to player object that stores information about that
/// player's identity.
@property(nonatomic, retain) Player* player;
/// @brief The color taken by the player.
@property(nonatomic, assign, getter=isBlack) bool black;
/// @brief Returns a string that corresponds to the color taken by the
/// player. "B" for black, "W" for white.
@property(nonatomic, assign, readonly) NSString* colorString;

@end
