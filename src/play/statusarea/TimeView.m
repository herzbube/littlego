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
#import "TimeView.h"
#import "../timedplay/CompositeDuration.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/ExceptionUtility.h"


// This variable must be accessed via [TimeView timeViewSize]
static CGSize timeViewSize = { 0.0f, 0.0f };

// We reserve 6 characters to display the clock. Depending on the number of
// seconds to display we switch to a different resolution.
static int thresholdInSecondsForSecondsResolution = 59999;   // 999:59
static int thresholdInSecondsForMinutesResolution = 359999;  // 99h59m +59 seconds
static int thresholdInSecondsForHoursResolution = 35999999;  //  9999h +3599 seconds
// We reserve 8 characters to display the number of moves or periods: "(>99999)"
static int maximumNumberOfMovesOrPeriods = 99999;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TimeView.
// -----------------------------------------------------------------------------
@interface TimeView()
/// @name Private properties
//@{
@property(nonatomic, assign) bool viewContentNeedsUpdate;
@property(nonatomic, retain) NSString* remainingTimeString;
@property(nonatomic, retain) NSString* remainingNumberOfMovesOrPeriodsString;
@property(nonatomic, assign) UILabel* remainingTimeMovesPeriodsLabel;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) bool isTimeForBlackPlayer;
//@}
@end


@implementation TimeView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a TimeView object that displays the time for either the
/// black player (@a isTimeForBlackPlayer is true) or the white player
/// (@a isTimeForBlackPlayer is false).
///
/// @note This is the designated initializer of TimeView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect isTimeForBlackPlayer:(bool)isTimeForBlackPlayer
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.viewContentNeedsUpdate = true;
  self.remainingTimeString = [self stringForRemainingTimeInSeconds:0.0];
  self.remainingNumberOfMovesOrPeriodsString = [self stringForRemainingNumberOfMovesOrPeriods:0];

  self.isTimeForBlackPlayer = isTimeForBlackPlayer;
  self.isTimeDataValid = false;
  self.isRemainingTimeAbsoluteTime = false;
  self.remainingTimeInSeconds = 0.0;
  self.remainingNumberOfMovesOrPeriods = 0;
  self.clockState = GoClockStateStopped;

  [self setupViewHierarchy];
  [self configureView];
  [self setupAutoLayoutConstraints];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TimeView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.remainingTimeString = nil;
  self.remainingTimeMovesPeriodsLabel = nil;

  [super dealloc];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [self updateViewContentIfNeeded];
  [super layoutSubviews];
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
  {
    self.viewContentNeedsUpdate = true;
    [self updateViewContentIfNeeded];
  }
}

#pragma mark - One-time view setup

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.remainingTimeMovesPeriodsLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  [self addSubview:self.remainingTimeMovesPeriodsLabel];
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
  enum UIType uiType = [LayoutManager sharedManager].uiType;
  CGFloat fontSize = [UiElementMetrics statusAreaLabelFontSizeForUiType:uiType];

  self.remainingTimeMovesPeriodsLabel.numberOfLines = 2;
  self.remainingTimeMovesPeriodsLabel.font = [UIFont systemFontOfSize:fontSize];
  self.remainingTimeMovesPeriodsLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.remainingTimeMovesPeriodsLabel.textAlignment = NSTextAlignmentCenter;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.remainingTimeMovesPeriodsLabel.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"remainingTimeMovesPeriodsLabel"] = self.remainingTimeMovesPeriodsLabel;

  [visualFormats addObject:@"H:|-[remainingTimeMovesPeriodsLabel]-|"];
  [visualFormats addObject:@"V:|-[remainingTimeMovesPeriodsLabel]-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
}

#pragma mark - Content update

