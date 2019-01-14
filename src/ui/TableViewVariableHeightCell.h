// -----------------------------------------------------------------------------
// Copyright 2013-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// exception that the description text label is adjusted in width and height to
/// accommodate text that requires more than 1 line.
///
/// To make TableViewVariableHeightCell work as expected, the
/// UITableViewDelegate must NOT override tableView:heightForRowAtIndexPath:(),
/// instead it must set the following UITableView properties:
/// - rowHeight = UITableViewAutomaticDimension (already the default value)
/// - estimatedRowHeight = a non-zero value; for the best results, the value
///   should match the actual height of most of the cells in the table view,
///   because in that case the table view has to make unexpected layout changes
///   only for occasional outlying cells
/// - In iOS 9 and later, make sure that cellLayoutMarginsFollowReadableWidth
///   is set to YES. The reason for this is that in iOS 9 and later,
///   TableViewVariableHeightCell internally uses the cell content view's
///   @e readableContentGuide property. If the UITableView has other cells
///   but cellLayoutMarginsFollowReadableWidth is set to NO, then the default
///   table view cells use different margins than TableViewVariableHeightCell.
///   In iOS 9-11 the default for cellLayoutMarginsFollowReadableWidth is YES,
///   in iOS 12 and later the default for cellLayoutMarginsFollowReadableWidth
///   is NO.
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
/// - The value label is adjusted in width to accommodate its text on exactly
///   one line, without truncating the text.
/// - The value label text is positioned so that it appears 1) right-aligned
///   and 2) vertically centered inside the cell's content view.
/// - The description text label is adjusted in width and height to accomodate
///   its text on multiple lines, without truncating the text.
/// - Due to word wrap, the description text label may not use up all the width
///   available to it, so there is usually some unused spacing between the two
///   labels. In extreme cases, however, the spacing may shrink to 0. This is in
///   accordance to how UITableViewCellStyleValue1 cells behave
/// - TableViewVariableHeightCell does not support indentation or showing an
///   image
/// - TableViewVariableHeightCell is not tested in table views that do not have
///   grouped style
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell : UITableViewCell
{
}

+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UILabel* valueLabel;

@end
