// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
@interface GoGameRules : NSObject <NSSecureCoding>
{
}

/// @brief The ko rule in effect for the game.
@property(nonatomic, assign) enum GoKoRule koRule;
/// @brief The scoring system in effect for the game.
@property(nonatomic, assign) enum GoScoringSystem scoringSystem;
/// @brief How many pass moves are required to proceed to the life & death
/// settling phase of the game.
@property(nonatomic, assign) enum GoLifeAndDeathSettlingRule lifeAndDeathSettlingRule;
/// @brief Whether alternating play is enforced or not enforced when the game
/// is resumed to resolve disputes that arose during the life & death settling
/// phase.
@property(nonatomic, assign) enum GoDisputeResolutionRule disputeResolutionRule;
/// @brief What is the meaning of four consecutive pass moves.
@property(nonatomic, assign) enum GoFourPassesRule fourPassesRule;

@end
