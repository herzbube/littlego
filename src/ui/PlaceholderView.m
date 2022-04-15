// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlaceholderView.h"
#import "../shared/LayoutManager.h"
#import "../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlaceholderView.
// -----------------------------------------------------------------------------
@interface PlaceholderView()
@property(nonatomic, assign, readwrite) enum PlaceholderViewStyle placeholderViewStyle;
@property(nonatomic, retain) UIView* twoThirdsView;
@property(nonatomic, retain, readwrite) UILabel* placeholderLabel;
@end


@implementation PlaceholderView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an PlaceholderView object that displays the specified
/// text @a placeholderText. The PlaceholderView lays out its content using
/// @e PlaceholderViewStyleThirds.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect placeholderText:(NSString*)placeholderText
{
  return [self initWithFrame:rect placeholderText:placeholderText style:PlaceholderViewStyleThirds];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an PlaceholderView object that displays the specified
/// text @a placeholderText. The PlaceholderView lays out its content according
/// to @a placeholderViewStyle.
///
/// @note This is the designated initializer of PlaceholderView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect placeholderText:(NSString*)placeholderText style:(enum PlaceholderViewStyle)placeholderViewStyle
{
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.placeholderViewStyle = placeholderViewStyle;
  
  [self setupViewHierarchy];
  [self configurePlaceholderLabel];
  [self setupAutoLayoutConstraints];

  self.placeholderLabel.text = placeholderText;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlaceholderView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.twoThirdsView = nil;
  self.placeholderLabel = nil;
  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  if (self.placeholderViewStyle == PlaceholderViewStyleThirds)
  {
    self.twoThirdsView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
    [self addSubview:self.twoThirdsView];

    self.placeholderLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [self.twoThirdsView addSubview:self.placeholderLabel];
  }
  else
  {
    self.placeholderLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
    [self addSubview:self.placeholderLabel];
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures the placehholder label.
// -----------------------------------------------------------------------------
- (void) configurePlaceholderLabel
{
  // The following font size factors have been experimentally determined, i.e.
  // what looks good on a simulator
  CGFloat fontSizeFactor;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    fontSizeFactor = 1.5;
  else
    fontSizeFactor = 2.0;

  self.placeholderLabel.font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize] * fontSizeFactor];
  self.placeholderLabel.textAlignment = NSTextAlignmentCenter;
  self.placeholderLabel.numberOfLines = 0;
}

// -----------------------------------------------------------------------------
/// @brief Sets up Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  if (self.placeholderViewStyle == PlaceholderViewStyleThirds)
    [self setupAutoLayoutConstraintsThirds];
  else
    [self setupAutoLayoutConstraintsCenter];
}

// -----------------------------------------------------------------------------
/// @brief Helper method for setupAutoLayoutConstraints().
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsThirds
{
  self.twoThirdsView.translatesAutoresizingMaskIntoConstraints = NO;
  self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;

  // Give the twoThirdsView 2/3 of the height of the entire placeholder view
  NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.twoThirdsView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeHeight
                                                               multiplier:2.0f/3.0f
                                                                 constant:0.0f];
  [self addConstraint:constraint];
  // By anchoring twoThirdsView at the bottom of the placeholder view it extends
  // upwards so that its top is below the 1/3 mark
  [self.bottomAnchor constraintEqualToAnchor:self.twoThirdsView.bottomAnchor].active = YES;
  [self.layoutMarginsGuide.leftAnchor constraintEqualToAnchor:self.twoThirdsView.leftAnchor].active = YES;
  [self.layoutMarginsGuide.rightAnchor constraintEqualToAnchor:self.twoThirdsView.rightAnchor].active = YES;

  // Anchor the label at the top, but don't give it any height. If the label has
  // a non-intrinsic height its text is vertically centered. We don't want this,
  // we want the text to be at the top of twoThirdsView.
  [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.twoThirdsView.topAnchor].active = YES;
  [self.placeholderLabel.leftAnchor constraintEqualToAnchor:self.twoThirdsView.leftAnchor].active = YES;
  [self.placeholderLabel.rightAnchor constraintEqualToAnchor:self.twoThirdsView.rightAnchor].active = YES;
}

// -----------------------------------------------------------------------------
/// @brief Helper method for setupAutoLayoutConstraints().
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsCenter
{
  self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;

  [self.layoutMarginsGuide.leftAnchor constraintEqualToAnchor:self.placeholderLabel.leftAnchor].active = YES;
  [self.layoutMarginsGuide.rightAnchor constraintEqualToAnchor:self.placeholderLabel.rightAnchor].active = YES;
  [self.centerYAnchor constraintEqualToAnchor:self.placeholderLabel.centerYAnchor].active = YES;
}

@end
