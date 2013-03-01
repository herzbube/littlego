// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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



// -----------------------------------------------------------------------------
/// @brief The NewGameModel class provides user defaults data to its clients
/// that describes the characteristics of a new game.
// -----------------------------------------------------------------------------
@interface NewGameModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (NSString*) blackPlayerUUID;
- (NSString*) whitePlayerUUID;

/// @brief Type of game that was created most recently.
///
/// This value is used to create a new game when the application launches. It
/// is very important that the UUIDs of the players associated with this
/// game type are valid at this time, otherwise the application crashes.
@property(nonatomic, assign) enum GoGameType gameType;
/// @brief Type of game that was selected when the "New game" view was
/// displayed the last time.
@property(nonatomic, assign) enum GoGameType gameTypeLastSelected;
/// @brief In a computer vs. human game.
@property(nonatomic, retain) NSString* humanPlayerUUID;
/// @brief In a computer vs. human game.
@property(nonatomic, retain) NSString* computerPlayerUUID;
/// @brief In a computer vs. human game.
@property(nonatomic, assign) bool computerPlaysWhite;
/// @brief In a human vs. human game.
@property(nonatomic, retain) NSString* humanBlackPlayerUUID;
/// @brief In a human vs. human game.
@property(nonatomic, retain) NSString* humanWhitePlayerUUID;
/// @brief In a computer vs. computer game.
@property(nonatomic, retain) NSString* computerPlayerSelfPlayUUID;
@property(nonatomic, assign) enum GoBoardSize boardSize;
@property(nonatomic, assign) int handicap;
@property(nonatomic, assign) double komi;

@end
