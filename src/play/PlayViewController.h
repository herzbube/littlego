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


// Project includes
#import "ToolbarController.h"
#import "gesture/PanGestureController.h"
#import "boardposition/CurrentBoardPositionViewController.h"


// -----------------------------------------------------------------------------
/// @brief The PlayViewController class is the main controller on the "Play"
/// tab. It does not manage user interaction on its own, instead it delegates
/// this task to a variety of other sub-controllers.
///
/// PlayViewController has the following responsibilities:
/// - Set up the view hierarchy on the "Play" tab
/// - Create and configure sub-controllers
/// - Manage the timing of these tasks during application launch
/// - Rotate views on the "Play" tab when the device orientation changes
/// - Manage the animation to and from the "backside" view which displays
///   information about the current game. The transition is triggered by a
///   sub-controller, but managed by PlayViewController because only
///   PlayViewController knows the details of the view hierarchy
/// - Display alerts that are used by more than one sub-controller
///
///
/// @par Interface rotation
///
/// Most of the "Play" view is automatically resized when an interface
/// orientation occurs, due to autoresizeMask being properly set on most of the
/// view's UI elements. There are, however, the following exceptions:
/// - At any given time, either the "frontside" or the "backside" view are not
///   part of the view hierarchy because they are not visible at that time.
///   If the interface is rotated, the view that is currently not part of the
///   view hierarchy is not automatically resized. PlayViewController makes
///   sure that the resize happens nonetheless.
/// - The autoresizeMask of PlayView does not allow the view to grow or shrink.
///   PlayViewController makes sure that whenever the "frontside" view is
///   resized, PlayView is also resized. If the "frontside" view is visible at
///   that time, the resize is animated.
///
/// PlayViewController makes sure that all size updates described above are
/// performed even if the "Play" view is not visible at the time the interface
/// rotates. This requires special code because PlayViewController's regular
/// rotation code is not triggered by UIKit in this situation.
// -----------------------------------------------------------------------------
@interface PlayViewController : UIViewController <PanGestureControllerDelegate,
                                                  ToolbarControllerDelegate,
                                                  CurrentBoardPositionViewControllerDelegate,
                                                  UIAlertViewDelegate>
{
}

@end
