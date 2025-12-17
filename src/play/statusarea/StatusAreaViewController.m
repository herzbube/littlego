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
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for StatusAreaViewController.
// -----------------------------------------------------------------------------
@interface StatusAreaViewController()
@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, retain) TimeViewController* timeViewController;
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

  [self setupChildControllers];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this StatusAreaViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.statusViewController = nil;
  self.timeViewController = nil;

  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.statusViewController = [[[StatusViewController alloc] init] autorelease];
  self.timeViewController = [[[TimeViewController alloc] init] autorelease];
}

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
  [self.view addSubview:self.statusViewController.statusView];
  [self.view addSubview:self.timeViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  [self updateColors];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.statusViewController.statusView.translatesAutoresizingMaskIntoConstraints = NO;
  self.timeViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"statusView"] = self.statusViewController.statusView;
  viewsDictionary[@"timeView"] = self.timeViewController.view;

  [visualFormats addObject:@"H:|-0-[statusView]-[timeView]-0-|"];
  [visualFormats addObject:@"V:|-[statusView]-|"];
  [visualFormats addObject:@"V:|-[timeView]-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.statusViewController.statusView.superview];
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
