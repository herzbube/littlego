// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) UILabel* descriptionLabel;
@property(readwrite, retain) UILabel* valueLabel;
@property(readwrite, retain) UISlider* slider;
//@}
@end


@implementation TableViewSliderCell

@synthesize descriptionLabel;
@synthesize valueLabel;
@synthesize slider;


// Values determined experimentally by debugging a default UITableViewCell
static const int distanceFromEdgeHorizontal = 10;
static const int distanceFromEdgeVertical = 11;
// Spacing between UI elements (values determined experimentally in
// Interface Builder)
static const int spacingHorizontal = 8;
static const int spacingVertical = 8;
// UI elements sizes (values also from IB)
static const int labelHeight = 21;
static const int sliderHeight = 23;
// Arbitrary value that hopefully leaves enough space for the value label
static const int descriptionLabelWidth = 230;


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
  // self.contentView still thinks it has the entire table view width, but in a
  // table view with grouped style the available width will be less because the
  // cell is set off from the view edges both on the left and the right
  // -> through debugging we know that the offset happens to be the default
  //    indentation width
  // -> this is probably not a coincidence, so we boldly use this indentation
  //    width for our calculations
  int contentViewWidth = self.contentView.bounds.size.width - (2 * self.indentationWidth);

  assert(descriptionLabelWidth < contentViewWidth);
  CGRect descriptionLabelRect = CGRectMake(distanceFromEdgeHorizontal, distanceFromEdgeVertical, descriptionLabelWidth, labelHeight);
  descriptionLabel = [[UILabel alloc] initWithFrame:descriptionLabelRect];  // no autorelease, property is retained
  descriptionLabel.tag = SliderCellDescriptionLabelTag;
  descriptionLabel.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
  descriptionLabel.textAlignment = UITextAlignmentLeft;
  descriptionLabel.textColor = [UIColor blackColor];
  [self.contentView addSubview:descriptionLabel];

  int valueLabelX = descriptionLabelRect.origin.x + descriptionLabelRect.size.width + spacingHorizontal;
  int valueLabelY = descriptionLabelRect.origin.y;
  int valueLabelWidth = contentViewWidth - valueLabelX - distanceFromEdgeHorizontal;
  assert(valueLabelWidth > 0);
  CGRect valueLabelRect = CGRectMake(valueLabelX, valueLabelY, valueLabelWidth, labelHeight);
  valueLabel = [[[UILabel alloc] initWithFrame:valueLabelRect] autorelease];  // no autorelease, property is retained
  valueLabel.tag = SliderCellValueLabelTag;
  valueLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  valueLabel.textAlignment = UITextAlignmentRight;
  valueLabel.textColor = [UIColor slateBlueColor];
  [self.contentView addSubview:valueLabel];

  int sliderX = descriptionLabelRect.origin.x;
  int sliderY = descriptionLabelRect.origin.y + descriptionLabelRect.size.height + spacingVertical;
  int sliderWidth = valueLabelX + valueLabelWidth - sliderX;
  CGRect sliderRect = CGRectMake(sliderX, sliderY, sliderWidth, sliderHeight);
  slider = [[[UISlider alloc] initWithFrame: sliderRect] autorelease];  // no autorelease, property is retained
  slider.tag = SliderCellSliderTag;
  [self.contentView addSubview:slider];
}

// -----------------------------------------------------------------------------
/// @brief Returns the row height for TableViewSliderCell objects.
// -----------------------------------------------------------------------------
+ (CGFloat) rowHeightInTableView:(UITableView*)tableView
{
  static CGFloat rowHeight = 0;
  if (0 == rowHeight)
  {
    rowHeight = 2 * distanceFromEdgeVertical + labelHeight + spacingVertical + sliderHeight;
  }
  return rowHeight;
}


@end
