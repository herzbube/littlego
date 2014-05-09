// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "AutoLayoutUtility.h"


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
  [self setupAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupDescriptionLabel
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
  self.descriptionLabel.tag = SliderCellDescriptionLabelTag;
  self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
  self.descriptionLabel.backgroundColor = [UIColor clearColor];
  [self.contentView addSubview:self.descriptionLabel];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupValueLabel
{
  self.valueLabel = [[[UILabel alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
  self.valueLabel.tag = SliderCellValueLabelTag;
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.backgroundColor = [UIColor clearColor];
  [self.contentView addSubview:self.valueLabel];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupSlider
{
  self.slider = [[[UISlider alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
  self.slider.tag = SliderCellSliderTag;
  self.slider.continuous = YES;
  [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
  [self.contentView addSubview:self.slider];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.slider.translatesAutoresizingMaskIntoConstraints = NO;
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          self.descriptionLabel, @"descriptionLabel",
                                          self.slider, @"slider",
                                          nil];
  CGFloat horizontalSpacingSiblings = [AutoLayoutUtility horizontalSpacingSiblings];
  CGFloat verticalSpacingSiblings = [AutoLayoutUtility verticalSpacingSiblings];
  CGFloat horizontalSpacingTableViewCell = [AutoLayoutUtility horizontalSpacingTableViewCell];
  CGFloat verticalSpacingTableViewCell = [AutoLayoutUtility verticalSpacingTableViewCell];
  NSString* visualFormat1 = [NSString stringWithFormat:@"H:|-%f-[descriptionLabel]-%f-|", horizontalSpacingTableViewCell, horizontalSpacingTableViewCell];
  NSString* visualFormat2 = [NSString stringWithFormat:@"H:|-%f-[descriptionLabel]-%f-[valueLabel]-%f-|", horizontalSpacingTableViewCell, horizontalSpacingSiblings, horizontalSpacingTableViewCell];
  NSString* visualFormat3 = [NSString stringWithFormat:@"H:|-%f-[slider]-%f-|", horizontalSpacingTableViewCell, horizontalSpacingTableViewCell];
  NSString* visualFormat4 = [NSString stringWithFormat:@"V:|-%f-[descriptionLabel]-%f-[slider]", verticalSpacingTableViewCell, verticalSpacingSiblings];
  NSString* visualFormat5 = [NSString stringWithFormat:@"V:|-%f-[valueLabel]", verticalSpacingTableViewCell];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   visualFormat3,
                                   visualFormat4,
                                   nil];
  if (self.valueLabelHidden)
  {
    [visualFormats addObject:visualFormat1];
  }
  else
  {
    [viewsDictionary setObject:self.valueLabel forKey:@"valueLabel"];
    [visualFormats addObject:visualFormat2];
    [visualFormats addObject:visualFormat5];
  }
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.contentView];
}

// -----------------------------------------------------------------------------
/// @brief Returns the row height for TableViewSliderCell objects.
// -----------------------------------------------------------------------------
+ (CGFloat) rowHeightInTableView:(UITableView*)tableView
{
  static CGFloat rowHeight = 0;
  if (0 == rowHeight)
  {
    UILabel* dummyLabel = [[[UILabel alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    dummyLabel.text = @"A";
    [dummyLabel setNeedsLayout];
    [dummyLabel layoutIfNeeded];
    CGSize labelSize = [dummyLabel systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    UISlider* dummySlider = [[[UISlider alloc] initWithFrame:[UIScreen mainScreen].bounds] autorelease];
    [dummySlider setNeedsLayout];
    [dummySlider layoutIfNeeded];
    CGSize sliderSize = [dummySlider systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

    rowHeight = (2 * [AutoLayoutUtility verticalSpacingTableViewCell]
                 + labelSize.height
                 + [AutoLayoutUtility verticalSpacingSiblings]
                 + sliderSize.height);
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
