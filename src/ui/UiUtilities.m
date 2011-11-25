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
#import "UiUtilities.h"


@implementation UiUtilities

// -----------------------------------------------------------------------------
/// @brief Calculates the row height for a table view cell of type @a type
/// whose label is about to be displayed containing @a text.
///
/// Supported cell types currently are #DefaultCellType and #SwitchCellType.
///
/// @a hasDisclosureIndicator is true if the cell displays a standard disclosure
/// indicator.
///
/// Assumptions that this method makes:
/// - The cell is not indented, i.e. the cell has the full width of the screen
/// - The label inside the cell uses the default label font and label font size
/// - The label uses UILineBreakModeWordWrap.
///
/// @note This method is intended to be called from inside a table view
/// delegate's tableView:heightForRowAtIndexPath:().
// -----------------------------------------------------------------------------
+ (CGFloat) tableView:(UITableView*)tableView heightForCellOfType:(enum TableViewCellType)type withText:(NSString*)text  hasDisclosureIndicator:(bool)hasDisclosureIndicator
{
  // Calculating the cell height for an empty text results in a value much too
  // small. We therefore return table view's default height for rows
  if (0 == text.length)
    return tableView.rowHeight;

  CGFloat labelWidth;
  switch (type)
  {
    case DefaultCellType:
    {
      // The label has the entire cell width
      labelWidth = cellContentViewWidth - 2 * cellContentDistanceFromEdgeHorizontal;
      break;
    }
    case SwitchCellType:
    {
      // The label shares the cell with a UISwitch
      labelWidth = (cellContentViewWidth
                    - 2 * cellContentDistanceFromEdgeHorizontal
                    - cellContentSwitchWidth
                    - cellContentSpacingHorizontal);
      break;
    }
    default:
    {
      assert(0);
      return tableView.rowHeight;
    }
  }
  if (hasDisclosureIndicator)
    labelWidth -= cellDisclosureIndicatorWidth;

  UIFont* labelFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize constraintSize = CGSizeMake(labelWidth, MAXFLOAT);
  CGSize labelSize = [text sizeWithFont:labelFont
                      constrainedToSize:constraintSize
                          lineBreakMode:UILineBreakModeWordWrap];

  return labelSize.height + 2 * cellContentDistanceFromEdgeVertical;
}

@end
