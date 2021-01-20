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
/// @brief The Auto Layout constraint that controls the width ratio between the
/// two labels. Is not used if the ratio is 1.0.
@property(nonatomic, retain) NSLayoutConstraint* widthRatioConstraint;
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

  self.widthRatioConstraint = nil;
  _widthRatio = 1.0;

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
  self.widthRatioConstraint = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;

  self.valueLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  self.valueLabel.numberOfLines = 0;
  self.valueLabel.lineBreakMode = NSLineBreakByWordWrapping;
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.textColor = [UIColor tableViewCellDetailTextLabelColor];

  self.stackView = [[UIStackView alloc] initWithArrangedSubviews:[NSArray arrayWithObjects:self.descriptionLabel, self.valueLabel, nil]];
  [self.contentView addSubview:self.stackView];
  self.stackView.axis = UILayoutConstraintAxisHorizontal;
  self.stackView.spacing = 0.0f;
  self.stackView.distribution = UIStackViewDistributionFillProportionally;

  [self layoutContentView];
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints of the content view that never
/// change. This is run only once, as part of setting up the content view.
// -----------------------------------------------------------------------------
- (void) layoutContentView
{
  self.stackView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.stackView.leadingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.leadingAnchor].active = YES;
  [self.stackView.trailingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.trailingAnchor].active = YES;
  [self.stackView.topAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.topAnchor].active = YES;
  [self.stackView.bottomAnchor constraintEqualToAnchor:self.contentView.layoutMarginsGuide.bottomAnchor].active = YES;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setWidthRatio:(CGFloat)widthRatio
{
  if (_widthRatio == widthRatio)
    return;
  _widthRatio = widthRatio;

  if (self.widthRatioConstraint)
    [self.stackView removeConstraint:self.widthRatioConstraint];

  if (_widthRatio != 1.0)
  {
    self.widthRatioConstraint = [NSLayoutConstraint constraintWithItem:self.valueLabel
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.descriptionLabel
                                                             attribute:NSLayoutAttributeWidth
                                                            multiplier:_widthRatio
                                                              constant:0.0];
    [self.stackView addConstraint:self.widthRatioConstraint];
  }
}

@end
