// -----------------------------------------------------------------------------
// Copyright 2015-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionCollectionViewCell.h"
#import "../model/NodeTreeViewModel.h"
#import "../nodetreeview/canvas/NodeTreeViewCanvasDataProvider.h"
#import "../nodetreeview/layer/NodeTreeViewDrawingHelper.h"
#import "../nodetreeview/NodeTreeViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/AccessibilityUtility.h"
#import "../../utility/MarkupUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


enum BoardPositionCollectionViewCellType
{
  BoardPositionCollectionViewCellTypePositionZero,
  BoardPositionCollectionViewCellTypePositionNonZero
};

/// @brief A private implementation of the NodeTreeViewCanvasDataProvider
/// protocol that provides data for a zero-size canvas. Used for drawing the
/// node symbol images.
@interface PrivateNodeTreeViewCanvasDataProvider : NSObject <NodeTreeViewCanvasDataProvider>
{
}
@end

@implementation PrivateNodeTreeViewCanvasDataProvider
- (CGSize) canvasSize
{
  return CGSizeZero;
}

- (GoNode*) nodeAtPosition:(NodeTreeViewCellPosition*)position
{
  return nil;
}
@end

// ----------------------------------------
// Cell sizes
// ----------------------------------------
// This variable must be accessed via [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionZero]
static CGSize boardPositionCollectionViewCellSizePositionZero = { 0.0f, 0.0f };
// This variable must be accessed via [BoardPositionCollectionViewCell boardPositionCollectionViewCellSizePositionNonZero]
static CGSize boardPositionCollectionViewCellSizePositionNonZero = { 0.0f, 0.0f };

// ----------------------------------------
// Margins towards the superview edges
// ----------------------------------------
// 4 is not enough => the subviews are too close to the left/right cell edges
// - if horizontalSpacingSiblings == 4 => 6 is good
// - if horizontalSpacingSiblings == 8 => 8 is good
static int horizontalMargin = 8;
// 4 is stingy, but still OK
// 8 is generous, also ok but not needed
// 6 is a good middle ground => tested with horizontalMargin = 6 and 8
static int verticalMargin = 6;

// ----------------------------------------
// Spacings between siblings
// ----------------------------------------
// 4 is not enough, the labels are too close to the node symbol and the icon
//                  images are also too close to each other
// 6 is stingy
// 8 is generous and also looks good
static int horizontalSpacingSiblings = 8;
// if horizontalSpacingSiblings == 4
// - 0 is very tight for the labels but OK - but it's not enough for the icons
//                   the icons are then too close to each other vertically
// - 2 is ok for the labels and a bit stingy for the icons
// - 4 is too much for the labels and OK for the icons
// if horizontalSpacingSiblings == 8
// - 4 is good
static int verticalSpacingLabels = 4;
// 4 is not enough => the icons sit too close on top of each other
// 8 is too much => the icons are too close to the top/bottom cell edges
// 6 is a good middle ground
static int verticalSpacingIconImageViews = 6;

// ----------------------------------------
// Fonts
// ----------------------------------------
// Cell height 42, Margin/Spacing 8: 14 allows 2 lines, 15+ allows only 1 line
// Cell height 42, Margin/Spacing 4: 17 allows 2 lines, 18+ allows only 1 line
// Cell height 50, vertical margin 6 / vertical spacing labels 4: 15 allows 2 lines, 16+ allows only 1 line
// Cell height 53, vertical margin 6 / vertical spacing labels 4: 17 allows 2 lines, 18+ allows only 1 line
static CGFloat largeFontSize = 17.0f;
static CGFloat smallFontSize = 11.0f;

// ----------------------------------------
// Image dimensions
// ----------------------------------------
// 40 takes advantage of the cell height that results from the values above.
// A bit more would be possible, but this would make the cell even wider than
// it currently is.
static CGFloat nodeSymbolImageDimension = 40.0f;
// 13 is a good value to fill out the cell height that results from the values
// above, when there are two rows of icons.
static CGFloat iconImageDimension = 13.0f;

// ----------------------------------------
// Objects
// ----------------------------------------
static NSMutableDictionary* nodeSymbolImages = nil;
static UIImage* infoIconImage = nil;
static UIImage* hotspotIconImage = nil;
static UIImage* markupIconImage = nil;
static UIColor* currentBoardPositionCellBackgroundColor = nil;
static UIColor* alternateCellBackgroundColor1 = nil;
static UIColor* alternateCellBackgroundColor2 = nil;
static UIColor* alternateCellBackgroundColor1DarkMode = nil;
static UIColor* alternateCellBackgroundColor2DarkMode = nil;
static UIColor* capturedStonesLabelTextColor = nil;
static UIFont* largeFont = nil;
static UIFont* smallFont = nil;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionCollectionViewCell.
// -----------------------------------------------------------------------------
@interface BoardPositionCollectionViewCell()
@property(nonatomic, assign) bool offscreenMode;
@property(nonatomic, assign) bool didLayoutSubviewsBefore;
@property(nonatomic, assign) UIImageView* nodeSymbolImageView;
@property(nonatomic, assign) UILabel* textLabel;
@property(nonatomic, assign) UILabel* detailTextLabel;
@property(nonatomic, assign) UILabel* capturedStonesLabel;
@property(nonatomic, assign) UIImageView* infoIconImageView;
@property(nonatomic, assign) UIImageView* hotspotIconImageView;
@property(nonatomic, assign) UIImageView* markupIconImageView;
@property (nonatomic, retain) NSLayoutConstraint* detailTextLabelYPositionConstraint;
@property (nonatomic, retain) NSLayoutConstraint* detailTextLabelZeroHeightConstraint;
@property (nonatomic, retain) NSLayoutConstraint* infoIconImageViewLeftEdgeConstraint;
@property (nonatomic, retain) NSLayoutConstraint* infoIconImageViewWidthConstraint;
@property (nonatomic, retain) NSLayoutConstraint* hotspotIconImageViewWidthConstraint;
@property (nonatomic, retain) NSLayoutConstraint* markupIconImageViewLeftEdgeConstraint;
@property (nonatomic, retain) NSLayoutConstraint* markupIconImageViewWidthConstraint;
@property (nonatomic, retain) NSLayoutConstraint* infoIconImageViewYPositionConstraint;
@property (nonatomic, retain) NSLayoutConstraint* hotspotIconImageViewYPositionConstraint;
@property (nonatomic, retain) NSLayoutConstraint* markupIconImageViewYPositionConstraint;
@end


@implementation BoardPositionCollectionViewCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionCollectionViewCell object with frame
/// @a rect.
///
/// @note This is the designated initializer of BoardPositionCollectionViewCell.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UICollectionViewCell)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.offscreenMode = false;
  self.didLayoutSubviewsBefore = false;

  // Don't use self, we don't want to trigger the setter
  _boardPosition = -1;

  [self setupViewHierarchy];
  [self configureView];

  // No content to setup, we first need a board position
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionCollectionViewCell object that is never
/// rendered on screen.
///
/// @note This initializer is privately used for the one-time pre-calculation
/// of the BoardPositionCollectionViewCell size. The calculated size depends on
/// @a cellType.
// -----------------------------------------------------------------------------
- (id) initOffscreenViewWithCellType:(enum BoardPositionCollectionViewCellType)cellType
{
  // The frame for the off-screen view can be pretty much any size, the view
  // will be resized by setupStaticViewMetrics to UILayoutFittingCompressedSize
  // anyway. There is one restriction though: The frame must be large enough to
  // accomodate all spacings set up by setupAutoLayoutConstraints(). If the
  // frame is not large enough (e.g. CGRectZero) Auto Layout will print a
  // warning to the debug console, but continue by breaking one of the
  // constraints.
  CGRect frame = CGRectMake(0, 0, 100, 100);

  // Call designated initializer of superclass (UICollectionViewCell)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;

  self.offscreenMode = true;
  self.didLayoutSubviewsBefore = false;

  // Don't use self, we don't want to trigger the setter
  if (cellType == BoardPositionCollectionViewCellTypePositionZero)
    _boardPosition = 0;
  else
    _boardPosition = 1;

  [self setupViewHierarchy];
  // Setup content first because dynamic Auto Layout constraint calculation
  // examines the content
  [self setupDummyContent];
  [self configureView];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionCollectionViewCell
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeSymbolImageView = nil;
  self.textLabel = nil;
  self.detailTextLabel = nil;
  self.capturedStonesLabel = nil;
  self.infoIconImageView = nil;
  self.hotspotIconImageView = nil;
  self.markupIconImageView = nil;
  self.detailTextLabelYPositionConstraint = nil;
  self.detailTextLabelZeroHeightConstraint = nil;
  self.infoIconImageViewLeftEdgeConstraint = nil;
  self.infoIconImageViewWidthConstraint = nil;
  self.hotspotIconImageViewWidthConstraint = nil;
  self.markupIconImageViewLeftEdgeConstraint = nil;
  self.markupIconImageViewWidthConstraint = nil;
  self.infoIconImageViewYPositionConstraint = nil;
  self.hotspotIconImageViewYPositionConstraint = nil;
  self.markupIconImageViewYPositionConstraint = nil;

  [super dealloc];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  if (! self.didLayoutSubviewsBefore)
  {
    self.didLayoutSubviewsBefore = true;

    [self setupStaticAutoLayoutConstraints];
  }

  [self updateDynamicAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection*)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    {
      // traitCollectionDidChange sometimes is invoked when a cell is reused
      // before the boardPosition property value was updated. If that is the
      // case then we don't get a GoNode object => there's no point in updating
      // the colors, so we skip it and let setupRealContent do it later when the
      // boardPosition property is updated.
      GoNode* node = [self nodeWithDataOrNil];
      if (node)
        [self updateColors:node];
    }
  }
}

#pragma mark - One-time view setup

