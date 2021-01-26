// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "TableViewSliderCell.h"
#import "AutoLayoutUtility.h"
#import "UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TableViewSliderCell.
// -----------------------------------------------------------------------------
@interface TableViewSliderCell()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* descriptionLabel;
@property(nonatomic, retain, readwrite) UILabel* valueLabel;
@property(nonatomic, retain, readwrite) UISlider* slider;
@property(nonatomic, assign, readwrite) id delegate;
@property(nonatomic, assign, readwrite) SEL delegateActionValueDidChange;
@property(nonatomic, assign, readwrite) SEL delegateActionSliderValueDidChange;
//@}
/// @brief The horizontal stack view that contains the two labels
@property(nonatomic, retain) UIStackView* stackViewLabels;
/// @brief The vertical stack view that contains the label stack view and the
/// slider.
@property(nonatomic, retain) UIStackView* stackViewSlider;
@end


@implementation TableViewSliderCell

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewSliderCell instance with
/// reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewSliderCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
                                valueLabelHidden:(bool)valueLabelHidden
{
  TableViewSliderCell* cell = [[TableViewSliderCell alloc] initWithReuseIdentifier:reuseIdentifier
                                                                  valueLabelHidden:valueLabelHidden];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewSliderCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewSliderCell.
// -----------------------------------------------------------------------------
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
              valueLabelHidden:(bool)valueLabelHidden
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;
  _valueLabelHidden = valueLabelHidden;
  [self setupCell];
  [self setupContentView];
  // TODO: instead of duplicating code from the setter, we should invoke the
  // setter (self.value = ...), but we need to be sure that it does not update
  // because of its old/new value check
  int newValue = self.slider.minimumValue;
  self.value = newValue;
  self.slider.value = newValue;
  [self updateValueLabel];
  self.delegate = nil;
  self.delegateActionValueDidChange = nil;
  self.delegateActionSliderValueDidChange = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TableViewSliderCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.descriptionLabel = nil;
  self.valueLabel = nil;
  self.slider = nil;
  self.stackViewLabels = nil;
  self.stackViewSlider = nil;
  self.delegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up cell attributes that are not related to the content view.
// -----------------------------------------------------------------------------
- (void) setupCell
{
  // The cell should never appear selected, instead we want the slider
  // to be the active element
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  [self setupDescriptionLabel];
  if (! self.valueLabelHidden)
    [self setupValueLabel];
  [self setupSlider];
  [self setupStackViews];

  [self.contentView addSubview:self.stackViewSlider];

  [self setupAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupDescriptionLabel
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectNull] autorelease];
  self.descriptionLabel.tag = SliderCellDescriptionLabelTag;
  self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
  self.descriptionLabel.backgroundColor = [UIColor clearColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupValueLabel
{
  self.valueLabel = [[[UILabel alloc] initWithFrame:CGRectNull] autorelease];
  self.valueLabel.tag = SliderCellValueLabelTag;
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.backgroundColor = [UIColor clearColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupSlider
{
  self.slider = [[[UISlider alloc] initWithFrame:CGRectNull] autorelease];
  self.slider.tag = SliderCellSliderTag;
  self.slider.continuous = YES;
  [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupStackViews
{
  if (self.valueLabelHidden)
    self.stackViewLabels = [[UIStackView alloc] initWithArrangedSubviews:@[self.descriptionLabel]];
  else
    self.stackViewLabels = [[UIStackView alloc] initWithArrangedSubviews:@[self.descriptionLabel, self.valueLabel]];
  self.stackViewLabels.axis = UILayoutConstraintAxisHorizontal;
  self.stackViewLabels.spacing = [AutoLayoutUtility horizontalSpacingSiblings];

  self.stackViewSlider = [[UIStackView alloc] initWithArrangedSubviews:@[self.stackViewLabels, self.slider]];
  self.stackViewSlider.axis = UILayoutConstraintAxisVertical;
  self.stackViewSlider.spacing = [AutoLayoutUtility verticalSpacingSiblings];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.stackViewSlider.translatesAutoresizingMaskIntoConstraints = NO;
  [self.stackViewSlider.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
  [self.stackViewSlider.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
  [self.stackViewSlider.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
  [self.stackViewSlider.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
}

// -----------------------------------------------------------------------------
/// @brief Updates the integer value of this cell to @a newValue.
///
/// This method also updates the slider's value, so be sure to adjust the
/// slider's minimum/maximum values to accomodate @a newValue before invoking
/// this method.
// -----------------------------------------------------------------------------
- (void) setValue:(int)newValue
{
  if (_value == newValue)
    return;
  _value = newValue;
  self.slider.value = newValue;
  [self updateValueLabel];
  if (self.delegate && self.delegateActionValueDidChange)
  {
    if ([self.delegate respondsToSelector:self.delegateActionValueDidChange])
      [self.delegate performSelector:self.delegateActionValueDidChange withObject:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Update value label to display the slider's new value.
// -----------------------------------------------------------------------------
- (void) sliderValueChanged:(UISlider*)sender
{
  // This check also has the benefit that the value label is not updated
  // unnecessarily many times for fraction changes that we are not interested
  // in
  int newValue = sender.value;
  if (_value == newValue)
    return;
  self.value = newValue;
  if (self.delegate && self.delegateActionSliderValueDidChange)
  {
    if ([self.delegate respondsToSelector:self.delegateActionSliderValueDidChange])
      [self.delegate performSelector:self.delegateActionSliderValueDidChange withObject:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates value label to display the slider's current value (only the
/// integer part).
// -----------------------------------------------------------------------------
- (void) updateValueLabel
{
  if (self.valueLabelHidden)
    return;
  int intValue = self.slider.value;
  self.valueLabel.text = [NSString stringWithFormat:@"%d", intValue];
}

// -----------------------------------------------------------------------------
/// @brief Configures this cell with @a delegate and selectors for methods to
/// invoke when the cell's integer value changes.
// -----------------------------------------------------------------------------
- (void) setDelegate:(id)aDelegate actionValueDidChange:(SEL)action1 actionSliderValueDidChange:(SEL)action2
{
  self.delegate = aDelegate;
  self.delegateActionValueDidChange = action1;
  self.delegateActionSliderValueDidChange = action2;
}

@end
