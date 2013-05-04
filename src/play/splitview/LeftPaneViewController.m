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
#import "../boardposition/BoardPositionController.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"


@implementation LeftPaneViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a LeftPaneViewController object.
///
/// @note This is the designated initializer of LeftPaneViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this LeftPaneViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseObjects];
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.boardPositionController = [[[BoardPositionController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.view = nil;
  self.boardPositionController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionController:(BoardPositionController*)boardPositionController
{
  if (_boardPositionController == boardPositionController)
    return;
  if (_boardPositionController)
  {
    [_boardPositionController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionController removeFromParentViewController];
    [_boardPositionController release];
    _boardPositionController = nil;
  }
  if (boardPositionController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionController];
    [boardPositionController didMoveToParentViewController:self];
    [boardPositionController retain];
    _boardPositionController = boardPositionController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  CGRect leftPaneViewFrame = CGRectZero;
  leftPaneViewFrame.size.width = [UiElementMetrics splitViewLeftPaneWidth];
  leftPaneViewFrame.size.height = [UiElementMetrics splitViewHeight];
  self.view = [[[UIView alloc] initWithFrame:leftPaneViewFrame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [UiUtilities addGroupTableViewBackgroundToView:self.view];

  self.boardPositionController.view.frame = self.view.bounds;
  [self.view addSubview:self.boardPositionController.view];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

@end