// -----------------------------------------------------------------------------
/// @brief Creates the views and sets up the view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.nodeSymbolImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.textLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.detailTextLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.capturedStonesLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.infoIconImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.hotspotIconImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.markupIconImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];

  [self addSubview:self.nodeSymbolImageView];
  [self addSubview:self.textLabel];
  [self addSubview:self.detailTextLabel];
  [self addSubview:self.capturedStonesLabel];
  [self addSubview:self.infoIconImageView];
  [self addSubview:self.hotspotIconImageView];
  [self addSubview:self.markupIconImageView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) configureView
{
  self.selectedBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.selectedBackgroundView.backgroundColor = currentBoardPositionCellBackgroundColor;

  self.textLabel.font = largeFont;
  self.detailTextLabel.font = smallFont;
  self.capturedStonesLabel.font = smallFont;

  self.capturedStonesLabel.textColor = capturedStonesLabelTextColor;

  // Setting identifiers is extremely helpful when debugging auto layout issues.
  // The identifiers are also used by UI tests for identifying UI elements.
  // Note: self.nodeSymbolImageView does not have a static identifier, instead
  // its identifier is assigned dynamically based on the node symbol it
  // displays.
  self.accessibilityIdentifier = boardPositionCollectionViewCellAccessibilityIdentifier;
  self.backgroundView.accessibilityIdentifier = unselectedBackgroundViewBoardPositionAccessibilityIdentifier;
  self.selectedBackgroundView.accessibilityIdentifier = selectedBackgroundViewBoardPositionAccessibilityIdentifier;
  self.textLabel.accessibilityIdentifier = textLabelBoardPositionAccessibilityIdentifier;
  self.detailTextLabel.accessibilityIdentifier = detailTextLabelBoardPositionAccessibilityIdentifier;
  self.capturedStonesLabel.accessibilityIdentifier = capturedStonesLabelBoardPositionAccessibilityIdentifier;
  self.hotspotIconImageView.accessibilityIdentifier = hotspotIconImageViewBoardPositionAccessibilityIdentifier;
  self.infoIconImageView.accessibilityIdentifier = infoIconImageViewBoardPositionAccessibilityIdentifier;
  self.markupIconImageView.accessibilityIdentifier = markupIconImageViewBoardPositionAccessibilityIdentifier;
}

