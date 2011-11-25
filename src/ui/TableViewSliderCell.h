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


// -----------------------------------------------------------------------------
/// @brief Enumerates tags of subviews of TableViewSliderCell.
// -----------------------------------------------------------------------------
enum SliderCellSubViewTag
{
  SliderCellDescriptionLabelTag = 1,  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
  SliderCellValueLabelTag,
  SliderCellSliderTag
};


// -----------------------------------------------------------------------------
/// @brief The TableViewSliderCell class implements a custom table view cell
/// that displays an integer value and uses a UISlider to change that value.
///
/// TableViewSliderCell adds its UI elements as subview to its content view and
/// arranges them according to the following schema:
///
/// @verbatim
/// +-------------------------------------------------------------------------+
/// |                                                                         |
/// |  +----------------------------------------------+  +-----------------+  |
/// |  | UILabel (descriptive text)                   |  | UILabel (value) |  |
/// |  +----------------------------------------------+  +-----------------+  |
/// |                                                                         |
/// |  +-------------------------------------------------------------------+  |
/// |  | UISlider                                                          |  |
/// |  +-------------------------------------------------------------------+  |
/// |                                                                         |
/// +-------------------------------------------------------------------------+
/// @endverbatim
///
/// Notes and constraints:
/// - Use the @e value property to set or get the integer value
/// - Each UI element has its view tag set to a value from the
///   #SliderCellSubViewTag enum
/// - The labels' width is fixed
/// - The value label has room for roughly 3-4 characters
/// - TableViewSliderCell was not designed to be used in editing mode
/// - TableViewSliderCell is not tested in table views that do not have grouped
///   style
// -----------------------------------------------------------------------------
@interface TableViewSliderCell : UITableViewCell
{
}

+ (TableViewSliderCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;
+ (CGFloat) rowHeightInTableView:(UITableView*)tableView;
- (void) setDelegate:(id)aDelegate actionValueDidChange:(SEL)action1 actionSliderValueDidChange:(SEL)action2;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UILabel* valueLabel;
@property(nonatomic, retain, readonly) UISlider* slider;
@property(nonatomic, assign) int value;
/// @brief Delegate object that will be informed when the cell's integer
/// value changes.
@property(nonatomic, retain, readonly) id delegate;
/// @brief Is invoked when the cell's integer value changes, regardless of the
/// source of the change.
@property(nonatomic, assign, readonly) SEL delegateActionValueDidChange;
/// @brief Is invoked when the user's interaction with the slider causes the
/// cell's integer value to change.
@property(nonatomic, assign, readonly) SEL delegateActionSliderValueDidChange;
//@}

@end
