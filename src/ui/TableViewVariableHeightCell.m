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
#import "AutoLayoutUtility.h"
#import "UIColorAdditions.h"
#import "../utility/UIDeviceAdditions.h"


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
/// @brief True if TableViewVariableHeightCell should layout its content view
/// using layout guides. Layout guides were introduced in iOS 9.
///
/// TODO: Remove this flag when we drop iOS 8 support.
@property(nonatomic, assign) bool layoutWithLayoutGuides;
// Only used if layouting is done without layout guides
@property(nonatomic, assign) CGFloat leftEdgeSpacing;
// Only used if layouting is done without layout guides
@property(nonatomic, assign) NSLayoutConstraint* rightEdgeSpacingConstraint;
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
  self.layoutWithLayoutGuides = ([UIDevice systemVersionMajor] >= 9);
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
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content view with subviews for all UI elements in this
/// cell.
// -----------------------------------------------------------------------------
- (void) setupContentView
{
  self.descriptionLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  [self.contentView addSubview:self.descriptionLabel];
  self.descriptionLabel.numberOfLines = 0;
  self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;

  self.valueLabel = [[[UILabel alloc] initWithFrame:self.contentView.bounds] autorelease];
  [self.contentView addSubview:self.valueLabel];
  self.valueLabel.textAlignment = NSTextAlignmentRight;
  self.valueLabel.textColor = [UIColor tableViewCellDetailTextLabelColor];

  [self layoutContentView];
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints of the content view that never
/// change. This is run only once, as part of setting up the content view.
// -----------------------------------------------------------------------------
- (void) layoutContentView
{
  self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;

  // This is important! The value label now resists compression more strongly
  // than the description label. If the description label contains a long text
  // the Auto Layout engine will therefore resize the description label's height
  // to make room for the long text. To make this work, the description label's
  // numberOfLines property must also be set 0.
  [self.valueLabel setContentCompressionResistancePriority:(UILayoutPriorityDefaultHigh + 1) forAxis:UILayoutConstraintAxisHorizontal];

  if (self.layoutWithLayoutGuides)
    [self layoutContentViewWithLayoutGuides];
  else
    [self layoutContentViewWithoutLayoutGuides];
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints of the content view that never
/// change, using layout guides introduced in iOS 9. This is run only once, as
/// part of setting up the content view.
// -----------------------------------------------------------------------------
- (void) layoutContentViewWithLayoutGuides
{
  CGFloat verticalSpacingTableViewCell = [AutoLayoutUtility verticalSpacingTableViewCell];

  // Take the anchors from the readable content guide, not from the content
  // itself. The readable content guide takes visible effect on the iPad in
  // landscape orientation, severely constraining the available width.
  [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.leadingAnchor].active = YES;
  [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.contentView.readableContentGuide.trailingAnchor].active = YES;

  [self.valueLabel.leadingAnchor constraintEqualToAnchor:self.descriptionLabel.trailingAnchor].active = YES;

  [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:verticalSpacingTableViewCell].active = YES;
  [self.descriptionLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-verticalSpacingTableViewCell].active = YES;
  [self.valueLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:verticalSpacingTableViewCell].active = YES;
  [self.valueLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-verticalSpacingTableViewCell].active = YES;
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints of the content view that never
/// change, using "traditional" Auto Layout mechanisms instead of layout guides
/// which were introduced in iOS 9. This is run only once, as part of setting
/// up the content view.
// -----------------------------------------------------------------------------
- (void) layoutContentViewWithoutLayoutGuides
{
  CGFloat horizontalSpacingTableViewCell = [AutoLayoutUtility horizontalSpacingTableViewCell];
  CGFloat verticalSpacingTableViewCell = [AutoLayoutUtility verticalSpacingTableViewCell];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.descriptionLabel, @"descriptionLabel",
                                   self.valueLabel, @"valueLabel",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:|-%f-[descriptionLabel]-0-[valueLabel]", horizontalSpacingTableViewCell],
                            [NSString stringWithFormat:@"V:|-%f-[descriptionLabel]-%f-|", verticalSpacingTableViewCell, verticalSpacingTableViewCell],
                            [NSString stringWithFormat:@"V:|-%f-[valueLabel]-%f-|", verticalSpacingTableViewCell, verticalSpacingTableViewCell],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.contentView];

  self.leftEdgeSpacing = [AutoLayoutUtility horizontalSpacingTableViewCell];
  // Later on in layoutSubviews() we may need to change the right edge spacing,
  // so we need access to the NSLayoutConstraint object.
  NSArray* rightEdgeSpacingConstraints = [AutoLayoutUtility installVisualFormats:[NSArray arrayWithObject:@"H:[valueLabel]-0-|"]
                                                                       withViews:viewsDictionary
                                                                          inView:self.contentView];
  self.rightEdgeSpacingConstraint = [rightEdgeSpacingConstraints firstObject];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  if (self.layoutWithLayoutGuides)
  {
    // Nothing to do, the static Auto Layout constraints are sufficient
  }
  else
  {
    // If there is no accessory view we have to provide our own spacing at the
    // right edge
    if (self.accessoryType == UITableViewCellAccessoryNone)
      self.rightEdgeSpacingConstraint.constant = self.leftEdgeSpacing;
    else
      self.rightEdgeSpacingConstraint.constant = 0;
  }

  [super layoutSubviews];
}

@end