#pragma mark - Content setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the designated initializer and the
/// @e boardPosition property setter.
// -----------------------------------------------------------------------------
- (void) setupRealContent
{
  if (-1 == self.boardPosition)
    return;

  GoGame* game = [GoGame sharedGame];
  GoNode* node = [self nodeWithDataOrNil];

  enum NodeTreeViewCellSymbol nodeSymbol = [GoUtilities symbolForNode:node];
  self.nodeSymbolImageView.image = [self nodeSymbolImageForNodeSymbol:nodeSymbol];

  if (0 == self.boardPosition)
  {
    self.textLabel.text = @"Game start";
    NSString* komiString = [NSString stringWithKomi:game.komi numericZeroValue:true];
    self.detailTextLabel.text = [NSString stringWithFormat:@"H: %1lu, K: %@", (unsigned long)game.handicapPoints.count, komiString];
    self.capturedStonesLabel.text = nil;
    self.infoIconImageView.image = nil;
    self.hotspotIconImageView.image = nil;
    self.markupIconImageView.image = nil;
  }
  else
  {
    if ([self showsMoveData:node])
    {
      GoMove* move = node.goMove;
      self.textLabel.text = [self textLabelTextForMove:move];
      self.detailTextLabel.text = [NSString stringWithFormat:@"Move %d", node.goMove.moveNumber];
      self.capturedStonesLabel.text = [self capturedStonesLabelTextForMove:move];
    }
    else
    {
      if (node.goNodeSetup)
        self.textLabel.text = @"Setup";
      else
        self.textLabel.text = @"Empty";
      self.detailTextLabel.text = nil;
      self.capturedStonesLabel.text = nil;
    }

    if ([self showsInfoIcon:node])
      self.infoIconImageView.image = infoIconImage;
    else
      self.infoIconImageView.image = nil;

    if ([self showsHotspotIcon:node])
      self.hotspotIconImageView.image = hotspotIconImage;
    else
      self.hotspotIconImageView.image = nil;

    if ([self showsMarkupIcon:node])
      self.markupIconImageView.image = markupIconImage;
    else
      self.markupIconImageView.image = nil;
  }

  // Let UI tests distinguish which image is set. Experimentally determined that
  // we can't set the individual UIImage's accessibilityIdentifier property
  // (even though it exists), XCTest never finds any UIImages configured like
  // that. Presumably this is because XCTest only exposes views, and UIImage is
  // not a view - but UIImageView is.
  NSString* accessibilityIdentifier = [AccessibilityUtility accessibilityIdentifierForNodeSymbol:nodeSymbol];
  self.nodeSymbolImageView.accessibilityIdentifier = accessibilityIdentifier;

  [self updateColors:node];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the offscreen initializer.
// -----------------------------------------------------------------------------
- (void) setupDummyContent
{
  // Implementation note: Assign the widest/highest content that can possibly
  // appear.

  if (0 == self.boardPosition)
  {
    self.nodeSymbolImageView.image = nil;
    self.textLabel.text = @"Game start";
    self.detailTextLabel.text = @"H: 99, K: 99½";
    self.capturedStonesLabel.text = nil;
    self.infoIconImageView.image = nil;
    self.hotspotIconImageView.image = nil;
    self.markupIconImageView.image = nil;
  }
  else
  {
    self.nodeSymbolImageView.image = [self nodeSymbolImageForNodeSymbol:NodeTreeViewCellSymbolBlackMove];
    self.textLabel.text = @"Setup";
    self.detailTextLabel.text = @"Move 8888";
    self.capturedStonesLabel.text = @"888";
    self.infoIconImageView.image = infoIconImage;
    self.hotspotIconImageView.image = hotspotIconImage;
    self.markupIconImageView.image = markupIconImage;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (NSString*) textLabelTextForMove:(GoMove*)move
{
  if (GoMoveTypePlay == move.type)
    return move.point.vertex.string;
  else
    return @"Pass";
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (UIImage*) nodeSymbolImageForNodeSymbol:(enum NodeTreeViewCellSymbol)nodeSymbol
{
  NSNumber* nodeSymbolAsNumber = [NSNumber numberWithInt:nodeSymbol];
  UIImage* nodeSymbolImage = nodeSymbolImages[nodeSymbolAsNumber];
  return nodeSymbolImage;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
///
/// @attention Dynamic Auto Layout constraint calculation requires that we
/// return nil if @a move did not capture any stones.
// -----------------------------------------------------------------------------
- (NSString*) capturedStonesLabelTextForMove:(GoMove*)move
{
  if (GoMoveTypePass == move.type)
    return nil;
  NSUInteger numberOfCapturedStones = move.capturedStones.count;
  if (0 == numberOfCapturedStones)
    return nil;
  return [NSString stringWithFormat:@"%lu", (unsigned long)numberOfCapturedStones];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (bool) showsMoveData:(GoNode*)node
{
  if (self.offscreenMode)
    return true;

  if (node.goMove)
    return true;
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (bool) showsInfoIcon:(GoNode*)node
{
  if (self.offscreenMode)
    return true;
  else
    return [GoUtilities showInfoIndicatorForNode:node];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (bool) showsHotspotIcon:(GoNode*)node
{
  if (self.offscreenMode)
    return true;
  else
    return [GoUtilities showHotspotIndicatorForNode:node];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (bool) showsMarkupIcon:(GoNode*)node
{
  if (self.offscreenMode)
    return true;
  else
    return [MarkupUtilities shouldDisplayMarkupIndicatorForNode:node];
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setBoardPosition:(int)newValue
{
  bool newBoardPositionRequiresAutoLayoutConstraintUpdate;
  if (_boardPosition == -1)
  {
    newBoardPositionRequiresAutoLayoutConstraintUpdate = true;
  }
  else
  {
    bool oldPositionIsGreaterThanZero = (_boardPosition > 0);
    bool newPositionIsGreaterThanZero = (newValue > 0);
    newBoardPositionRequiresAutoLayoutConstraintUpdate = (oldPositionIsGreaterThanZero != newPositionIsGreaterThanZero);
  }

  _boardPosition = newValue;

  bool oldPositionShowsMove = (self.nodeSymbolImageView.image != nil);
  bool oldPositionHasCapturedStones = (self.capturedStonesLabel.text != nil);
  bool oldPositionShowsInfoIcon = (self.infoIconImageView.image != nil);
  bool oldPositionShowsHotspotIcon = (self.hotspotIconImageView.image != nil);
  bool oldPositionShowsMarkupIcon = (self.markupIconImageView.image != nil);
  // Setup content first because dynamic Auto Layout constraint calculation
  // examines the content
  [self setupRealContent];
  bool newPositionShowsMove = (self.nodeSymbolImageView.image != nil);
  bool newPositionHasCapturedStones = (self.capturedStonesLabel.text != nil);
  bool newPositionShowsInfoIcon = (self.infoIconImageView.image != nil);
  bool newPositionShowsHotspotIcon = (self.hotspotIconImageView.image != nil);
  bool newPositionShowsMarkupIcon = (self.markupIconImageView.image != nil);

  // Optimization: Change Auto Layout constraints only if absolutely necessary
  if (newBoardPositionRequiresAutoLayoutConstraintUpdate ||
      oldPositionShowsMove != newPositionShowsMove ||
      oldPositionHasCapturedStones != newPositionHasCapturedStones ||
      oldPositionShowsInfoIcon != newPositionShowsInfoIcon ||
      oldPositionShowsHotspotIcon != newPositionShowsHotspotIcon ||
      oldPositionShowsMarkupIcon != newPositionShowsMarkupIcon)
  {
    [self setNeedsLayout];
  }
}

#pragma mark - Static Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Main method for setting up the static Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraints
{
  self.nodeSymbolImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.textLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.detailTextLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.capturedStonesLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.infoIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.hotspotIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.markupIconImageView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.nodeSymbolImageView, @"nodeSymbolImageView",
                                   self.textLabel, @"textLabel",
                                   self.detailTextLabel, @"detailTextLabel",
                                   self.capturedStonesLabel, @"capturedStonesLabel",
                                   self.hotspotIconImageView, @"hotspotIconImageView",
                                   self.infoIconImageView, @"infoIconImageView",
                                   self.markupIconImageView, @"markupIconImageView",
                                   nil];

  [self setupStaticAutoLayoutConstraintsNodeSymbolImageView:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsTextLabel:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsDetailTextLabel:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsCapturedStonesLabel:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsInfoIconImageView:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsHotspotIconImageView:viewsDictionary];
  [self setupStaticAutoLayoutConstraintsMarkupIconImageView:viewsDictionary];
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for nodeSymbolImageView.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsNodeSymbolImageView:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C000
  NSLayoutXAxisAnchor* leftAnchor = self.safeAreaLayoutGuide.leftAnchor;
  NSLayoutConstraint* xPositionConstraint = [self.nodeSymbolImageView.leftAnchor constraintEqualToAnchor:leftAnchor
                                                                                                constant:horizontalMargin];
  xPositionConstraint.active = YES;
  xPositionConstraint.identifier = @"C000";
  // C001
  NSLayoutConstraint* yPositionConstraint = [AutoLayoutUtility alignFirstView:self.nodeSymbolImageView
                                                               withSecondView:self
                                                                  onAttribute:NSLayoutAttributeCenterY
                                                             constraintHolder:self];
  yPositionConstraint.identifier = @"C001";
  // C002
  [visualFormats addObject:[NSString stringWithFormat:@"H:[nodeSymbolImageView(==%f)]", nodeSymbolImageDimension]];
  // C003
  [visualFormats addObject:[NSString stringWithFormat:@"V:[nodeSymbolImageView(==%f)]", nodeSymbolImageDimension]];

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:2];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C002";
  ((NSLayoutConstraint*)constraints[1]).identifier = @"C003";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for textLabel.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsTextLabel:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C010
  [visualFormats addObject:[NSString stringWithFormat:@"H:[nodeSymbolImageView]-%d-[textLabel]", horizontalSpacingSiblings]];
  // C011
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-%d-[textLabel]", verticalMargin]];

  // C012 width = C030
  // C013 height = C023
  // C014 numberOfLines = 1 (the default)
  // C015 horizontal text alignment = default (left)
  // C016 vertical text alignment = default (center)

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:2];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C010";
  ((NSLayoutConstraint*)constraints[1]).identifier = @"C011";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for detailTextLabel.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsDetailTextLabel:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C020
  [visualFormats addObject:[NSString stringWithFormat:@"H:[nodeSymbolImageView]-%d-[detailTextLabel]", horizontalSpacingSiblings]];
  // C021
  self.detailTextLabelYPositionConstraint = [NSLayoutConstraint constraintWithItem:self.detailTextLabel
                                                                         attribute:NSLayoutAttributeTop
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.textLabel
                                                                         attribute:NSLayoutAttributeBottom
                                                                        multiplier:1.0
                                                                          constant:verticalSpacingLabels];
  self.detailTextLabelYPositionConstraint.active = YES;
  self.detailTextLabelYPositionConstraint.identifier = @"C021";

  // C022 width = C050

  // C023
  [visualFormats addObject:[NSString stringWithFormat:@"V:[detailTextLabel]-%d-|", verticalMargin]];
  // C024
  self.detailTextLabelZeroHeightConstraint = [NSLayoutConstraint constraintWithItem:self.detailTextLabel
                                                                          attribute:NSLayoutAttributeHeight
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:0.0f];
  self.detailTextLabelZeroHeightConstraint.active = NO;
  self.detailTextLabelZeroHeightConstraint.identifier = @"C024";

  // C025 numberOfLines = 1 (the default)
  // C026 horizontal text alignment = default (left)
  // C027 vertical text alignment = default (center)

  // C028
  // If the cell is higher than required then without this constraint the detail
  // text label gets all the surplus height while the text label stays at the
  // minimum height. Activating the constraint makes sure that the two labels
  // get an equal share of the available height.
  // This constraint is disabled by default. It can be activated to test out
  // alternate layouts.
  static bool activateEqualHeightsConstraint = false;
  if (activateEqualHeightsConstraint)
  {
    NSLayoutConstraint* equalHeightsConstraint = [AutoLayoutUtility alignFirstView:self.detailTextLabel
                                                                    withSecondView:self.textLabel
                                                                       onAttribute:NSLayoutAttributeHeight
                                                                  constraintHolder:self];
    equalHeightsConstraint.identifier = @"C028";
  }

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:2];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C020";
  ((NSLayoutConstraint*)constraints[1]).identifier = @"C023";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for capturedStonesLabel.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsCapturedStonesLabel:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C030
  [visualFormats addObject:[NSString stringWithFormat:@"H:[textLabel]-%d-[capturedStonesLabel]", horizontalSpacingSiblings]];
  // C031
  NSLayoutConstraint* constraint = [AutoLayoutUtility alignFirstView:self.capturedStonesLabel
                                                      withSecondView:self.textLabel
                                                         onAttribute:NSLayoutAttributeCenterY
                                                    constraintHolder:self];
  constraint.identifier = @"C031";

  // C032 width = C040
  // C033 height = intrinsic height
  // C034 numberOfLines = 1 (the default)

  // C035
  self.capturedStonesLabel.textAlignment = NSTextAlignmentRight;

  // C036 vertical text alignment = default (center)

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:1];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C030";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for infoIconImageView.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsInfoIconImageView:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C040
  self.infoIconImageViewLeftEdgeConstraint = [NSLayoutConstraint constraintWithItem:self.infoIconImageView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.capturedStonesLabel
                                                                          attribute:NSLayoutAttributeTrailing
                                                                         multiplier:1.0
                                                                           constant:horizontalSpacingSiblings];
  self.infoIconImageViewLeftEdgeConstraint.active = YES;
  self.infoIconImageViewLeftEdgeConstraint.identifier = @"C040";

  // C041 - wholly defined in dynamic constraints

  // C042
  NSLayoutXAxisAnchor* rightAnchor = self.safeAreaLayoutGuide.rightAnchor;
  NSLayoutConstraint* widthConstraint = [self.infoIconImageView.rightAnchor constraintEqualToAnchor:rightAnchor
                                                                                           constant:-horizontalMargin];
  widthConstraint.active = YES;
  widthConstraint.identifier = @"C042";

  // C043
  // Start out with a non-zero width - the actual value will be updated
  // dynamically
  self.infoIconImageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.infoIconImageView
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1.0
                                                                        constant:iconImageDimension];
  self.infoIconImageViewWidthConstraint.active = YES;
  self.infoIconImageViewWidthConstraint.identifier = @"C043";

  // C044
  [visualFormats addObject:[NSString stringWithFormat:@"V:[infoIconImageView(==%f)]", iconImageDimension]];

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:1];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C044";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for hotspotIconImageView.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsHotspotIconImageView:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C050
  [visualFormats addObject:[NSString stringWithFormat:@"H:[detailTextLabel]-%d-[hotspotIconImageView]", horizontalSpacingSiblings]];

  // C051 - wholly defined in dynamic constraints
  // C052 width = C060

  // C053
  // Start out with a non-zero width - the actual value will be updated
  // dynamically
  self.hotspotIconImageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.hotspotIconImageView
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:nil
                                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                                         multiplier:1.0
                                                                           constant:iconImageDimension];
  self.hotspotIconImageViewWidthConstraint.active = YES;
  self.hotspotIconImageViewWidthConstraint.identifier = @"C053";

  // C054
  [visualFormats addObject:[NSString stringWithFormat:@"V:[hotspotIconImageView(==%f)]", iconImageDimension]];

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:2];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C050";
  ((NSLayoutConstraint*)constraints[1]).identifier = @"C054";
}

// -----------------------------------------------------------------------------
/// @brief Set up the static Auto Layout constraints for markupIconImageView.
// -----------------------------------------------------------------------------
- (void) setupStaticAutoLayoutConstraintsMarkupIconImageView:(NSDictionary*)viewsDictionary
{
  NSMutableArray* visualFormats = [NSMutableArray array];

  // C060
  self.markupIconImageViewLeftEdgeConstraint = [NSLayoutConstraint constraintWithItem:self.markupIconImageView
                                                                            attribute:NSLayoutAttributeLeading
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self.hotspotIconImageView
                                                                            attribute:NSLayoutAttributeTrailing
                                                                           multiplier:1.0
                                                                             constant:horizontalSpacingSiblings];
  self.markupIconImageViewLeftEdgeConstraint.active = YES;
  self.markupIconImageViewLeftEdgeConstraint.identifier = @"C060";

  // C061 - wholly defined in dynamic constraints

  // C062
  NSLayoutXAxisAnchor* rightAnchor = self.safeAreaLayoutGuide.rightAnchor;
  NSLayoutConstraint* widthConstraint = [self.markupIconImageView.rightAnchor constraintEqualToAnchor:rightAnchor
                                                                                             constant:-horizontalMargin];
  widthConstraint.active = YES;
  widthConstraint.identifier = @"C062";

  // C063
  // Start out with a non-zero width - the actual value will be updated
  // dynamically
  self.markupIconImageViewWidthConstraint = [NSLayoutConstraint constraintWithItem:self.markupIconImageView
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0
                                                                          constant:iconImageDimension];
  self.markupIconImageViewWidthConstraint.active = YES;
  self.markupIconImageViewWidthConstraint.identifier = @"C063";

  // C064
  [visualFormats addObject:[NSString stringWithFormat:@"V:[markupIconImageView(==%f)]", iconImageDimension]];

  NSArray* constraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self];
  [self throwIfConstraints:constraints hasNotExpectedCount:1];
  ((NSLayoutConstraint*)constraints[0]).identifier = @"C064";
}

