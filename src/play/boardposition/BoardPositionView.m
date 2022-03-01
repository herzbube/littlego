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
#import "BoardPositionView.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeAnnotation.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// This variable must be accessed via [BoardPositionView boardPositionViewSize]
static CGSize boardPositionViewSize = { 0.0f, 0.0f };
static UIImage* blackStoneImage = nil;
static UIImage* whiteStoneImage = nil;
static UIImage* infoIconImage = nil;
static UIImage* hotspotIconImage = nil;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardPositionView.
// -----------------------------------------------------------------------------
@interface BoardPositionView()
@property(nonatomic, assign) bool offscreenMode;
@property(nonatomic, assign) UILabel* boardPositionLabel;
@property(nonatomic, assign) UILabel* intersectionLabel;
@property(nonatomic, assign) UILabel* capturedStonesLabel;
@property(nonatomic, assign) UIImageView* stoneImageView;
@property(nonatomic, assign) UIImageView* infoIconImageView;
@property(nonatomic, assign) UIImageView* hotspotIconImageView;
@end


@implementation BoardPositionView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionView object with frame @a rect.
///
/// @note This is the designated initializer of BoardPositionView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UICollectionViewCell)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.offscreenMode = false;
  _boardPosition = -1;             // don't use self, we don't want to trigger the setter
  _currentBoardPosition = false;   // ditto

  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureSubviews];

  // No content to setup, we first need a board position
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionView object that is never rendered on
/// screen.
///
/// @note This initializer is privately used for the one-time pre-calculation
/// of the BoardPositionView size.
// -----------------------------------------------------------------------------
- (id) initOffscreenView
{
  // Notes regarding the initial frame we choose here for the off-screen view:
  // - The frame should be smaller than the actual minimal size that will result
  //   from laying the view out with dummy content. The actual minimal size will
  //   be calculated by setupStaticViewMetrics by.
  // - In earlier iOS base SDKs it was possible to have an initial frame larger
  //   than the actual minimal size, and it would get compressed - this no
  //   longer seems to work with base SDK 15. E.g. a frame with width 100 will
  //   stay at this width.
  // - The frame must not be CGRectZero, or a very small size. If the frame is
  //   not large enough Auto Layout will print a warning to the debug console,
  //   but continue by breaking one of the constraints. It is likely that the
  //   frame must be large enough to accomodate all spacings set up by
  //   setupAutoLayoutConstraints().
  CGRect frame = CGRectMake(0, 0, 20, 20);
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;
  self.offscreenMode = true;
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureSubviews];
  [self setupDummyContent];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardPositionLabel = nil;
  self.intersectionLabel = nil;
  self.capturedStonesLabel = nil;
  self.stoneImageView = nil;
  self.infoIconImageView = nil;
  self.hotspotIconImageView = nil;
  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.boardPositionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.intersectionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.capturedStonesLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.stoneImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.infoIconImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.hotspotIconImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  [self addSubview:self.boardPositionLabel];
  [self addSubview:self.intersectionLabel];
  [self addSubview:self.capturedStonesLabel];
  [self addSubview:self.stoneImageView];
  [self addSubview:self.infoIconImageView];
  [self addSubview:self.hotspotIconImageView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.boardPositionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.intersectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.capturedStonesLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.stoneImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.infoIconImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.hotspotIconImageView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.boardPositionLabel, @"boardPositionLabel",
                                   self.intersectionLabel, @"intersectionLabel",
                                   self.capturedStonesLabel, @"capturedStonesLabel",
                                   self.stoneImageView, @"stoneImageView",
                                   self.infoIconImageView, @"infoIconImageView",
                                   self.hotspotIconImageView, @"hotspotIconImageView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-5-[boardPositionLabel]-0-[stoneImageView]-5-[infoIconImageView]-5-|",
                            @"H:|-5-[intersectionLabel]-5-[capturedStonesLabel]-5-[hotspotIconImageView]-5-|",
                            @"V:|-2-[boardPositionLabel]-0-[intersectionLabel]-2-|",
                            @"V:[capturedStonesLabel]-2-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self];

  // Avoid images being horizontally stretched. Labels will get more space
  // because of this.
  [self.stoneImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
  [self.infoIconImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
  [self.hotspotIconImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

  [AutoLayoutUtility alignFirstView:self.stoneImageView
                     withSecondView:self.boardPositionLabel
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self];
  [AutoLayoutUtility alignFirstView:self.infoIconImageView
                     withSecondView:self.stoneImageView
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self];
  [AutoLayoutUtility alignFirstView:self.hotspotIconImageView
                     withSecondView:self.intersectionLabel
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) configureSubviews
{
  UIFont* font = [UIFont systemFontOfSize:11];
  self.boardPositionLabel.font = font;
  self.intersectionLabel.font = font;
  self.capturedStonesLabel.font = font;

  self.capturedStonesLabel.textAlignment = NSTextAlignmentRight;
  self.capturedStonesLabel.textColor = [UIColor redColor];

  self.intersectionLabel.accessibilityIdentifier = intersectionLabelBoardPositionAccessibilityIdentifier;
  self.boardPositionLabel.accessibilityIdentifier = boardPositionLabelBoardPositionAccessibilityIdentifier;
  self.capturedStonesLabel.accessibilityIdentifier = capturedStonesLabelBoardPositionAccessibilityIdentifier;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the designated initializer.
// -----------------------------------------------------------------------------
- (void) setupRealContent
{
  if (-1 == self.boardPosition)
    return;

  GoGame* game = [GoGame sharedGame];
  if (0 == self.boardPosition)
  {
    self.boardPositionLabel.text = [NSString stringWithFormat:@"H: %1lu", (unsigned long)game.handicapPoints.count];
    NSString* komiString = [NSString stringWithKomi:game.komi numericZeroValue:true];
    self.intersectionLabel.text = [NSString stringWithFormat:@"K: %@", komiString];
    self.stoneImageView.image = nil;
    self.capturedStonesLabel.text = nil;
    self.infoIconImageView.image = nil;
    self.hotspotIconImageView.image = nil;
  }
  else
  {
    int nodeIndex = self.boardPosition;
    GoNode* node = [game.nodeModel nodeAtIndex:nodeIndex];

    if ([self showsMoveData:node])
    {
      GoMove* move = node.goMove;
      self.boardPositionLabel.text = [NSString stringWithFormat:@"%d", move.moveNumber];
      self.intersectionLabel.text = [self intersectionLabelTextForMove:move];
      self.stoneImageView.image = [self stoneImageForMove:move];
      self.capturedStonesLabel.text = [self capturedStonesLabelTextForMove:move];
    }
    else
    {
      self.boardPositionLabel.text = @"No";
      self.intersectionLabel.text = @"move";
      self.stoneImageView.image = nil;
      self.capturedStonesLabel.text = nil;
    }

    if ([self showsInfoIcon:node])
      self.infoIconImageView.image = infoIconImage;
    else
      self.infoIconImageView.image = nil;

    if ([self showsHotspotIcon:node])
    {
      self.hotspotIconImageView.image = hotspotIconImage;
      self.hotspotIconImageView.tintColor = [UIColor hotspotColor:node.goNodeAnnotation.goBoardPositionHotspotDesignation];
    }
    else
    {
      self.hotspotIconImageView.image = nil;
    }
  }
  [self setupBackgroundColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the offscreen initializer.
// -----------------------------------------------------------------------------
- (void) setupDummyContent
{
  // These must be longest strings that can possibly appear
  self.boardPositionLabel.text = @"H: 9";
  self.intersectionLabel.text = @"K: 6½";
  self.capturedStonesLabel.text = @"999";
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (NSString*) intersectionLabelTextForMove:(GoMove*)move
{
  if (GoMoveTypePlay == move.type)
    return move.point.vertex.string;
  else
    return @"Pass";
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (UIImage*) stoneImageForMove:(GoMove*)move
{
  if (move.player.black)
    return blackStoneImage;
  else
    return whiteStoneImage;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
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
- (void) setupBackgroundColor
{
  if (self.currentBoardPosition)
  {
    self.backgroundColor = [UIColor darkTangerineColor];
  }
  else
  {
    bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:self.traitCollection];
    if (isLightUserInterfaceStyle)
      [self setupBackgroundColorForLightMode];
    else
      [self setupBackgroundColorForDarkMode];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupBackgroundColor().
// -----------------------------------------------------------------------------
- (void) setupBackgroundColorForLightMode
{
  if (0 == (self.boardPosition % 2))
    self.backgroundColor = [UIColor nonPhotoBlueColor];
  else
    self.backgroundColor = [UIColor mayaBlueColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupBackgroundColor().
// -----------------------------------------------------------------------------
- (void) setupBackgroundColorForDarkMode
{
  if (@available(iOS 13.0, *))
  {
    if (0 == (self.boardPosition % 2))
      self.backgroundColor = [UIColor systemGrayColor];
    else
      self.backgroundColor = [UIColor systemGray2Color];
  }
  else
  {
    [self setupBackgroundColorForLightMode];
  }
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

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This is implemented so that BoardPositionView can be used with Auto Layout.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  if (self.offscreenMode)
    return [super intrinsicContentSize];
  else
    return boardPositionViewSize;
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This is implemented so that BoardPositionView can switch between Light Mode
/// and Dark Mode.
// -----------------------------------------------------------------------------
- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];

  if (@available(iOS 12.0, *))
  {
    if (self.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle)
    {
      [self setupBackgroundColor];
    }
  }
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setBoardPosition:(int)newValue
{
  _boardPosition = newValue;
  [self setupRealContent];
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(bool)newValue
{
  _currentBoardPosition = newValue;
  [self setupRealContent];
  [self setNeedsLayout];
}

#pragma mark - One-time view size calculation

// -----------------------------------------------------------------------------
/// @brief Returns the pre-calculated size of all BoardPositionView instances.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
// -----------------------------------------------------------------------------
+ (CGSize) boardPositionViewSize
{
  if (CGSizeEqualToSize(boardPositionViewSize, CGSizeZero))
    [BoardPositionView setupStaticViewMetrics];
  return boardPositionViewSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for boardPositionViewSize().
// -----------------------------------------------------------------------------
+ (void) setupStaticViewMetrics
{
  BoardPositionView* offscreenView = [[[BoardPositionView alloc] initOffscreenView] autorelease];
  [offscreenView layoutIfNeeded];
  CGSize offscreenViewSize = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
  // If values with fractions are used there is bound to be a rounding error
  // at some stage, either when the cell sizes are passed to the collection view
  // or when the cell sizes are used for Auto Layout constraints. For instance,
  // an effect that was observed with fractions was this totally misleading
  // warning output in Xcode's debug window:
  // "The behavior of the UICollectionViewFlowLayout is not defined because
  // the item height must be less than the height of the UICollectionView minus
  // the section insets top and bottom values, minus the content insets top and
  // bottom values."
  boardPositionViewSize = CGSizeMake(ceilf(offscreenViewSize.width), ceilf(offscreenViewSize.height));

  // The stone image size is based on the height of one of the labels
  CGFloat stoneImageDimension = offscreenView.boardPositionLabel.intrinsicContentSize.height;
  stoneImageDimension *= 0.75;
  // We can't have fractions, otherwise the resulting image will look fuzzy due
  // to anti-aliasing
  stoneImageDimension = floorf(stoneImageDimension);
  // Experimentally determined that decrementing the diameter by one more point
  // looks best together with
  // 1) font size 11.0f (see configureSubviews()), and with
  // 2) pinning the stone image baseline to the board position label baseline
  //    (see setupAutoLayoutConstraints())
  stoneImageDimension--;
  blackStoneImage = [[BoardPositionView stoneImageWithDimension:stoneImageDimension
                                                          color:[UIColor blackColor]] retain];
  whiteStoneImage = [[BoardPositionView stoneImageWithDimension:stoneImageDimension
                                                          color:[UIColor whiteColor]] retain];

  // The icon image size is based on the stone image size
  CGFloat iconImageDimension = stoneImageDimension;
  CGSize iconImageSize = CGSizeMake(iconImageDimension, iconImageDimension);
  infoIconImage = [[[UIImage imageNamed:uiAreaAboutIconResource] imageByResizingToSize:iconImageSize] retain];
  hotspotIconImage = [[[UIImage imageNamed:hotspotIconResource] templateImageByResizingToSize:iconImageSize] retain];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupStaticViewMetrics().
// -----------------------------------------------------------------------------
+ (UIImage*) stoneImageWithDimension:(CGFloat)dimension color:(UIColor*)color
{
  // Make sure that we don't have fractions. If we have fractions, the resulting
  // image will be fuzzy due to anti-aliasing.
  CGFloat diameter = floorf(dimension);
  CGFloat radius = diameter / 2.0f;
  CGFloat centerXAndY = radius;
  CGPoint center = CGPointMake(centerXAndY, centerXAndY);

  CGSize imageSize = CGSizeMake(diameter, diameter);
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0.0f);
  CGContextRef context = UIGraphicsGetCurrentContext();
  [UiUtilities drawCircleWithContext:context center:center radius:radius fill:true color:color];
  UIImage* stoneImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return stoneImage;
}

@end
