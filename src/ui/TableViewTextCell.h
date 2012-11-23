// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates tags of subviews of TableViewTextCell.
// -----------------------------------------------------------------------------
enum TextCellSubViewTag
{
  TextCellLabelTag = 1,  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
  TextCellTextFieldTag
};


// -----------------------------------------------------------------------------
/// @brief The TableViewTextCell class implements a custom table view cell
/// that contains an optional label with descriptive text, and an editable
/// text field.
///
/// TableViewTextCell adds its UI elements as subview to its content view and
/// arranges them according to the following schema:
///
/// @verbatim
/// +-------------------------------------------------------------------------+
/// |                                                                         |
/// |  +----------------------------+  +-----------------------------------+  |
/// |  | UILabel (descriptive text) |  | UITextField (value)               |  |
/// |  +----------------------------+  +-----------------------------------+  |
/// |                                                                         |
/// +-------------------------------------------------------------------------+
/// @endverbatim
///
/// Notes and constraints:
/// - Each UI element has its view tag set to a value from the
///   #TextCellSubViewTag enum
/// - The label width adjusts to the text it contains, the text field then
///   gets all the remaining width
/// - The text field has a minimum width so that it can't be pushed off the
///   screen by a label with a very long text
/// - The label is hidden if it contains zero characters
/// - TableViewTextCell is not tested in table views that do not have grouped
///   style
// -----------------------------------------------------------------------------
@interface TableViewTextCell : UITableViewCell
{
}

+ (TableViewTextCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

@property(nonatomic, retain, readonly) UILabel* label;
@property(nonatomic, retain, readonly) UITextField* textField;

@end
