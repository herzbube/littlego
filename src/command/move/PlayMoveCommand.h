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
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The PlayMoveCommand class is responsible for making a playing move
/// or a pass move for a human player.
///
/// PlayMoveCommand submits a "play" command to the GTP engine, then updates
/// GoGame so that it generates a GoMove of type #GoMoveTypePlay or
/// #GoMoveTypePass for the human player whose turn it is.
///
/// The computer player is triggered if it is now its turn to move.
// -----------------------------------------------------------------------------
@interface PlayMoveCommand : CommandBase
{
}

- (id) initWithPoint:(GoPoint*)aPoint;
- (id) initPass;

@property(nonatomic, retain) GoGame* game;
@property(nonatomic, assign) enum GoMoveType moveType;
@property(nonatomic, retain) GoPoint* point;

@end