// -----------------------------------------------------------------------------
/// @brief Updates the view's content based on property values if such an update
/// is needed. Does nothing if the content did not change since the last update.
// -----------------------------------------------------------------------------
- (void) updateViewContentIfNeeded
{
  if (! self.viewContentNeedsUpdate)
    return;
  self.viewContentNeedsUpdate = false;

  UITraitCollection* traitCollection = self.traitCollection;
  bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:traitCollection];

  // In dark mode a filled circle is rendered with fill color white
  // => in dark mode we have to reverse the symbols to keep the appearance of
  //    black/white stones
  NSString* colorString;
  if (self.isTimeForBlackPlayer)
    colorString = (isLightUserInterfaceStyle ? @"●" : @"○");
  else
    colorString = (isLightUserInterfaceStyle ? @"○" : @"●");

  if (self.isTimeDataValid)
  {
    NSString* colorAndRemainingTimeString = [NSString stringWithFormat:@"%@ %@", colorString, self.remainingTimeString];

    NSString* mainTimeOrRemainingNumberOfMovesOrPeriodsString;
    if (self.isRemainingTimeAbsoluteTime)
      mainTimeOrRemainingNumberOfMovesOrPeriodsString = @"Main time";
    else
      mainTimeOrRemainingNumberOfMovesOrPeriodsString = self.remainingNumberOfMovesOrPeriodsString;

    self.remainingTimeMovesPeriodsLabel.text = [NSString stringWithFormat:@"%@\n%@", colorAndRemainingTimeString, mainTimeOrRemainingNumberOfMovesOrPeriodsString];
  }
  else
  {
    self.remainingTimeMovesPeriodsLabel.text = [NSString stringWithFormat:@"%@ Invalid time data", colorString];
  }

  UIColor* textColor;
  UIColor* borderColor;
  CGFloat borderWidth;

  switch (self.clockState)
  {
    case GoClockStateStopped:
    {
      textColor = [UIColor labelColor];
      borderColor = [UIColor blackColor];
      borderWidth = 1.0;
      break;
    }
    case GoClockStateStarted:
    case GoClockStateSuspended:
    {
      textColor = (isLightUserInterfaceStyle ? [UIColor blueColor] : [UIColor mayaBlueColor]);
      borderColor = (self.clockState == GoClockStateStarted
                     ? [UIColor systemGreenColor]
                     : [UIColor systemCyanColor]);
      borderWidth = 3.0;
      break;
    }
    default:
    {
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Invalid clock state %d"
                                                  argumentValue:self.clockState];
      // Dummy return to make compiler happy (compiler does not see that an
      // exception is thrown)
      return;
    }
  }

  self.remainingTimeMovesPeriodsLabel.textColor = textColor;
  self.layer.borderColor = borderColor.CGColor;
  self.layer.borderWidth = borderWidth;
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setIsTimeDataValid:(bool)newValue
{
  if (_isTimeDataValid == newValue)
    return;
  _isTimeDataValid = newValue;

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setIsRemainingTimeAbsoluteTime:(bool)newValue
{
  if (_isRemainingTimeAbsoluteTime == newValue)
    return;
  _isRemainingTimeAbsoluteTime = newValue;

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setRemainingTimeInSeconds:(double)newValue
{
  if (_remainingTimeInSeconds == newValue)
    return;
  _remainingTimeInSeconds = newValue;

  // See property documentation for details why we round up.
  double remainingTimeInSecondsRoundedUp = MAX(ceil(newValue), 0.0);
  self.remainingTimeString = [self stringForRemainingTimeInSeconds:remainingTimeInSecondsRoundedUp];

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setRemainingNumberOfMovesOrPeriods:(unsigned long)newValue
{
  if (_remainingNumberOfMovesOrPeriods == newValue)
    return;
  _remainingNumberOfMovesOrPeriods = newValue;

  self.remainingNumberOfMovesOrPeriodsString = [self stringForRemainingNumberOfMovesOrPeriods:_remainingNumberOfMovesOrPeriods];

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setClockState:(enum GoClockState)newValue
{
  if (_clockState == newValue)
    return;
  _clockState = newValue;

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

#pragma mark - One-time view size calculation

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
+ (CGSize) timeViewSize
{
  if (CGSizeEqualToSize(timeViewSize, CGSizeZero))
    [TimeView setupStaticViewMetrics];
  return timeViewSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for timeViewSize().
// -----------------------------------------------------------------------------
+ (void) setupStaticViewMetrics
{
  TimeView* offscreenView = [[[TimeView alloc] initWithFrame:CGRectZero isTimeForBlackPlayer:false] autorelease];

  offscreenView.isTimeDataValid = true;
  // "W" is wider than "B"
  offscreenView.isTimeForBlackPlayer = false;
  // Widest time we support: 6 characters in total
  offscreenView.remainingTimeInSeconds = 320280; // clock shows "88h58m"
  // Widest number for either remaining moves or remaining periods we support:
  // 8 characters in total ("(>99999)"). This is about the same width as the
  // widest value we expect to display on line 1 ("● 88h58m"). It's
  // irrelevant anyway because the string "Main time" (which we show on line 2
  // if isRemainingTimeAbsoluteTime is true) is wider.
  offscreenView.remainingNumberOfMovesOrPeriods = 100000;
  // Shows "Main time" instead of a number
  offscreenView.isRemainingTimeAbsoluteTime = true;
  // Wider border than when clock is stopped (but border is probably outside of
  // the view's frame)
  offscreenView.clockState = GoClockStateStarted;

  [offscreenView layoutIfNeeded];
  CGSize timeViewSizeWithFractions = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

  timeViewSize = CGSizeMake(ceil(timeViewSizeWithFractions.width),
                            ceil(timeViewSizeWithFractions.height));
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a remainingTimeInSeconds
/// using the appropriate resolution format.
// -----------------------------------------------------------------------------
- (NSString*) stringForRemainingTimeInSeconds:(double)remainingTimeInSeconds
{
  CompositeDuration* compositeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:remainingTimeInSeconds] autorelease];

  if (remainingTimeInSeconds <= thresholdInSecondsForSecondsResolution)
  {
    return [NSString stringWithFormat:@"%d:%02d",
            compositeDuration.numberOfMinutes + compositeDuration.numberOfHours * 60,
            compositeDuration.numberOfSeconds];
  }
  else if (remainingTimeInSeconds <= thresholdInSecondsForMinutesResolution)
  {
    return [NSString stringWithFormat:@"%dh%02dm",
            compositeDuration.numberOfHours,
            compositeDuration.numberOfMinutes];
  }
  else if (remainingTimeInSeconds <= thresholdInSecondsForHoursResolution)
  {
    return [NSString stringWithFormat:@"%dh",
            compositeDuration.numberOfHours];
  }
  else
  {
    compositeDuration = [[[CompositeDuration alloc] initWithDurationInSeconds:thresholdInSecondsForHoursResolution] autorelease];
    return [NSString stringWithFormat:@">%dh",
            compositeDuration.numberOfHours];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of
/// @a remainingNumberOfMovesOrPeriods.
// -----------------------------------------------------------------------------
- (NSString*) stringForRemainingNumberOfMovesOrPeriods:(unsigned long)remainingNumberOfMovesOrPeriods
{
  return (remainingNumberOfMovesOrPeriods <= maximumNumberOfMovesOrPeriods
          ? [NSString stringWithFormat:@"(%lu)", _remainingNumberOfMovesOrPeriods]
          : [NSString stringWithFormat:@"(>%d)", maximumNumberOfMovesOrPeriods]);
}

@end
