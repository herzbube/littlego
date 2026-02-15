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
#import "TimedPlayViewController.h"
#import "../../go/GoGame.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../play/model/TimedPlayModel.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusAreaViewController.
// -----------------------------------------------------------------------------
@interface StatusAreaViewController()
@property(nonatomic, retain) UIStackView* stackView;
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) TimedPlayViewController* timedPlayViewController;
@property(nonatomic, assign) bool timedPlayViewControllerIntegrationNeedsUpdate;
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
  self.timedPlayViewControllerIntegrationNeedsUpdate = true;

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
  self.timedPlayViewController = nil;

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

  // KVO observing
  TimedPlayModel* timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
  [timedPlayModel addObserver:self forKeyPath:@"hidePlayerClockViewForInvalidTimeSystems" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  // KVO observing
  TimedPlayModel* timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
  [timedPlayModel removeObserver:self forKeyPath:@"hidePlayerClockViewForInvalidTimeSystems"];
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

  self.timedPlayViewControllerIntegrationNeedsUpdate = true;
  [self updateTimedPlayViewControllerIntegrationIfNeeded];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  self.timedPlayViewControllerIntegrationNeedsUpdate = true;
  [self updateTimedPlayViewControllerIntegrationIfNeeded];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setTimedPlayViewController:(TimedPlayViewController*)timedPlayViewController
{
  if (_timedPlayViewController == timedPlayViewController)
    return;
  if (_timedPlayViewController)
  {
    [_timedPlayViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_timedPlayViewController removeFromParentViewController];
    [_timedPlayViewController release];
    _timedPlayViewController = nil;
  }
  if (timedPlayViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:timedPlayViewController];
    [timedPlayViewController didMoveToParentViewController:self];
    [timedPlayViewController retain];
    _timedPlayViewController = timedPlayViewController;
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
  [self updateTimedPlayViewControllerIntegrationIfNeeded];
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

#pragma mark - Setup/remove TimedPlayViewController

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when a change occurs that
/// potentially requires adding or removing TimedPlayViewController.
// -----------------------------------------------------------------------------
- (void) updateTimedPlayViewControllerIntegrationIfNeeded
{
  if (! self.timedPlayViewControllerIntegrationNeedsUpdate || ! self.isViewLoaded)
    return;

  // This controller is created very early during app launch, before a game
  // has been created
  GoGame* game = [GoGame sharedGame];
  if (! game)
    return;

  self.timedPlayViewControllerIntegrationNeedsUpdate = false;

  TimedPlayModel* timedPlayModel = [Registry sharedRegistry].modelProvider.timedPlayModel;
  GoTimeSettings* timeSettings = game.timeSettings;

  bool timedPlayViewControllerIsCurrentlyIntegrated = self.timedPlayViewController;

  bool shouldIntegrateTimedPlayViewController;
  if (timeSettings.hasNoTimeSystems)
    shouldIntegrateTimedPlayViewController = false;
  else if (timedPlayModel.hidePlayerClockViewForInvalidTimeSystems && ! timeSettings.isTimeDataValid)
    shouldIntegrateTimedPlayViewController = false;
  else
    shouldIntegrateTimedPlayViewController = true;

  if (timedPlayViewControllerIsCurrentlyIntegrated == shouldIntegrateTimedPlayViewController)
    return;

  if (shouldIntegrateTimedPlayViewController)
  {
    self.timedPlayViewController = [[[TimedPlayViewController alloc] init] autorelease];
    // Caues UIStackView to add the view as subview
    [self.stackView addArrangedSubview:self.timedPlayViewController.view];
  }
  else
  {
    // Causes UIStackView to remove the view from its arranged subviews
    [self.timedPlayViewController.view removeFromSuperview];
    self.timedPlayViewController = nil;
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
