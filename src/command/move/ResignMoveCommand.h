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
#import "../CommandBase.h"

// Forward declarations
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The ResignMoveCommand class is responsible for making a resign move
/// for the player whose turn it is.
///
/// ResignMoveCommand updates GoGame so that it generates a GoMove of type
/// #ResignMove for the player whose turn it is. In addition it submits a
/// "final_score" command to the GTP engine.
// -----------------------------------------------------------------------------
@interface ResignMoveCommand : CommandBase
{
}

- (id) init;

@property(retain) GoGame* game;

@end
