// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
@class BoardPositionTableListViewController;
@class BoardPositionToolbarController;


// -----------------------------------------------------------------------------
/// @brief The LeftPaneViewController class manages a simple container view
/// intended to be displayed as the left pane of a split view (i.e. the view
/// managed by UISplitViewController).
///
/// LeftPaneViewController is a container view controller. It is used on the
/// iPad only.
// -----------------------------------------------------------------------------
@interface LeftPaneViewController : UIViewController
{
}

@property(nonatomic, retain) BoardPositionToolbarController* boardPositionToolbarController;
@property(nonatomic, retain) BoardPositionTableListViewController* boardPositionTableListViewController;

@end
