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


// Project includes
#import "TableViewTextCell.h"
#import "UIColorAdditions.h"
#import "UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TableViewTextCell.
// -----------------------------------------------------------------------------
@interface TableViewTextCell()
/// @name Initialization and deallocation
//@{
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;
- (void) dealloc;
- (void) setupCell;
- (void) setupContentView;
//@}
/// @name Overrides from superclass
//@{
- (void) layoutSubviews;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* label;
@property(nonatomic, retain, readwrite) UITextField* textField;
//@}
@end


@implementation TableViewTextCell

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewTextCell instance with
/// reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewTextCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewTextCell* cell = [[TableViewTextCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewTextCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewTextCell.
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

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TableViewTextCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.label = nil;
  self.textField = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up cell attributes that are not related to the content view.
// -----------------------------------------------------------------------------
- (void) setupCell
{
  // The cell should never appear selected, instead we want the text field
  // to be the active element
  self.selectionStyle = UITableViewCellSelectionStyleNone;
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.label = [[UILabel alloc] initWithFrame:CGRectNull];
  [self.contentView addSubview:self.label];
  self.label.tag = TextCellLabelTag;
  self.label.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
  self.label.textAlignment = UITextAlignmentLeft;
  self.label.textColor = [UIColor blackColor];
  self.label.backgroundColor = [UIColor clearColor];
  self.label.hidden = YES;

  self.textField = [[UITextField alloc] initWithFrame:CGRectNull];
  [self.contentView addSubview:self.textField];
  self.textField.tag = TextCellTextFieldTag;
  self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  self.textField.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
  self.textField.textColor = [UIColor slateBlueColor];
  self.textField.clearButtonMode = UITextFieldViewModeWhileEditing;
  // Properties from the UITextInputTraits protocol
  self.textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
  self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
  self.textField.enablesReturnKeyAutomatically = YES;
}

// -----------------------------------------------------------------------------
/// @brief Determine frames of all UI elements in this cell.
///
/// This overrides the superclass implementation. We need this because the
/// label text, which is not known at the time when the cell is constructed,
/// influences how much space the label and text field get.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  // Start with the assumption that the text field is going to get the entire
  // cell for itself
  CGRect textFieldFrame = self.contentView.bounds;
  textFieldFrame = CGRectInset(textFieldFrame,
                               [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal],
                               [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical]);
  if (nil == self.label.text || 0 == self.label.text.length)
  {
    self.label.hidden = YES;
    self.textField.frame = textFieldFrame;
  }
  else
  {
    // Arbitrary value that at least allows the user to tap the field so that
    // she can edit text in place
    static const int textFieldMinimumWidth = 50;
    int maximumLabelWidth = (textFieldFrame.size.width
                                        - [UiElementMetrics spacingHorizontal]
                                        - textFieldMinimumWidth);
    CGSize constraintSize = CGSizeMake(maximumLabelWidth, MAXFLOAT);
    CGSize labelTextSize = [self.label.text sizeWithFont:self.label.font
                                       constrainedToSize:constraintSize
                                           lineBreakMode:UILineBreakModeWordWrap];
    int labelWidth = labelTextSize.width;
    if (labelWidth > maximumLabelWidth)
      labelWidth = maximumLabelWidth;
    CGRect labelFrame = textFieldFrame;
    labelFrame.size.width = labelWidth;
    self.label.hidden = NO;
    self.label.frame = labelFrame;

    int subtractFromTextFieldWidth = labelWidth + [UiElementMetrics spacingHorizontal];
    textFieldFrame.size.width -= subtractFromTextFieldWidth;
    textFieldFrame.origin.x += subtractFromTextFieldWidth;
    self.textField.frame = textFieldFrame;
  }
}

@end
