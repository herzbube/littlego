// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../ui/MagnifyingViewController.h"

// Forward declarations
@class BoardView;
@class CommandBase;

// -----------------------------------------------------------------------------
/// @brief The PanGestureController class is responsible for managing the pan
/// gesture on the Go board. Panning is used to place a stone on the board.
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
@interface PanGestureController : NSObject <UIGestureRecognizerDelegate, MagnifyingViewControllerDelegate>
{
}

@property(nonatomic, assign) BoardView* boardView;

@end
