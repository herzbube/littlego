// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "UIColorAdditions.h"
#import "UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TableViewSliderCell.
// -----------------------------------------------------------------------------
@interface TableViewSliderCell()
/// @name Initialization and deallocation
//@{
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;
- (void) dealloc;
- (void) setupCell;
- (void) setupContentView;
//@}
/// @name Action methods
//@{
- (void) sliderValueChanged:(UISlider*)sender;
//@}
/// @name Other methods
//@{
- (CGRect) descriptionLabelFrame;
- (CGRect) valueLabelFrame;
- (CGRect) sliderFrame;
- (void) updateValueLabel;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* descriptionLabel;
@property(nonatomic, retain, readwrite) UILabel* valueLabel;
@property(nonatomic, retain, readwrite) UISlider* slider;
@property(nonatomic, retain, readwrite) id delegate;
@property(nonatomic, assign, readwrite) SEL delegateActionValueDidChange;
@property(nonatomic, assign, readwrite) SEL delegateActionSliderValueDidChange;
//@}
@end


@implementation TableViewSliderCell

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewSliderCell instance with
/// reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewSliderCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewSliderCell* cell = [[TableViewSliderCell alloc] initWithReuseIdentifier:reuseIdentifier];
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
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;

  [self setupCell];
  [self setupContentView];
  [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

  // TODO: instead of duplicating code from the setter, we should invoke the
  // setter (self.value = ...), but we need to be sure that it does not update
  // because of its old/new value check
  int newValue = self.slider.minimumValue;
  self.value = newValue;
  self.slider.value = newValue;
  [self updateValueLabel];

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
  CGRect descriptionLabelRect = [self descriptionLabelFrame];
  self.descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelRect];  // no autorelease, property is retained
  self.descriptionLabel.tag = SliderCellDescriptionLabelTag;
  self.descriptionLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
  self.descriptionLabel.textAlignment = UITextAlignmentLeft;
  self.descriptionLabel.textColor = [UIColor blackColor];
  self.descriptionLabel.backgroundColor = [UIColor clearColor];
  self.descriptionLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin);
  [self.contentView addSubview:self.descriptionLabel];

  CGRect valueLabelRect = [self valueLabelFrame];
  self.valueLabel = [[UILabel alloc] initWithFrame:valueLabelRect];  // no autorelease, property is retained
  self.valueLabel.tag = SliderCellValueLabelTag;
  self.valueLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  self.valueLabel.textAlignment = UITextAlignmentRight;
  self.valueLabel.textColor = [UIColor slateBlueColor];
  self.valueLabel.backgroundColor = [UIColor clearColor];
  self.valueLabel.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin);
  [self.contentView addSubview:self.valueLabel];

  CGRect sliderRect = [self sliderFrame];
  self.slider = [[UISlider alloc] initWithFrame:sliderRect];  // no autorelease, property is retained
  self.slider.tag = SliderCellSliderTag;
  self.slider.continuous = YES;
  self.slider.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  [self.contentView addSubview:self.slider];
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the description label. Assumes that an
/// autoresizingMask is later applied to the label that will make it resize
/// properly.
// -----------------------------------------------------------------------------
- (CGRect) descriptionLabelFrame
{
  int descriptionLabelX = [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal];
  int descriptionLabelY = [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
  // Arbitrary value that hopefully leaves enough space for the value label
  static const int descriptionLabelWidth = 230;
  int descriptionLabelHeight = [UiElementMetrics labelHeight];
  return CGRectMake(descriptionLabelX, descriptionLabelY, descriptionLabelWidth, descriptionLabelHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the value label. Assumes that an
/// autoresizingMask is later applied to the label that will make it resize
/// properly.
// -----------------------------------------------------------------------------
- (CGRect) valueLabelFrame
{
  CGSize superViewSize = self.contentView.bounds.size;
  int valueLabelX = (self.descriptionLabel.frame.origin.x
                     + self.descriptionLabel.frame.size.width
                     + [UiElementMetrics spacingHorizontal]);
  int valueLabelY = self.descriptionLabel.frame.origin.y;
  int valueLabelWidth = (superViewSize.width
                         - valueLabelX
                         - [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal]);
  int valueLabelHeight = [UiElementMetrics labelHeight];
  return CGRectMake(valueLabelX, valueLabelY, valueLabelWidth, valueLabelHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the frame of the slider. Assumes that an autoresizingMask
/// is later applied to the label that will make it resize properly.
// -----------------------------------------------------------------------------
- (CGRect) sliderFrame
{
  int sliderX = self.descriptionLabel.frame.origin.x;
  int sliderY = (self.descriptionLabel.frame.origin.y
                 + self.descriptionLabel.frame.size.height
                 + [UiElementMetrics spacingVertical]);
  int sliderWidth = (self.valueLabel.frame.origin.x
                     + self.valueLabel.frame.size.width
                     - sliderX);
  int sliderHeight = [UiElementMetrics sliderHeight];
  return CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);
}

// -----------------------------------------------------------------------------
/// @brief Returns the row height for TableViewSliderCell objects.
// -----------------------------------------------------------------------------
+ (CGFloat) rowHeightInTableView:(UITableView*)tableView
{
  static CGFloat rowHeight = 0;
  if (0 == rowHeight)
  {
    rowHeight = (2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical]
                 + [UiElementMetrics labelHeight]
                 + [UiElementMetrics spacingVertical]
                 + [UiElementMetrics sliderHeight]);
  }
  return rowHeight;
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
  if ([self.delegate respondsToSelector:self.delegateActionValueDidChange])
    [self.delegate performSelector:self.delegateActionValueDidChange withObject:self];
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
  if ([self.delegate respondsToSelector:self.delegateActionSliderValueDidChange])
    [self.delegate performSelector:self.delegateActionSliderValueDidChange withObject:self];
}

// -----------------------------------------------------------------------------
/// @brief Updates value label to display the slider's current value (only the
/// integer part).
// -----------------------------------------------------------------------------
- (void) updateValueLabel
{
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