// -----------------------------------------------------------------------------
/// @brief Helper for setting up the static Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) throwIfConstraints:(NSArray*)constraints
        hasNotExpectedCount:(NSUInteger)expectedCount
{
  if (constraints.count == expectedCount)
    return;

  @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"Unexpected constraints count %lu, expected was %lu", (unsigned long)constraints.count, (unsigned long)expectedCount]
                               userInfo:nil];
}

#pragma mark - Dynamic Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Updates dynamic layout constraints according to the current content
/// of this cell.
// -----------------------------------------------------------------------------
- (void) updateDynamicAutoLayoutConstraints
{
  bool showDetailText = self.detailTextLabel.text != nil;
  bool showInfoIcon = self.infoIconImageView.image != nil;
  bool showHotspotIcon = self.hotspotIconImageView.image != nil;
  bool showMarkupIcon = self.markupIconImageView.image != nil;

  // C021
  self.detailTextLabelYPositionConstraint.constant = showDetailText ? verticalSpacingLabels : 0.0f;
  // C024
  self.detailTextLabelZeroHeightConstraint.active = showDetailText ? NO : YES;

  // C040
  self.infoIconImageViewLeftEdgeConstraint.constant = showInfoIcon ? horizontalSpacingSiblings : 0;
  // C043
  self.infoIconImageViewWidthConstraint.constant = showInfoIcon ? iconImageDimension : 0.0f;

  // C053
  self.hotspotIconImageViewWidthConstraint.constant = showHotspotIcon ? iconImageDimension : 0.0f;

  // C060
  self.markupIconImageViewLeftEdgeConstraint.constant = showMarkupIcon ? horizontalSpacingSiblings : 0;
  // C063
  self.markupIconImageViewWidthConstraint.constant = showMarkupIcon ? iconImageDimension : 0.0f;

  // Because detailTextLabel is sometimes not displayed the vertical
  // positioning of the icon images needs to be dynamic. If detailTextLabel
  // is not shown, the hotspot icon and markup icon images are aligned instead
  // on the center of textLabel. In addition if both the info icon
  // image in the top row and one or both of the icon images in the bottom row
  // are shown, the two rows need to have a bit of spacing in between.
  UIView* alignViewTopRow;
  UIView* alignViewBottomRow;
  CGFloat constantTopRow;
  CGFloat constantBottomRow;
  if (showDetailText)
  {
    alignViewTopRow = self.textLabel;
    alignViewBottomRow = self.detailTextLabel;
    constantTopRow = 0.0f;
    constantBottomRow = 0.0f;
  }
  else
  {
    alignViewTopRow = self;
    alignViewBottomRow = self;

    if (showInfoIcon && (showHotspotIcon || showMarkupIcon))
    {
      CGFloat alignModifier = (iconImageDimension + verticalSpacingIconImageViews) / 2.0f;
      constantTopRow = -alignModifier;
      constantBottomRow = alignModifier;
    }
    else
    {
      constantTopRow = 0.0f;
      constantBottomRow = 0.0f;
    }
  }

  // C041
  if (self.infoIconImageViewYPositionConstraint)
    self.infoIconImageViewYPositionConstraint.active = NO;
  self.infoIconImageViewYPositionConstraint = [NSLayoutConstraint constraintWithItem:self.infoIconImageView
                                                                           attribute:NSLayoutAttributeCenterY
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:alignViewTopRow
                                                                           attribute:NSLayoutAttributeCenterY
                                                                          multiplier:1.0
                                                                            constant:constantTopRow];
  self.infoIconImageViewYPositionConstraint.active = YES;
  self.infoIconImageViewYPositionConstraint.identifier = @"C041";

  // C051
  if (self.hotspotIconImageViewYPositionConstraint)
    self.hotspotIconImageViewYPositionConstraint.active = NO;
  self.hotspotIconImageViewYPositionConstraint = [NSLayoutConstraint constraintWithItem:self.hotspotIconImageView
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:alignViewBottomRow
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.0
                                                                               constant:constantBottomRow];
  self.hotspotIconImageViewYPositionConstraint.active = YES;
  self.hotspotIconImageViewYPositionConstraint.identifier = @"C051";

  // C061
  if (self.markupIconImageViewYPositionConstraint)
    self.markupIconImageViewYPositionConstraint.active = NO;
  self.markupIconImageViewYPositionConstraint = [NSLayoutConstraint constraintWithItem:self.markupIconImageView
                                                                             attribute:NSLayoutAttributeCenterY
                                                                             relatedBy:NSLayoutRelationEqual
                                                                                toItem:alignViewBottomRow
                                                                             attribute:NSLayoutAttributeCenterY
                                                                            multiplier:1.0
                                                                              constant:constantBottomRow];
  self.markupIconImageViewYPositionConstraint.active = YES;
  self.markupIconImageViewYPositionConstraint.identifier = @"C061";
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates all kinds of colors to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors:(GoNode*)node
{
  bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:self.traitCollection];

  if (0 == (self.boardPosition % 2))
    self.backgroundColor = isLightUserInterfaceStyle ? alternateCellBackgroundColor1 : alternateCellBackgroundColor1DarkMode;
  else
    self.backgroundColor = isLightUserInterfaceStyle ? alternateCellBackgroundColor2 : alternateCellBackgroundColor2DarkMode;

  UIColor* iconTintColor = isLightUserInterfaceStyle ? [UIColor blackColor] : [UIColor whiteColor];;

  if (self.infoIconImageView.image)
    self.infoIconImageView.tintColor = iconTintColor;

  if (self.markupIconImageView.image)
    self.markupIconImageView.tintColor = iconTintColor;

  if (self.hotspotIconImageView.image)
  {
    GoNodeAnnotation* nodeAnnotation = node ? node.goNodeAnnotation : nil;
    enum GoBoardPositionHotspotDesignation goBoardPositionHotspotDesignation = nodeAnnotation ? nodeAnnotation.goBoardPositionHotspotDesignation : GoBoardPositionHotspotDesignationNone;
    if (goBoardPositionHotspotDesignation == GoBoardPositionHotspotDesignationYesEmphasized)
      self.hotspotIconImageView.tintColor = [UIColor hotspotColor:goBoardPositionHotspotDesignation];
    else
      self.hotspotIconImageView.tintColor = iconTintColor;
  }
}

