// -----------------------------------------------------------------------------
// Copyright 20256 Patrick Näf (herzbube@herzbube.ch)
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
#import "InvalidTimeDataView.h"
#import "../../go/GoTimeDataValidator.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for InvalidTimeDataView.
// -----------------------------------------------------------------------------
@interface InvalidTimeDataView()
@property(nonatomic, assign) bool viewContentNeedsUpdate;
@property(nonatomic, assign) UILabel* invalidReasonDescriptionLabel;
@end


@implementation InvalidTimeDataView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a InvalidTimeDataView object.
///
/// @note This is the designated initializer of InvalidTimeDataView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.viewContentNeedsUpdate = true;
  
  self.isTimeDataValid = false;
  self.timeDataInvalidReason = GoTimeDataValidationResultInvalid.timeDataInvalidReason;

  [self setupViewHierarchy];
  [self configureView];
  [self setupAutoLayoutConstraints];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InvalidTimeDataView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.invalidReasonDescriptionLabel = nil;

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

#pragma mark - One-time view setup

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.invalidReasonDescriptionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  [self addSubview:self.invalidReasonDescriptionLabel];
}

// -----------------------------------------------------------------------------
/// @brief Configures the view and its elements.
// -----------------------------------------------------------------------------
- (void) configureView
{
  enum UIType uiType = [LayoutManager sharedManager].uiType;
  CGFloat fontSize = [UiElementMetrics statusAreaLabelFontSizeForUiType:uiType];

  self.invalidReasonDescriptionLabel.numberOfLines = 2;
  self.invalidReasonDescriptionLabel.font = [UIFont systemFontOfSize:fontSize];
  self.invalidReasonDescriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  self.invalidReasonDescriptionLabel.textAlignment = NSTextAlignmentCenter;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.invalidReasonDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self withSubview:self.invalidReasonDescriptionLabel];
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

  if (self.isTimeDataValid)
    self.invalidReasonDescriptionLabel.text = @"Time data is valid";
  else
    self.invalidReasonDescriptionLabel.text = [NSString stringWithFormat:@"No time data. Reason: %d.", self.timeDataInvalidReason];
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
- (void) setTimeDataInvalidReason:(enum GoTimeDataInvalidReason)newValue
{
  if (_timeDataInvalidReason == newValue)
    return;
  _timeDataInvalidReason = newValue;

  self.viewContentNeedsUpdate = true;
  [self setNeedsLayout];
}

@end
