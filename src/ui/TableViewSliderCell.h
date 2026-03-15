// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
  SliderCellStepperTag,
  SliderCellSliderTag,
};


// -----------------------------------------------------------------------------
/// @brief The TableViewSliderCell class implements a custom table view cell
/// that uses a UISlider to change an integer value. The cell optionally
/// displays the integer value, and a UIStepper as a secondary control to change
/// the integer value (useful for fine-grained control).
///
/// TableViewSliderCell adds its UI elements as subview to its content view and
/// arranges them according to the following schema:
///
/// @verbatim
/// +-------------------------------------------------------------------------+
/// |                                                                         |
/// |  +--------------------------------+  +-----------------+ +-----------+  |
/// |  | UILabel (descriptive text)     |  | UILabel (value) | | UIStepper |  |
/// |  +--------------------------------+  +-----------------+ +-----------+  |
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
/// - If the stepper is shown then the value label must also be shown.
/// - TableViewSliderCell was not designed to be used in editing mode
/// - TableViewSliderCell is not tested in table views that do not have grouped
///   style
// -----------------------------------------------------------------------------
@interface TableViewSliderCell : UITableViewCell
{
}

+ (TableViewSliderCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
                                valueLabelHidden:(bool)valueLabelHidden
                                   stepperHidden:(bool)stepperHidden;

- (void) setValue:(int)value minimumValue:(float)minimumValue maximumValue:(float)maximumValue;
- (void) setDelegate:(id)delegate actionValueDidChange:(SEL)action valueFormatter:(SEL)valueFormatter;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UILabel* valueLabel;
@property(nonatomic, retain, readonly) UIStepper* stepper;
@property(nonatomic, retain, readonly) UISlider* slider;
@property(nonatomic, assign) int value;
@property(nonatomic, assign, readonly) bool valueLabelHidden;
@property(nonatomic, assign, readonly) bool stepperHidden;
/// @brief Delegate object that will be informed when the cell's integer
/// value changes and/or when the cell's integer value is rendered.
@property(nonatomic, assign, readonly) id delegate;
/// @brief Is invoked when the cell's integer value changes. Note that this is
/// also invoked when @e value is changed programmatically.
@property(nonatomic, assign, readonly) SEL delegateActionValueDidChange;
/// @brief Is invoked when the cell's integer value is rendered. The selector
/// is invoked with an argument of type @e NSNumber which holds an @e int value,
/// the value being the value of property @e value. The selector is expected to
/// return an @e NSString object that represents the integer value.
///
/// The selector is never invoked if the value label is hidden.
@property(nonatomic, assign, readonly) SEL delegateValueFormatter;

@end
