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


// -----------------------------------------------------------------------------
/// @brief The PanGestureControllerDelegate protocol must be implemented by the
/// delegate of PanGestureController.
// -----------------------------------------------------------------------------
@protocol PanGestureControllerDelegate
/// @brief This method is invoked when the user attempts to place a stone. The
/// delegate executes @a command, possibly displaying an alert first which the
/// user must confirm.
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(CommandBase*)command;
@end


// -----------------------------------------------------------------------------
/// @brief The PanGestureController class is responsible for managing the pan
/// gesture on the "Play" tab. Panning is used to place a stone on the board.
///
/// Despite its name, PanGestureController does not use UIPanGestureRecognizer
/// for gesture recognition, because UIPanGestureRecognizer requires a
/// fingertip to travel a certain distance before the gesture is recognized as
/// a pan.
///
/// PanGestureController uses UILongPressGestureRecognizer so that a stone can
/// be displayed immediately when a fingertip touches the board (or after only
/// a very short delay).
// -----------------------------------------------------------------------------
@interface PanGestureController : NSObject <UIGestureRecognizerDelegate>
{
}

@property(nonatomic, assign) PlayView* playView;
@property(nonatomic, assign) UIView* scrollView;
@property(nonatomic, assign) id<PanGestureControllerDelegate> delegate;

@end
