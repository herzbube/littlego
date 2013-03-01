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
#import "TableViewSegmentedCell.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TableViewSegmentedCell.
// -----------------------------------------------------------------------------
@interface TableViewSegmentedCell()
/// @name Initialization and deallocation
//@{
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;
- (void) dealloc;
- (void) setupCell;
- (void) setupContentView;
//@}
/// @name Overrides from superclass
//@{
- (void) layoutSubviews;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UISegmentedControl* segmentedControl;
//@}
@end


@implementation TableViewSegmentedCell

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewSegmentedCell instance
/// with reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewSegmentedCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewSegmentedCell* cell = [[TableViewSegmentedCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewSegmentedCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewSegmentedCell.
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
/// @brief Deallocates memory allocated by this TableViewSegmentedCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.segmentedControl = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up cell attributes that are not related to the content view.
// -----------------------------------------------------------------------------
- (void) setupCell
{
  // The cell should never appear selected, instead we want the segmented
  // control to be the active element
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  NSArray* segmentedItems = nil;
  self.segmentedControl = [[[UISegmentedControl alloc] initWithItems:segmentedItems] autorelease];
  self.segmentedControl.tag = SegmentedCellSegmentedControlTag;
  self.segmentedControl.segmentedControlStyle = UISegmentedControlStylePlain;
  self.segmentedControl.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [self.contentView addSubview:self.segmentedControl];
}

// -----------------------------------------------------------------------------
/// @brief Determine frames of all UI elements in this cell.
///
/// This overrides the superclass implementation. We need this to make sure that
/// the UISegmentedControl fully covers the white background of the cell. The
/// default size of the control is slightly too small to cover the entire cell
/// background, resulting in an ugly border around the control. To fix this we
/// slightly enlarge the control.
///
/// A cleaner solution, which would let us keep the control's default size,
/// would be to set the alpha of the cell's background view. Unfortunately this
/// can only be done in the table view delegate (in the override for
/// tableView:willDisplayCell:forRowAtIndexPath:), which would place an
/// unacceptable burden on users of this class.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  // The content view is not a subview of the background view, so we need to
  // use the background view's ***frame*** (not its bounds).
  CGRect backgroundViewFrame = self.backgroundView.frame;
  // If this cell is the only cell in a section it also needs to cover the
  // section bottom
  backgroundViewFrame.size.height++;
  self.contentView.frame = backgroundViewFrame;
  self.segmentedControl.frame = self.contentView.bounds;
}

@end
