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
/// exception that the two text labels are adjusted in height to accommodate
/// text that requires more than 1 line.
///
/// Notes and constraints:
/// - Due to word wrap, the labels may not use up all the width available to
///   them, so there is usually some unused spacing between them. In extreme
///   cases, however, the spacing may shrink to 0. This is in accordance to how
///   UITableViewCellStyleValue1 cells behave.
/// - By default the two text labels take up an equal amount of horizontal
///   space. This can lead to wasted space, because when one of the labels uses
///   only a short text and does not use its allotted space then the other label
///   does not automatically get the unused space. The @e widthRatio property
///   can be set to change the horizontal space distribution.
/// - TableViewVariableHeightCell does not support indentation or showing an
///   image
/// - TableViewVariableHeightCell is not tested in table views that do not have
///   grouped style
///
/// @note The implementation of TableViewVariableHeightCell is based on
/// UIStackView, which does all of the layouting heavy-lifting, and the use of
/// layout guides. Before UIStackView and layout guides were available (iOS 8
/// and before) the implementation of TableViewVariableHeightCell was much more
/// complicated and there were a lot of limitations.
///
/// If the content of TableViewVariableHeightCell work as expected, the
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
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell : UITableViewCell
{
}

+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UILabel* valueLabel;
/// @brief Defines the ratio how the horizontal space is distributed between
/// the two text labels. The ratio is "description label : value label", i.e.
/// a ratio of 2.5 means the value label's width is 2.5 times the description
/// label's width. The default ratio is 1.0, i.e. both labels have equal width.
@property(nonatomic, assign) CGFloat widthRatio;

@end
