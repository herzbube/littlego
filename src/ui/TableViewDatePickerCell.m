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


// Project includes
#import "TableViewDatePickerCell.h"
#import "AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TableViewDatePickerCell.
// -----------------------------------------------------------------------------
@interface TableViewDatePickerCell()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* descriptionLabel;
@property(nonatomic, retain, readwrite) UIDatePicker* datePicker;
@property(nonatomic, assign, readwrite) id delegate;
@property(nonatomic, assign, readwrite) SEL delegateActionValueDidChange;
//@}
@property(nonatomic, retain) UIStackView* stackView;
@end


@implementation TableViewDatePickerCell

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewDatePickerCell instance
/// with reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewDatePickerCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewDatePickerCell* cell = [[TableViewDatePickerCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewDatePickerCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewDatePickerCell.
// -----------------------------------------------------------------------------
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;

  [self setupCell];
  [self setupContentView];
  self.delegate = nil;
  self.delegateActionValueDidChange = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TableViewDatePickerCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.descriptionLabel = nil;
  self.datePicker = nil;
  self.stackView = nil;
  self.delegate = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up cell attributes that are not related to the content view.
// -----------------------------------------------------------------------------
- (void) setupCell
{
  // The cell should never appear selected, instead we want the slider
  // to be the active element
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  [self setupDescriptionLabel];
  [self setupDatePicker];
  [self setupStackView];

  [self.contentView addSubview:self.stackView];

  [self setupAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupDescriptionLabel
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectNull] autorelease];
  self.descriptionLabel.tag = DatePickerCellDescriptionLabelTag;
  self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
  self.descriptionLabel.backgroundColor = [UIColor clearColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupDatePicker
{
  self.datePicker = [[[UIDatePicker alloc] initWithFrame:CGRectNull] autorelease];
  self.datePicker.tag = DatePickerCellDatePickerTag;
  self.datePicker.datePickerMode = UIDatePickerModeDate;
  self.datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
  self.datePicker.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
  [self.datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupStackView
{
  self.stackView = [[[UIStackView alloc] initWithArrangedSubviews:@[self.descriptionLabel, self.datePicker]] autorelease];
  self.stackView.axis = UILayoutConstraintAxisHorizontal;
  self.stackView.spacing = [AutoLayoutUtility horizontalSpacingSiblings];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupContentView
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
  [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
  [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
  [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
}

// -----------------------------------------------------------------------------
/// @brief Notifies the delegate that the date picker has changed its value.
// -----------------------------------------------------------------------------
- (void) datePickerValueChanged:(UIDatePicker*)sender
{
  if (self.delegate && self.delegateActionValueDidChange)
  {
    if ([self.delegate respondsToSelector:self.delegateActionValueDidChange])
      [self.delegate performSelector:self.delegateActionValueDidChange withObject:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures this cell with @a delegate and the selector for the method
/// to invoke when the cell's date value changes.
// -----------------------------------------------------------------------------
- (void) setDelegate:(id)delegate actionValueDidChange:(SEL)action
{
  self.delegate = delegate;
  self.delegateActionValueDidChange = action;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (NSDateComponents*) dateComponents
{
  NSCalendarUnit componentFlags = (NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear);
  NSDateComponents* dateComponents = [self.datePicker.calendar components:componentFlags
                                                      fromDate:self.datePicker.date];
  return dateComponents;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDateComponents:(NSDateComponents*)dateComponents
{
  self.datePicker.date = [self.datePicker.calendar dateFromComponents:dateComponents];
}

@end
