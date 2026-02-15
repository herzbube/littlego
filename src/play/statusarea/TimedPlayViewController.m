// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "TimedPlayViewController.h"
#import "InvalidTimeDataViewController.h"
#import "TimeViewController.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../go/GoTimeDataValidator.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/PageViewController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimedPlayViewController.
// -----------------------------------------------------------------------------
@interface TimedPlayViewController()
@property(nonatomic, assign) bool clockViewMode;
@property(nonatomic, retain) UIStackView* stackView;
@property(nonatomic, retain) TimeViewController* timeViewController;
@property(nonatomic, retain) InvalidTimeDataViewController* invalidTimeDataViewController;
@property(nonatomic, assign) bool childViewControllerIntegrationNeedsUpdate;
@end


@implementation TimedPlayViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimedPlayViewController object that operates in
/// "clock view" mode.
// -----------------------------------------------------------------------------
- (id) initWithClockView
{
  return [self initWithMode:true];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TimedPlayViewController object that operates in
/// "node time data view" mode.
// -----------------------------------------------------------------------------
- (id) initWithNodeTimeDataView
{
  return [self initWithMode:false];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TimedPlayViewController object that operates either in
/// "clock view" mode (@a clockViewMode is true) or in "node time data view"
/// mode (@a clockViewMode is false).
///
/// @note This is the designated initializer of TimedPlayViewController.
// -----------------------------------------------------------------------------
- (id) initWithMode:(bool)clockViewMode
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.clockViewMode = clockViewMode;

  self.stackView = nil;
  self.childViewControllerIntegrationNeedsUpdate = true;
  
  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimedPlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  
  self.stackView = nil;
  self.timeViewController = nil;
  self.invalidTimeDataViewController = nil;

  [super dealloc];
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

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setInvalidTimeDataViewController:(InvalidTimeDataViewController*)invalidTimeDataViewController
{
  if (_invalidTimeDataViewController == invalidTimeDataViewController)
    return;
  if (_invalidTimeDataViewController)
  {
    [_invalidTimeDataViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_invalidTimeDataViewController removeFromParentViewController];
    [_invalidTimeDataViewController release];
    _invalidTimeDataViewController = nil;
  }
  if (invalidTimeDataViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:invalidTimeDataViewController];
    [invalidTimeDataViewController didMoveToParentViewController:self];
    [invalidTimeDataViewController retain];
    _invalidTimeDataViewController = invalidTimeDataViewController;
  }
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(timeDataDidBecomeValid:) name:timeDataDidBecomeValid object:nil];
  [center addObserver:self selector:@selector(timeDataDidBecomeInvalid:) name:timeDataDidBecomeInvalid object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupViewHierarchy];
  [self configureView];
  [self setupAutoLayoutConstraints];
  [self updateChildViewControllerIntegrationIfNeeded];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.stackView = [[[UIStackView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.stackView];
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view
                       withSubview:self.stackView];

  if (self.clockViewMode)
  {
    NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
    NSMutableArray* visualFormats = [NSMutableArray array];
    
    viewsDictionary[@"stackView"] = self.stackView;
    
    CGSize timeViewControllerClockViewSize = [TimeViewController timeViewControllerClockViewSize];
    
    [visualFormats addObject:[NSString stringWithFormat:@"H:[stackView(==%f)]", timeViewControllerClockViewSize.width]];
    [visualFormats addObject:[NSString stringWithFormat:@"V:[stackView(==%f)]", timeViewControllerClockViewSize.height]];
    [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
  }
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.childViewControllerIntegrationNeedsUpdate = true;
  [self updateChildViewControllerIntegrationIfNeeded];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #timeDataDidBecomeValid notification.
// -----------------------------------------------------------------------------
- (void) timeDataDidBecomeValid:(NSNotification*)notification
{
  self.childViewControllerIntegrationNeedsUpdate = true;
  [self updateChildViewControllerIntegrationIfNeeded];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #timeDataDidBecomeInvalid notification.
// -----------------------------------------------------------------------------
- (void) timeDataDidBecomeInvalid:(NSNotification*)notification
{
  self.childViewControllerIntegrationNeedsUpdate = true;
  [self updateChildViewControllerIntegrationIfNeeded];
}

#pragma mark - Integrate child view controllers in view hierarchy

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when a change occurs that
/// potentially requires adding or removing one of the child view controllers
/// to the view hierarchy.
// -----------------------------------------------------------------------------
- (void) updateChildViewControllerIntegrationIfNeeded
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(updateChildViewControllerIntegrationIfNeeded) withObject:nil waitUntilDone:YES];
    return;
  }

  if (! self.childViewControllerIntegrationNeedsUpdate || ! self.isViewLoaded)
    return;
  self.childViewControllerIntegrationNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoNode* currentNode = game.boardPosition.currentNode;

  bool shouldIntegrateTimeViewController = currentNode.isTimeDataValid;

  bool childViewControllerIntegrationHasTakenPlaceBefore = (self.timeViewController ||
                                                            self.invalidTimeDataViewController);
  if (childViewControllerIntegrationHasTakenPlaceBefore)
  {
    bool timeViewControllerIsCurrentlyIntegrated = self.timeViewController;
    if (timeViewControllerIsCurrentlyIntegrated == shouldIntegrateTimeViewController)
      return;
  }

  if (shouldIntegrateTimeViewController)
  {
    if (childViewControllerIntegrationHasTakenPlaceBefore)
    {
      // Causes UIStackView to remove the view from its arranged subviews
      [self.invalidTimeDataViewController.view removeFromSuperview];
      self.invalidTimeDataViewController = nil;
    }

    if (self.clockViewMode)
      self.timeViewController = [[[TimeViewController alloc] initWithClockView] autorelease];
    else
      self.timeViewController = [[[TimeViewController alloc] initWithNodeTimeDataView] autorelease];
    // Causes UIStackView to add the view as subview
    [self.stackView addArrangedSubview:self.timeViewController.view];
  }
  else
  {
    if (childViewControllerIntegrationHasTakenPlaceBefore)
    {
      // Causes UIStackView to remove the view from its arranged subviews
      [self.timeViewController.view removeFromSuperview];
      self.timeViewController = nil;
    }

    if (self.clockViewMode)
      self.invalidTimeDataViewController = [[[InvalidTimeDataViewController alloc] initWithClockView] autorelease];
    else
      self.invalidTimeDataViewController = [[[InvalidTimeDataViewController alloc] initWithNodeTimeDataView] autorelease];
    // Causes UIStackView to add the view as subview
    [self.stackView addArrangedSubview:self.invalidTimeDataViewController.view];
  }
}

@end
