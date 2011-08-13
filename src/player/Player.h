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
@class PlayerStatistics;


// -----------------------------------------------------------------------------
/// @brief The Player class collects data used to describe a Go player (e.g.
/// player name, whether the player is human or computer, etc.).
///
/// The difference between the Player and the GoPlayer class is that Player
/// refers to an @e identity, whereas GoPlayer attaches that identity to the
/// context of a Go game.
// -----------------------------------------------------------------------------
@interface Player : NSObject
{
}

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;

/// @brief The player's UUID. This is a technical identifier guaranteed to be
/// unique. This identifier is never displayed in the GUI.
@property(readonly, retain) NSString* uuid;
/// @brief The player's name. This is displayed in the GUI.
@property(retain) NSString* name;
/// @brief True if this Player object represents a human player, false if it
/// represents a computer player.
@property(getter=isHuman) bool human;
/// @brief Reference to an object that stores statistics about the history of
/// games played by this Player.
@property(retain) PlayerStatistics* statistics;

@end
