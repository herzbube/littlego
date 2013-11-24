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



// -----------------------------------------------------------------------------
/// @brief The TableViewVariableHeightCell class implements a custom table view
/// cell that in general looks like UITableViewCellStyleValue1, with the
/// exception that the text label is adjusted in width and height to accommodate
/// text that requires more than 1 line.
///
/// To make TableViewVariableHeightCell work as expected, a UITableViewDelegate
/// must override tableView:heightForRowAtIndexPath: and return the value of
/// heightForRowWithText:detailText:hasDisclosureIndicator:().
///
/// TableViewVariableHeightCell arranges its labels within its content view
/// according to the following schema:
///
/// @verbatim
/// +-------------------------------------------------------------------------+
/// |                                                                         |
/// |  +----------------------------------+                                   |
/// |  | UILabel (descriptive text)       |           +--------------------+  |
/// |  | line 2                           |  spacing  | UILabel (value)    |  |
/// |  | line 3                           |           +--------------------+  |
/// |  +----------------------------------+                                   |
/// |                                                                         |
/// +-------------------------------------------------------------------------+
/// @endverbatim
///
/// Notes and constraints:
/// - The value label (cell.detailTextLabel) is adjusted in width to accommodate
///   its text on exactly one line, without truncating the text.
/// - The value label is positioned so that it appears 1) right-aligned and 2)
///   vertically centered inside the cell's content view.
/// - The text label (cell.textLabel) is adjusted in width and height to
///   accommodate its text on multiple lines, without truncating the text.
/// - Due to word wrap, the text label may not use up all the width available
///   to it, so there is usually some unused spacing between the two labels.
///   In extreme cases, however, the spacing may shrink to 0. This is in
///   accordance to how UITableViewCellStyleValue1 cells behave
/// - TableViewVariableHeightCell is not tested in table views that do not have
///   grouped style
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell : UITableViewCell
{
}

+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;
+ (CGFloat) heightForRowWithText:(NSString*)text
                      detailText:(NSString*)detailText
          hasDisclosureIndicator:(bool)hasDisclosureIndicator;

@end
