// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class NodeTreeViewModel;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewController class manages the scroll views that
/// display the tree of nodes and the strip with node numbers.
///
/// NodeTreeViewController has the following responsibilities:
/// - Manage zooming and scrolling of the main scroll view that displays the
///   tree of nodes
/// - Synchronize zooming and scrolling properties of the scroll view that
///   contains the node number view with the corresponding properties of the
///   main scroll view
/// - Resize scroll views when a view layout change occurs outside of zooming
///   (typically when the device changes orientation). See the documentation of
///   viewDidLayoutSubviews() for details.
///
/// NodeTreeViewController creates additional controllers for managing all
/// gestures except zooming and scrolling. Since these sub-controllers are not
/// view controllers, NodeTreeViewController is also not a container view
/// controller (i.e. it does not use addChildViewController:() to manage these
/// sub-controllers).
// -----------------------------------------------------------------------------
@interface NodeTreeViewController : UIViewController <TiledScrollViewDataSource, UIScrollViewDelegate>
{
}

- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel;

@end
