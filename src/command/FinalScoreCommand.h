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
#import "CommandBase.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The FinalScoreCommand class is responsible for submiting a
/// "final_score" command to the GTP engine.
///
/// Scoring involves the following:
/// 1. Captured stones
/// 2. Dead stones
/// 3. Territory
/// 4. Komi
/// Little Go is capable of counting 1 and 4, but not 2 and 3. So for the
/// moment we rely on Fuego's scoring.
// -----------------------------------------------------------------------------
@interface FinalScoreCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;

@end
