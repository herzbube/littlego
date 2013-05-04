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


// Forward declarations
@class PlayView;
@class PanGestureController;


// -----------------------------------------------------------------------------
/// @brief The PlayViewController class is the main controller on the "Play"
/// tab. It does not manage user interaction on its own, instead it delegates
/// this task to a variety of other sub-controllers.
///
/// PlayViewController has the following responsibilities:
/// - Set up the view hierarchy on the "Play" tab
/// - Create and configure sub-controllers
/// - Manage the timing of these tasks during application launch
/// - Manage the transition to and from the Game Info view. The transition is
///   triggered by a sub-controller, but managed by PlayViewController because
///   only PlayViewController knows the details of the view hierarchy
/// - Display alerts that are used by more than one sub-controller
///
///
/// @par Interface rotation
///
/// PlayViewController sets up all views on the "Play" tab with an appropriate
/// autoresizing mask so that when the interface rotates UIKit automatically
/// resizes and shifts the views.
// -----------------------------------------------------------------------------
@interface PlayViewController : UIViewController
{
}

@property(nonatomic, retain) PlayView* playView;
@property(nonatomic, retain) PanGestureController* panGestureController;

@end