#pragma mark - Helpers

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object whose data is displayed by the cell.
/// Returns @e nil if the cell refers to a node that does not exist. This can
/// occur if this method is invoked for a reused cell before the cell's
/// @e boardPosition property has been updated.
// -----------------------------------------------------------------------------
- (GoNode*) nodeWithDataOrNil
{
  GoNodeModel* nodeModel = [GoGame sharedGame].nodeModel;

  int nodeIndex = self.boardPosition;
  if (nodeIndex >= nodeModel.numberOfNodes)
    return nil;

  GoNode* node = [nodeModel nodeAtIndex:nodeIndex];
  return node;
}

#pragma mark - One-time view size calculation

// -----------------------------------------------------------------------------
/// @brief Returns the pre-calculated size of a BoardPositionCollectionViewCell
/// instance that represents board position 0.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
// -----------------------------------------------------------------------------
+ (CGSize) boardPositionCollectionViewCellSizePositionZero
{
  if (CGSizeEqualToSize(boardPositionCollectionViewCellSizePositionZero, CGSizeZero))
    [BoardPositionCollectionViewCell setupStaticViewMetrics];
  return boardPositionCollectionViewCellSizePositionZero;
}

// -----------------------------------------------------------------------------
/// @brief Returns the pre-calculated size of a BoardPositionCollectionViewCell
/// instance that represents a non-zero board position.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
// -----------------------------------------------------------------------------
+ (CGSize) boardPositionCollectionViewCellSizePositionNonZero
{
  if (CGSizeEqualToSize(boardPositionCollectionViewCellSizePositionNonZero, CGSizeZero))
    [BoardPositionCollectionViewCell setupStaticViewMetrics];
  return boardPositionCollectionViewCellSizePositionNonZero;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for boardPositionCollectionViewCellSize().
// -----------------------------------------------------------------------------
+ (void) setupStaticViewMetrics
{
  NodeTreeViewModel* nodeTreeViewModel = [ApplicationDelegate sharedDelegate].nodeTreeViewModel;
  id<NodeTreeViewCanvasDataProvider> nodeTreeViewCanvasDataProvider = [[[PrivateNodeTreeViewCanvasDataProvider alloc] init] autorelease];
  NodeTreeViewMetrics* metrics = [[[NodeTreeViewMetrics alloc] initWithModel:nodeTreeViewModel
                                                          canvasDataProvider:nodeTreeViewCanvasDataProvider
                                                             traitCollection:nil
                                                              darkBackground:false] autorelease];
  nodeSymbolImages = [[NSMutableDictionary alloc] init];
  for (enum NodeTreeViewCellSymbol nodeSymbol = NodeTreeViewCellSymbolFirst;
       nodeSymbol <= NodeTreeViewCellSymbolLast;
       nodeSymbol++)
  {
    if (nodeSymbol == NodeTreeViewCellSymbolNone)
      continue;

    [BoardPositionCollectionViewCell addNodeSymbolImage:nodeSymbol
                                           toDictionary:nodeSymbolImages
                                            withMetrics:metrics];
  }

  CGSize iconImageSize = CGSizeMake(iconImageDimension, iconImageDimension);
  infoIconImage = [[[UIImage imageNamed:uiAreaAboutIconResource] templateImageByResizingToSize:iconImageSize] retain];
  markupIconImage = [[[UIImage imageNamed:markupIconResource] templateImageByResizingToSize:iconImageSize] retain];
  hotspotIconImage = [[[UIImage imageNamed:hotspotIconResource] templateImageByResizingToSize:iconImageSize] retain];

  currentBoardPositionCellBackgroundColor = [[UIColor darkTangerineColor] retain];
  alternateCellBackgroundColor1 = [[UIColor lightBlueColor] retain];
  alternateCellBackgroundColor2 = [[UIColor whiteColor] retain];
  alternateCellBackgroundColor1DarkMode = [UIColor systemGrayColor];
  alternateCellBackgroundColor2DarkMode = [UIColor systemGray2Color];
  capturedStonesLabelTextColor = [[UIColor redColor] retain];

  largeFont = [[UIFont systemFontOfSize:largeFontSize] retain];
  smallFont = [[UIFont systemFontOfSize:smallFontSize] retain];

  enum BoardPositionCollectionViewCellType cellType = BoardPositionCollectionViewCellTypePositionZero;
  BoardPositionCollectionViewCell* offscreenView = [[[BoardPositionCollectionViewCell alloc] initOffscreenViewWithCellType:cellType] autorelease];
  [offscreenView layoutIfNeeded];
  boardPositionCollectionViewCellSizePositionZero = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

  cellType = BoardPositionCollectionViewCellTypePositionNonZero;
  offscreenView = [[[BoardPositionCollectionViewCell alloc] initOffscreenViewWithCellType:cellType] autorelease];
  [offscreenView layoutIfNeeded];
  boardPositionCollectionViewCellSizePositionNonZero = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];

  // If values with fractions are used there is bound to be a rounding error
  // at some stage, either when the cell sizes are passed to the collection view
  // or when the cell sizes are used for Auto Layout constraints.
  boardPositionCollectionViewCellSizePositionZero = CGSizeMake(ceilf(boardPositionCollectionViewCellSizePositionZero.width),
                                                               ceilf(boardPositionCollectionViewCellSizePositionZero.height));
  boardPositionCollectionViewCellSizePositionNonZero = CGSizeMake(ceilf(boardPositionCollectionViewCellSizePositionNonZero.width),
                                                                  ceilf(boardPositionCollectionViewCellSizePositionNonZero.height));
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupStaticViewMetrics().
// -----------------------------------------------------------------------------
+ (UIImage*) addNodeSymbolImage:(enum NodeTreeViewCellSymbol)nodeSymbol
                   toDictionary:(NSMutableDictionary*)nodeSymbolImages
                    withMetrics:(NodeTreeViewMetrics*)metrics
{
  // Create context
  CGSize nodeSymbolImageSize = CGSizeMake(nodeSymbolImageDimension, nodeSymbolImageDimension);
  BOOL opaque = NO;
  CGFloat scale = 0.0f;
  UIGraphicsBeginImageContextWithOptions(nodeSymbolImageSize, opaque, scale);

  // Create layer using function provided by NodeTreeViewDrawingHelper
  CGContextRef context = UIGraphicsGetCurrentContext();
  static bool condensed = false;
  CGLayerRef nodeSymbolLayer = CreateNodeSymbolLayer(context, nodeSymbol, condensed, metrics);

  // Draw layer into context
  CGRect drawingRect = CGRectZero;
  drawingRect.size = nodeSymbolImageSize;
  CGContextDrawLayerInRect(context, drawingRect, nodeSymbolLayer);

  // Get image from context
  UIImage* nodeSymbolImage = UIGraphicsGetImageFromCurrentImageContext();

  // Release objects created above
  CGLayerRelease(nodeSymbolLayer);
  UIGraphicsEndImageContext();

  NSNumber* nodeSymbolAsNumber = [NSNumber numberWithInt:nodeSymbol];
  nodeSymbolImages[nodeSymbolAsNumber] = nodeSymbolImage;

  return nodeSymbolImage;
}

@end
