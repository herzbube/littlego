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
#import "TimeViewController.h"
#import "TimeView.h"
#import "../../go/GoGame.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimeViewController.
// -----------------------------------------------------------------------------
@interface TimeViewController()
@property(nonatomic, retain) TimeView* timeViewBlackPlayer;
@property(nonatomic, retain) TimeView* timeViewWhitePlayer;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizerTimeViewBlackPlayer;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizerTimeViewWhitePlayer;
@property(nonatomic, assign) bool timeDataNeedsUpdate;
@end


@implementation TimeViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an TimeViewController object.
///
/// @note This is the designated initializer of TimeViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.timeViewBlackPlayer = nil;
  self.timeViewWhitePlayer = nil;
  self.tapRecognizerTimeViewBlackPlayer = nil;
  self.tapRecognizerTimeViewWhitePlayer = nil;

  self.timeDataNeedsUpdate = false;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimeViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  
  self.timeViewBlackPlayer = nil;
  self.timeViewWhitePlayer = nil;
  self.tapRecognizerTimeViewBlackPlayer = nil;
  self.tapRecognizerTimeViewWhitePlayer = nil;

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
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
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
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.timeViewBlackPlayer = [[[TimeView alloc] initWithFrame:CGRectZero isTimeForBlackPlayer:true] autorelease];
  self.timeViewWhitePlayer = [[[TimeView alloc] initWithFrame:CGRectZero isTimeForBlackPlayer:false] autorelease];

  [self.view addSubview:self.timeViewBlackPlayer];
  [self.view addSubview:self.timeViewWhitePlayer];
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
  self.timeViewBlackPlayer.userInteractionEnabled = YES;
  self.tapRecognizerTimeViewBlackPlayer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)] autorelease];
  [self.timeViewBlackPlayer addGestureRecognizer:self.tapRecognizerTimeViewBlackPlayer];

  self.timeViewWhitePlayer.userInteractionEnabled = YES;
  self.tapRecognizerTimeViewWhitePlayer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)] autorelease];
  [self.timeViewWhitePlayer addGestureRecognizer:self.tapRecognizerTimeViewWhitePlayer];

  [self updateColors];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.timeViewBlackPlayer.translatesAutoresizingMaskIntoConstraints = NO;
  self.timeViewWhitePlayer.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"timeViewBlackPlayer"] = self.timeViewBlackPlayer;
  viewsDictionary[@"timeViewWhitePlayer"] = self.timeViewWhitePlayer;

  [visualFormats addObject:@"H:|-[timeViewBlackPlayer]-[timeViewWhitePlayer]-|"];
  [visualFormats addObject:@"V:|-[timeViewBlackPlayer]-|"];
  [visualFormats addObject:@"V:|-[timeViewWhitePlayer]-|"];

  CGSize timeViewSize = [TimeView timeViewSize];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[timeViewBlackPlayer(==%f)]", timeViewSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[timeViewWhitePlayer(==%f)]", timeViewSize.width]];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.view];
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  UITraitCollection* traitCollection = self.traitCollection;
  [UiUtilities applyTransparentStyleToView:self.timeViewBlackPlayer traitCollection:traitCollection];
  [UiUtilities applyTransparentStyleToView:self.timeViewWhitePlayer traitCollection:traitCollection];
}

#pragma mark - Gesture handling

// -----------------------------------------------------------------------------
/// @brief Reacts to the time view being tapped.
// -----------------------------------------------------------------------------
- (void) viewTapped:(id)sender
{
  TimeView* timeView = (sender == self.tapRecognizerTimeViewBlackPlayer
                        ? self.timeViewBlackPlayer
                        : self.timeViewWhitePlayer);

  // TODO xxx implement real handling
  switch (timeView.clockState)
  {
    case GoClockStateStopped:
      timeView.clockState = GoClockStateStarted;
      timeView.isRemainingTimeAbsoluteTime = ! timeView.isRemainingTimeAbsoluteTime;
      break;
    case GoClockStateStarted:
      timeView.clockState = GoClockStateSuspended;
      timeView.isRemainingTimeAbsoluteTime = ! timeView.isRemainingTimeAbsoluteTime;
      break;
    case GoClockStateSuspended:
      timeView.clockState = GoClockStateStopped;
      timeView.isRemainingTimeAbsoluteTime = ! timeView.isRemainingTimeAbsoluteTime;
      break;
    default:
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Invalid clock state %d"
                                                  argumentValue:timeView.clockState];
      break;
  }
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  self.timeDataNeedsUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(delayedUpdate) withObject:nil waitUntilDone:YES];
    return;
  }

  [self updateTimeData];
}

// -----------------------------------------------------------------------------
/// @brief Updates TimeView objects to display each player's current time data.
// -----------------------------------------------------------------------------
- (void) updateTimeData
{
  if (! self.timeDataNeedsUpdate)
    return;
  self.timeDataNeedsUpdate = false;

  GoGame* game = [GoGame sharedGame];
  GoTimeSettings* timeSettings = game.timeSettings;

  NSArray* timeSystems = @[timeSettings.absoluteTimeSystem, timeSettings.periodBasedTimeSystem];
  for (GoTimeSystem* timeSystem in timeSystems)
  {
    if (timeSystem.goTimeSystemType != GoTimeSystemTypeNone &&
        timeSystem.goTimeSystemType != GoTimeSystemTypeCustom)
    {
      [self updateTimeData:self.timeViewBlackPlayer timeSystem:timeSystem];
      [self updateTimeData:self.timeViewWhitePlayer timeSystem:timeSystem];
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates TimeView objects to display each player's current time data.
// -----------------------------------------------------------------------------
- (void) updateTimeData:(TimeView*)timeView timeSystem:(GoTimeSystem*)timeSystem
{
  timeView.clockState = GoClockStateStopped;

  if (timeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute)
  {
    timeView.isRemainingTimeAbsoluteTime = true;
    timeView.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
    timeView.remainingNumberOfMovesOrPeriods = 0;
  }
  else
  {
    timeView.isRemainingTimeAbsoluteTime = false;
    if (timeSystem.goTimeSystemType == GoTimeSystemTypeJapanese)
    {
      timeView.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
      timeView.remainingNumberOfMovesOrPeriods = timeSystem.numberOfPeriods;
    }
    else if (timeSystem.goTimeSystemType == GoTimeSystemTypeFischer)
    {
      timeView.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
      // TODO xxx TimeView should not show anything
      timeView.remainingNumberOfMovesOrPeriods = 0;
    }
    else
    {
      timeView.remainingTimeInSeconds = timeSystem.periodDurationInSeconds;
      timeView.remainingNumberOfMovesOrPeriods = timeSystem.minimumNumberOfMovesPerPeriod;
    }
  }
}

@end
