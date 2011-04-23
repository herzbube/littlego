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



// -----------------------------------------------------------------------------
/// @brief The PlayerStatistics class collects statistical data about the
/// history of games played by a Player. PlayerStatistics is not much more than
/// a linear extension of the Player class.
// -----------------------------------------------------------------------------
@interface PlayerStatistics : NSObject
{
}

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;

/// @brief How many games have been played.
@property int gamesPlayed;
/// @brief How many games have been won.
@property int gamesWon;
/// @brief How many games have been lost.
@property int gamesLost;
/// @brief How many games have been tied.
@property int gamesTied;

@end
