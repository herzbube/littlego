// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates tags of subviews of TableViewDatePickerCell.
// -----------------------------------------------------------------------------
enum DatePickerCellSubViewTag
{
  DatePickerCellDescriptionLabelTag = 1,  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
  DatePickerCellDatePickerTag,
};


// -----------------------------------------------------------------------------
/// @brief The TableViewDatePickerCell class implements a custom table view cell
/// that uses a UIDatePicker to select a date value.
///
/// TableViewDatePickerCell adds its UI elements as subview to its content view
/// and arranges them according to the following schema:
///
/// @verbatim
/// +-------------------------------------------------------------------------+
/// |                                                                         |
/// |  +----------------------------------------------+  +-----------------+  |
/// |  | UILabel (descriptive text)                   |  | UIDatePicker    |  |
/// |  +----------------------------------------------+  +-----------------+  |
/// |                                                                         |
/// +-------------------------------------------------------------------------+
/// @endverbatim
///
/// Notes and constraints:
/// - Use the UIDatePacker property @e date to directly set or get the NSDate
///   value
/// - Use the setDateComponents:() method to set the date picker's value using
///   an NSDateComponents object.
/// - Each UI element has its view tag set to a value from the
///   #DatePickerCellSubViewTag enum
/// - TableViewDatePickerCell explicitly uses UIDatePickerStyleCompact instead
///   of keeping the default UIDatePickerStyleAutomatic, because the cell layout
///   requires a short representation of the date. If TableViewDatePickerCell
///   would keep UIDatePickerStyleAutomatic, the API documentation implies that
///   on certain platforms a style that is not UIDatePickerStyleCompact might
///   be used. In particular, UIDatePickerStyleWheels would break the cell
///   layout.
/// - At the time of writing, UIKit does not allow the combination of
///   UIDatePickerStyleCompact and UIDatePickerModeYearAndMonth - in fact
///   UIDatePickerModeYearAndMonth @e requires UIDatePickerStyleWheels! For
///   this reason, TableViewDatePickerCell can currently only be used to pick a
///   full date (i.e. days, month and year).
/// - The UIDatePicker control's behaviour can be influenced by directly setting
///   its properties (e.g. minimum and/or maximum value).
/// - TableViewDatePickerCell explicitly configures the date picker to use the
///   Gregorian calendar. To use a different calendar, set the UIDatePicker
///   property @e calendar with a different NSCalendar object.
/// - TableViewDatePickerCell was not designed to be used in editing mode
/// - TableViewDatePickerCell is not tested in table views that do not have
///   grouped style
// -----------------------------------------------------------------------------
@interface TableViewDatePickerCell : UITableViewCell
{
}

+ (TableViewDatePickerCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier;

- (void) setDelegate:(id)delegate actionValueDidChange:(SEL)action;

@property(nonatomic, retain, readonly) UILabel* descriptionLabel;
@property(nonatomic, retain, readonly) UIDatePicker* datePicker;
/// @brief Delegate object that will be informed when the cell's date value
/// changes and/or when the cell's date value is rendered.
@property(nonatomic, assign, readonly) id delegate;
/// @brief Is invoked when the cell's date value changes. Note that
/// this is also invoked when the date picker's @e date property is changed
/// programmatically. The invoked method is expected to take a single parameter
/// that is this TableViewDatePickerCell object.
@property(nonatomic, assign, readonly) SEL delegateActionValueDidChange;
/// @brief Gets or sets the cell's date value in the form of a NSDateComponents
/// object. When setting the property the NSDateComponents object must have
/// non-zero values for the @e day, @e month and @e year properties.
@property(nonatomic, assign) NSDateComponents* dateComponents;

@end
