// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiElementMetrics.h"


@implementation TableViewVariableHeightCell

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
  return self;
}

// -----------------------------------------------------------------------------
/// @brief This overrides the superclass implementation.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  // Temporarily reset the text label to its default single-line layout so that
  // the superclass implementation can do its work
  self.textLabel.numberOfLines = 1;
  [super layoutSubviews];
  self.textLabel.numberOfLines = 0;

  CGSize newDetailTextLabelSize;
  CGSize newTextLabelSize;
  [self calculateNewDetailTextLabelSize:&newDetailTextLabelSize newTextLabelSize:&newTextLabelSize];

  [self adjustTextLabelWithNewSize:newTextLabelSize];
  [self adjustDetailTextLabelWithNewSize:newDetailTextLabelSize
                        newTextLabelHeight:newTextLabelSize.height
                          textLabelOriginY:self.textLabel.frame.origin.y];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for layoutSubviews().
// -----------------------------------------------------------------------------
- (void) calculateNewDetailTextLabelSize:(CGSize*)newDetailTextLabelSize
                        newTextLabelSize:(CGSize*)newTextLabelSize
{
  *newDetailTextLabelSize = [TableViewVariableHeightCell sizeForDetailText:self.detailTextLabel.text
                                                                  withFont:self.detailTextLabel.font];
  bool hasDisclosureIndicator = (self.accessoryType != UITableViewCellAccessoryNone);
  *newTextLabelSize = [TableViewVariableHeightCell sizeForText:self.textLabel.text
                                           withDetailTextWidth:newDetailTextLabelSize->width
                                        hasDisclosureIndicator:hasDisclosureIndicator
                                                      withFont:self.textLabel.font];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for layoutSubviews().
// -----------------------------------------------------------------------------
- (void) adjustTextLabelWithNewSize:(CGSize)newTextLabelSize
{
  CGRect textLabelFrame = self.textLabel.frame;
  textLabelFrame.origin.y = [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
  textLabelFrame.size = newTextLabelSize;
  self.textLabel.frame = textLabelFrame;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for layoutSubviews().
// -----------------------------------------------------------------------------
- (void) adjustDetailTextLabelWithNewSize:(CGSize)newDetailTextLabelSize
                       newTextLabelHeight:(CGFloat)newTextLabelHeight
                         textLabelOriginY:(CGFloat)textLabelOriginY
{
  CGRect detailTextLabelFrame = self.detailTextLabel.frame;
  // Remain right-aligned
  detailTextLabelFrame.origin.x = (CGRectGetMaxX(detailTextLabelFrame)
                                   - newDetailTextLabelSize.width);
  // Vertically centered
  detailTextLabelFrame.origin.y = (textLabelOriginY
                                   + ((newTextLabelHeight - newDetailTextLabelSize.height) / 2.0));
  // Finally, don't forget the size
  detailTextLabelFrame.size = newDetailTextLabelSize;
  self.detailTextLabel.frame = detailTextLabelFrame;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the row height for a TableViewVariableHeightCell that is
/// to display @a text in its text label, and @a detailText in its detail text
/// label.
///
/// @a hasDisclosureIndicator is true if the cell displays a standard disclosure
/// indicator.
///
/// Assumptions that this method makes:
/// - The cell is not indented, i.e. the cell has the full width of the screen
/// - The cell does not use an image
/// - Both labels inside the cell use the default label font and label font size
/// - The label displaying @a text uses NSLineBreakByWordWrapping
///
/// @note This method is intended to be called from inside a table view
/// delegate's tableView:heightForRowAtIndexPath:().
// -----------------------------------------------------------------------------
+ (CGFloat) heightForRowWithText:(NSString*)text
                      detailText:(NSString*)detailText
          hasDisclosureIndicator:(bool)hasDisclosureIndicator
{
  UIFont* labelFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize detailTextSize = [TableViewVariableHeightCell sizeForDetailText:detailText
                                                                withFont:labelFont];
  CGSize textSize = [TableViewVariableHeightCell sizeForText:text
                                         withDetailTextWidth:detailTextSize.width
                                      hasDisclosureIndicator:hasDisclosureIndicator
                                                    withFont:labelFont];
  return (textSize.height
          + 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical]);
}

// -----------------------------------------------------------------------------
/// @brief Calculates and returns the size for the detail text @a detailText.
///
/// The text is allowed to get as much width as is required to display it with
/// no truncation
// -----------------------------------------------------------------------------
+ (CGSize) sizeForDetailText:(NSString*)detailText
                    withFont:(UIFont*)labelFont
{
  CGSize detailTextConstraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  return [detailText sizeWithFont:labelFont
                constrainedToSize:detailTextConstraintSize
                    lineBreakMode:NSLineBreakByClipping];
}

// -----------------------------------------------------------------------------
/// @brief Calculates and returns the size for the text @a text.
///
/// The text is constrained to the width that remains after @a detailTextWidth
/// and @a hasDisclosureIndicator have been taken into account. The text is
/// allowed to get as much height as is required to display it with no
/// truncation.
// -----------------------------------------------------------------------------
+ (CGSize) sizeForText:(NSString*)text
   withDetailTextWidth:(CGFloat)detailTextWidth
hasDisclosureIndicator:(bool)hasDisclosureIndicator
              withFont:(UIFont*)labelFont
{
  CGFloat totalWidthAvailableForBothTexts = [UiElementMetrics tableViewCellContentViewAvailableWidth];
  if (hasDisclosureIndicator)
    totalWidthAvailableForBothTexts -= [UiElementMetrics tableViewCellDisclosureIndicatorWidth];
  CGFloat maximumTextWidth = totalWidthAvailableForBothTexts - detailTextWidth;
  CGSize textConstraintSize = CGSizeMake(maximumTextWidth, MAXFLOAT);
  return [text sizeWithFont:labelFont
          constrainedToSize:textConstraintSize
              lineBreakMode:NSLineBreakByWordWrapping];
}

@end
