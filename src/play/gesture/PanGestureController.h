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


// Forward declarations
@class CommandBase;
@class PanGestureController;
@class PlayView;
@class ScoringModel;


// -----------------------------------------------------------------------------
/// @brief The PanGestureControllerDelegate protocol must be implemented by the
/// delegate of PanGestureController.
// -----------------------------------------------------------------------------
@protocol PanGestureControllerDelegate
/// @brief This method is invoked when the user attempts a panning gesture while
/// she views a board position where it is the computer's turn to play.
///
/// The delegate may display an alert that this is not possible.
- (void) panGestureControllerAlertCannotPlayOnComputersTurn:(PanGestureController*)controller;
/// @brief This method is invoked when the user attempts to place a stone. The
/// delegate executes @a command, possibly displaying an alert first which the
/// user must confirm.
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(CommandBase*)command;
@end


// -----------------------------------------------------------------------------
/// @brief The PanGestureController class is responsible for managing the pan
/// gesture on the "Play" view. Panning is used to place a stone on the board.
// -----------------------------------------------------------------------------
@interface PanGestureController : NSObject <UIGestureRecognizerDelegate>
{
}

- (id) initWithPlayView:(PlayView*)playView scoringModel:(ScoringModel*)scoringModel delegate:(id<PanGestureControllerDelegate>)delegate;

@end
