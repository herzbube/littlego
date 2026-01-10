// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "StatusAreaViewController.h"
#import "StatusViewController.h"
#import "TimeViewController.h"
#import "../../go/GoGame.h"
#import "../../go/GoTimeSettings.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusAreaViewController.
// -----------------------------------------------------------------------------
@interface StatusAreaViewController()
@property(nonatomic, retain) UIStackView* stackView;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) TimeViewController* timeViewController;
@property(nonatomic, assign) bool timeViewControllerIntegrationNeedsUpdate;
@end


@implementation StatusAreaViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a StatusAreaViewController object.
///
/// @note This is the designated initializer of StatusAreaViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.stackView = nil;
  self.statusViewController = [[[StatusViewController alloc] init] autorelease];
  self.timeViewControllerIntegrationNeedsUpdate = true;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StatusAreaViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.stackView = nil;
  self.statusViewController = nil;
  self.timeViewController = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(goGameDidCreate:)
                           withObject:notification
                        waitUntilDone:YES];
    return;
  }

  self.timeViewControllerIntegrationNeedsUpdate = true;
  [self updateTimeViewControllerIntegrationIfNeeded];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setTimeViewController:(TimeViewController*)timeViewController
{
  if (_timeViewController == timeViewController)
    return;
  if (_timeViewController)
  {
    [_timeViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_timeViewController removeFromParentViewController];
    [_timeViewController release];
    _timeViewController = nil;
  }
  if (timeViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:timeViewController];
    [timeViewController didMoveToParentViewController:self];
    [timeViewController retain];
    _timeViewController = timeViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];
  [self updateTimeViewControllerIntegrationIfNeeded];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    [self updateColors];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.stackView = [[[UIStackView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.stackView];

  [self.stackView addArrangedSubview:self.statusViewController.statusView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.stackView.spacing = [AutoLayoutUtility horizontalSpacingSiblings];

  [self updateColors];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.stackView];
}

#pragma mark - Setup/remove TimeViewController

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) updateTimeViewControllerIntegrationIfNeeded
{
  if (! self.timeViewControllerIntegrationNeedsUpdate || ! self.isViewLoaded)
    return;
  self.timeViewControllerIntegrationNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoTimeSettings* timeSettings = game.timeSettings;

  bool timeViewControllerIsCurrentlyIntegrated = self.timeViewController;
  bool shouldIntegrateTimeViewController = timeSettings.isGameUsingTimedPlay;
  if (timeViewControllerIsCurrentlyIntegrated == shouldIntegrateTimeViewController)
    return;

  if (shouldIntegrateTimeViewController)
  {
    self.timeViewController = [[[TimeViewController alloc] init] autorelease];
    // Caues UIStackView to add the view as subview
    [self.stackView addArrangedSubview:self.timeViewController.view];
  }
  else
  {
    // Causes UIStackView to remove the view from its arranged subviews
    [self.timeViewController.view removeFromSuperview];
    self.timeViewController = nil;
  }
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  UITraitCollection* traitCollection = self.traitCollection;
  [UiUtilities applyTransparentStyleToView:self.statusViewController.statusView traitCollection:traitCollection];
}

@end
