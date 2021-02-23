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


// Project includes
#import "TableViewVariableHeightCell.h"
#import "UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// TableViewVariableHeightCell.
// -----------------------------------------------------------------------------
@interface TableViewVariableHeightCell()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) UILabel* descriptionLabel;
@property(nonatomic, retain, readwrite) UILabel* valueLabel;
//@}
/// @brief The stack view that does the layouting heavy lifting for us.
@property(nonatomic, retain) UIStackView* stackView;
/// @brief The Auto Layout constraint that controls the width of the description
/// labels. Is not used if the ratio is 0.5.
@property(nonatomic, retain) NSLayoutConstraint* descriptionLabelWidthConstraint;
/// @brief The Auto Layout constraint that controls the width of the value
/// labels. Is not used if the ratio is 0.5.
@property(nonatomic, retain) NSLayoutConstraint* valueLabelWidthConstraint;
@end

@implementation TableViewVariableHeightCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewVariableHeightCell
/// instance with reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewVariableHeightCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewVariableHeightCell* cell = [[TableViewVariableHeightCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewVariableHeightCell object with reuse
/// identifier @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewVariableHeightCell.
// -----------------------------------------------------------------------------
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleValue1
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;

  self.descriptionLabelWidthConstraint = nil;
  self.valueLabelWidthConstraint = nil;
  _descriptionLabelWidthPercentage = 0.5;

  [self setupContentView];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.descriptionLabel = nil;
  self.valueLabel = nil;
  self.stackView = nil;
  self.descriptionLabelWidthConstraint = nil;
  self.valueLabelWidthConstraint = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:CGRectNull] autorelease];
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;

  self.valueLabel = [[[UILabel alloc] initWithFrame:CGRectNull] autorelease];
  self.valueLabel.numberOfLines = 0;
  self.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.textColor = [UIColor tableViewCellDetailTextLabelColor];

  self.stackView = [[[UIStackView alloc] initWithArrangedSubviews:[NSArray arrayWithObjects:self.descriptionLabel, self.valueLabel, nil]] autorelease];
  [self.contentView addSubview:self.stackView];
  self.stackView.axis = UILayoutConstraintAxisHorizontal;
  self.stackView.spacing = 0.0f;

  [self layoutContentView];
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints of the content view that never
/// change. This is run only once, as part of setting up the content view.
// -----------------------------------------------------------------------------
- (void) layoutContentView
{
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.leadingAnchor].active = YES;
  [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.trailingAnchor].active = YES;
  [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
  [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDescriptionLabelWidthPercentage:(CGFloat)descriptionLabelWidthPercentage
{
  if (descriptionLabelWidthPercentage < 0.0 || descriptionLabelWidthPercentage > 1.0)
  {
    assert(0);
    NSString* errorMessage = [NSString stringWithFormat:@"descriptionLabelWidthPercentage set with illegal value %.1f", descriptionLabelWidthPercentage];
    DDLogError(@"%@", errorMessage);
    @throw [NSException exceptionWithName:NSInvalidArgumentException reason:errorMessage userInfo:nil];
  }

  if (_descriptionLabelWidthPercentage == descriptionLabelWidthPercentage)
    return;
  _descriptionLabelWidthPercentage = descriptionLabelWidthPercentage;

  if (self.descriptionLabelWidthConstraint)
  {
    [self.stackView removeConstraint:self.descriptionLabelWidthConstraint];
    self.descriptionLabelWidthConstraint = nil;
  }

  if (self.valueLabelWidthConstraint)
  {
    [self.stackView removeConstraint:self.valueLabelWidthConstraint];
    self.valueLabelWidthConstraint = nil;
  }

  if (_descriptionLabelWidthPercentage != 0.5)
  {
    self.descriptionLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.descriptionLabel
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.stackView
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:_descriptionLabelWidthPercentage
                                                                         constant:0.0];
    [self.stackView addConstraint:self.descriptionLabelWidthConstraint];
    self.valueLabelWidthConstraint = [NSLayoutConstraint constraintWithItem:self.valueLabel
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.stackView
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1.0 - _descriptionLabelWidthPercentage
                                                                   constant:0.0];
    [self.stackView addConstraint:self.valueLabelWidthConstraint];
  }
}

@end
