// -----------------------------------------------------------------------------
// Copyright 2014-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../ui/TiledScrollView.h"


// -----------------------------------------------------------------------------
/// @brief The BoardViewController class manages the scroll views that display
/// the Go board and the board's coordinate labels.
///
/// BoardViewController has the following responsibilities:
/// - Manage zooming and scrolling of the main scroll view that displays the Go
///   board
/// - Synchronize zooming and scrolling properties of scroll views that contain
///   coordinate label views with the corresponding properties of the main
///   scroll view
/// - Resize scroll views when a view layout change occurs outside of zooming
///   (typically when the device changes orientation). See the documentation of
///   viewDidLayoutSubviews() for details.
///
/// BoardViewController creates additional controllers for managing all gestures
/// except zooming and scrolling. Since these sub-controllers are not view
/// controllers, BoardViewController is also not a container view controller
/// (i.e. it does not use addChildViewController:() to manage these
/// sub-controllers).
// -----------------------------------------------------------------------------
@interface BoardViewController : UIViewController <TiledScrollViewDataSource, UIScrollViewDelegate>
{
}

@end
