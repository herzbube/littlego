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


// Project includes
#import "LeftPaneViewController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for LeftPaneViewController.
// -----------------------------------------------------------------------------
@interface LeftPaneViewController()
/// @name UIViewController methods
//@{
- (void) loadView;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
@end


@implementation LeftPaneViewController

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect leftPaneViewFrame = CGRectMake(0, 0, [UiElementMetrics splitViewLeftPaneWidth], [UiElementMetrics splitViewHeight]);
  self.view = [[[UIView alloc] initWithFrame:leftPaneViewFrame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [UiUtilities addGroupTableViewBackgroundToView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
