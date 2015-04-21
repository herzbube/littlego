// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "TableViewVariableHeightCell.h"
#import "AutoLayoutUtility.h"
#import "UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// TableViewVariableHeightCell.
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* descriptionLabel;
@property(nonatomic, retain, readwrite) UILabel* valueLabel;
//@}
@property(nonatomic, assign) CGFloat leftEdgeSpacing;
@property(nonatomic, assign) NSLayoutConstraint* rightEdgeSpacingConstraint;
@end

@implementation TableViewVariableHeightCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewVariableHeightCell
/// instance with reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewVariableHeightCell* cell = [[TableViewVariableHeightCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewVariableHeightCell object with reuse
/// identifier @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewVariableHeightCell.
// -----------------------------------------------------------------------------
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleValue1
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;
  [self setupContentView];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.descriptionLabel = nil;
  self.valueLabel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  [self.contentView addSubview:self.descriptionLabel];
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;

  self.valueLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  [self.contentView addSubview:self.valueLabel];
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.textColor = [UIColor tableViewCellDetailTextLabelColor];

  self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;

  CGFloat horizontalSpacingTableViewCell = [AutoLayoutUtility horizontalSpacingTableViewCell];
  CGFloat verticalSpacingTableViewCell = [AutoLayoutUtility verticalSpacingTableViewCell];
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.descriptionLabel, @"descriptionLabel",
                                   self.valueLabel, @"valueLabel",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:|-%f-[descriptionLabel]-0-[valueLabel]", horizontalSpacingTableViewCell],
                            [NSString stringWithFormat:@"V:|-%f-[descriptionLabel]-%f-|", verticalSpacingTableViewCell, verticalSpacingTableViewCell],
                            [NSString stringWithFormat:@"V:|-%f-[valueLabel]-%f-|", verticalSpacingTableViewCell, verticalSpacingTableViewCell],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.contentView];

  self.leftEdgeSpacing = horizontalSpacingTableViewCell;
  NSArray* rightEdgeSpacingConstraints = [AutoLayoutUtility installVisualFormats:[NSArray arrayWithObject:@"H:[valueLabel]-0-|"]
                                                                       withViews:viewsDictionary
                                                                          inView:self.contentView];
  self.rightEdgeSpacingConstraint = [rightEdgeSpacingConstraints firstObject];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  // If there is no accessory view we have to provide our own spacing at the
  // right edge
  if (self.accessoryType == UITableViewCellAccessoryNone)
    self.rightEdgeSpacingConstraint.constant = self.leftEdgeSpacing;
  else
    self.rightEdgeSpacingConstraint.constant = 0;

  // The purpose of this first layout pass is that the content view gets its
  // correct width, because we need that width to calculate the description
  // label's preferredMaxLayoutWidth.
  [super layoutSubviews];

  // Multi-line labels only expand vertically if their preferredMaxLayoutWidth
  // property is set. In a "normal" view hierarchy the Auto Layout engine
  // automatically sets the property to a width that fits the bounds of the
  // label's superview. Here we need to set the property manually because
  // heightForRowInTableView... below is layouting an offscreen cell which is
  // not embedded in a view hierarchy and therefore is not constrained by the
  // bounds of a superview.
  CGFloat valueLabelWidth = self.valueLabel.intrinsicContentSize.width;
  CGFloat totalAmountOfHorizontalSpacing = self.leftEdgeSpacing + self.rightEdgeSpacingConstraint.constant;
  self.descriptionLabel.preferredMaxLayoutWidth = (self.contentView.bounds.size.width
                                                   - valueLabelWidth
                                                   - totalAmountOfHorizontalSpacing);

  // This second layout pass is required, obviously, because we just changed one
  // of the layouting properties of one of this cell's subviews.
  [super layoutSubviews];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Calculates the row height for a TableViewVariableHeightCell that is
/// to display @a descriptionText and @a valueText in its corresponding labels.
///
/// @a hasDisclosureIndicator is true if the cell displays a standard disclosure
/// indicator.
///
/// @note This method is intended to be called from inside a table view
/// delegate's tableView:heightForRowAtIndexPath:().
///
/// Assumptions that this method makes:
/// - The cell is not indented, i.e. the cell has the full width of the screen
/// - The appearance of the labels inside the cell has not been modified (e.g.
///   no font or line break changes).
///
/// If any of these assumptions are not true, the caller must
// -----------------------------------------------------------------------------
+ (CGFloat) heightForRowInTableView:(UITableView*)tableView
                    descriptionText:(NSString*)descriptionText
                          valueText:(NSString*)valueText
             hasDisclosureIndicator:(bool)hasDisclosureIndicator
{
  static TableViewVariableHeightCell* dummyCell = nil;
  if (nil == dummyCell)
  {
    dummyCell = [TableViewVariableHeightCell cellWithReuseIdentifier:@"dummyCell"];
    [dummyCell retain];
  }
  dummyCell.descriptionLabel.text = descriptionText;
  dummyCell.valueLabel.text = valueText;
  if (hasDisclosureIndicator)
    dummyCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  else
    dummyCell.accessoryType = UITableViewCellAccessoryNone;
  CGRect dummyCellBounds = dummyCell.bounds;
  dummyCellBounds.size.width = tableView.bounds.size.width;
  dummyCell.bounds = dummyCellBounds;
  [dummyCell setNeedsLayout];
  [dummyCell layoutIfNeeded];
  CGFloat height = [dummyCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
  // +1 for the separator line drawn between cells
  height += 1.0f;
  return height;
}

@end
