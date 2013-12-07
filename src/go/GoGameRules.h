// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The GoGameRules class defines the rules that are in effect for a
/// game.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoGameRules : NSObject <NSCoding>
{
}

/// @brief The ko rule in effect for the game.
@property(nonatomic, assign) enum GoKoRule koRule;
/// @brief The scoring system in effect for the game.
@property(nonatomic, assign) enum GoScoringSystem scoringSystem;

@end
