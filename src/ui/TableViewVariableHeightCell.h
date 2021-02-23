// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
///   does not automatically get the unused space. The @e descriptionLabel
///   property can be set to change the horizontal space distribution.
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
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell : UITableViewCell
{
}

+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UILabel* valueLabel;
/// @brief Defines the percentage of the available horizontal space that is
/// assigned to the description label. The value label gets the remaining space.
/// The default percentage is 0.5, i.e. both labels get the same amount of
/// space.
///
/// Raises NSInvalidArgumentException if the property is set with a value that
/// is less than zero, or greater than 1.
@property(nonatomic, assign) CGFloat descriptionLabelWidthPercentage;

@end
