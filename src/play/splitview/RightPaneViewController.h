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
@class DiscardFutureMovesAlertController;
@class NavigationBarController;
@class ScrollViewController;


// -----------------------------------------------------------------------------
/// @brief The RightPaneViewController class manages a simple container view
/// intended to be displayed as the right pane of a split view (i.e. the view
/// managed by UISplitViewController).
///
/// RightPaneViewController's has the following responsibilities:
/// - Create its view with a frame that is appropriate at the time of creation
/// - Supply the view with an autoresizing mask that lets it resize in all
///   directions
/// - Enable rotation to all orientations
// -----------------------------------------------------------------------------
@interface RightPaneViewController : UIViewController
{
}

@property(nonatomic, retain) NavigationBarController* navigationBarController;
@property(nonatomic, retain) ScrollViewController* scrollViewController;
@property(nonatomic, retain) DiscardFutureMovesAlertController* discardFutureMovesAlertController;

@end
