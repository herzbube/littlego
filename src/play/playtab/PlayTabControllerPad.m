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


// Project includes
#import "PlayTabControllerPad.h"
#import "../controller/NavigationBarController.h"
#import "../splitview/LeftPaneViewController.h"
#import "../splitview/RightPaneViewController.h"
#import "../splitview/SplitViewController.h"
#import "../../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayTabControllerPad.
// -----------------------------------------------------------------------------
@interface PlayTabControllerPad()
// Cannot name this property splitViewController, there already is a property
// of that name in UIViewController, and it has a different meaning
@property(nonatomic, retain) SplitViewController* splitViewControllerChild;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
@end


@implementation PlayTabControllerPad

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayTabControllerPad object.
///
/// @note This is the designated initializer of PlayTabControllerPad.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (PlayTabController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayTabControllerPad object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self releaseObjects];
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.splitViewControllerChild = [[[SplitViewController alloc] init] autorelease];

  // These are not direct child controllers. We are setting them up on behalf
  // of UISplitViewController because we don't want to create a
  // UISplitViewController subclass.
  self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
  self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
  self.splitViewControllerChild.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];

  self.splitViewControllerChild.delegate = self.rightPaneViewController.navigationBarController;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.view = nil;
  self.splitViewControllerChild = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setSplitViewControllerChild:(SplitViewController*)splitViewControllerChild
{
  if (_splitViewControllerChild == splitViewControllerChild)
    return;
  if (_splitViewControllerChild)
  {
    [_splitViewControllerChild willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_splitViewControllerChild removeFromParentViewController];
    [_splitViewControllerChild release];
    _splitViewControllerChild = nil;
  }
  if (splitViewControllerChild)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:splitViewControllerChild];
    [_splitViewControllerChild didMoveToParentViewController:self];
    [splitViewControllerChild retain];
    _splitViewControllerChild = splitViewControllerChild;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self.view addSubview:self.splitViewControllerChild.view];

  // Enabling Auto Layout and installation of constraints is delayed until
  // viewDidLayoutSubviews because the constraints use topLayoutGuide and
  // bottomLayoutGuide.

  // Don't change self.splitViewControllerChild.view.backgroundColor because
  // that color is used for the separator line between the left and right view.
  // The left and right view must set their own background color.
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
///
/// We override this method so that we can install Auto Layout constraints that
/// make use of the topLayoutGuide and bottomLayoutGuide properties of this
/// UIViewController. We cannot install the constraints in loadView because this
/// results in weird layout issues (when the app launches in landscape
/// orientation on the iPad, the split view controller starts out with bounds
/// that match portrait orientation).
///
/// Note that Apple's documentation for both the topLayoutGuide and the
/// bottomLayoutGuide properties says: "Query this property within your
/// implementation of the viewDidLayoutSubviews method." So this override
/// actually does the right thing.
// -----------------------------------------------------------------------------
- (void) viewDidLayoutSubviews
{
  static bool constraintsNotYetInstalled = true;
  if (constraintsNotYetInstalled)
  {
    constraintsNotYetInstalled = false;
    self.splitViewControllerChild.view.translatesAutoresizingMaskIntoConstraints = NO;
    // Unfortunately we can't say
    //   self.edgesForExtendedLayout = UIRectEdgeNone;
    // because then the split view controller's view extends beneath the status
    // bar at the top. So instead we ***MUST*** use the VC's layout guides,
    // which in turn forces us to override viewDidLayoutSubviews.
    [AutoLayoutUtility fillAreaBetweenGuidesOfViewController:self withSubview:self.splitViewControllerChild.view];
    // We must call this to avoid a crash; this is as per documentation of the
    // topLayoutGuide and bottomLayoutGuide properties.
    [self.view layoutSubviews];
  }
}

@end
