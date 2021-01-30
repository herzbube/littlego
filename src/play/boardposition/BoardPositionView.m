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
#import "BoardPositionView.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"


// This variable must be accessed via [BoardPositionView boardPositionViewSize]
static CGSize boardPositionViewSize = { 0.0f, 0.0f };
static UIImage* blackStoneImage = nil;
static UIImage* whiteStoneImage = nil;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardPositionView.
// -----------------------------------------------------------------------------
@interface BoardPositionView()
@property(nonatomic, assign) bool offscreenMode;
@property(nonatomic, assign) UILabel* boardPositionLabel;
@property(nonatomic, assign) UILabel* intersectionLabel;
@property(nonatomic, assign) UILabel* capturedStonesLabel;
@property(nonatomic, assign) UIImageView* stoneImageView;
@property(nonatomic, assign) bool isBoardPositionValid;
@property(nonatomic, assign) bool isCurrentBoardPositionValid;
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
  self.isBoardPositionValid = false;
  self.isCurrentBoardPositionValid = false;

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
  // The frame for the off-screen view can be pretty much any size, the view
  // will be resized by setupStaticViewMetrics to UILayoutFittingCompressedSize
  // anyway. There is one restriction though: The frame must be large enough to
  // accomodate all spacings set up by setupAutoLayoutConstraints(). If the
  // frame is not large enough (e.g. CGRectZero) Auto Layout will print a
  // warning to the debug console, but continue by breaking one of the
  // constraints.
  CGRect frame = CGRectMake(0, 0, 100, 100);
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
  [self addSubview:self.boardPositionLabel];
  [self addSubview:self.intersectionLabel];
  [self addSubview:self.capturedStonesLabel];
  [self addSubview:self.stoneImageView];
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

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.boardPositionLabel, @"boardPositionLabel",
                                   self.intersectionLabel, @"intersectionLabel",
                                   self.capturedStonesLabel, @"capturedStonesLabel",
                                   self.stoneImageView, @"stoneImageView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            @"H:|-2-[boardPositionLabel]",
                            // boardPositionLabel will never overlap
                            // stoneImageView, so we don't have to specify a
                            // spacing between the two. This is important
                            // because it saves us another constraint where we
                            // would have to specify that the label can expand
                            // while the image must hug its content.
                            @"H:[stoneImageView]-2-|",
                            @"H:|-2-[intersectionLabel]-2-[capturedStonesLabel]-2-|",
                            @"V:|-2-[boardPositionLabel]-0-[intersectionLabel]-2-|",
                            @"V:[capturedStonesLabel]-2-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self];
  // Experimentally determined that pinning the baseline looks best with how we
  // currently calculate the stone image size (see setupStaticViewMetrics())
  [AutoLayoutUtility alignFirstView:self.stoneImageView
                     withSecondView:self.boardPositionLabel
                        onAttribute:NSLayoutAttributeBaseline
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
  GoMove* move = nil;
  if (0 == self.boardPosition)
  {
    self.boardPositionLabel.text = [NSString stringWithFormat:@"H: %1lu", (unsigned long)game.handicapPoints.count];
    NSString* komiString = [NSString stringWithKomi:game.komi numericZeroValue:true];
    self.intersectionLabel.text = [NSString stringWithFormat:@"K: %@", komiString];
    self.stoneImageView.image = nil;
    self.capturedStonesLabel.text = nil;
  }
  else
  {
    int moveIndex = self.boardPosition - 1;
    move = [game.moveModel moveAtIndex:moveIndex];
    self.boardPositionLabel.text = [NSString stringWithFormat:@"%d", self.boardPosition];
    self.intersectionLabel.text = [self intersectionLabelTextForMove:move];
    self.stoneImageView.image = [self stoneImageForMove:move];
    self.capturedStonesLabel.text = [self capturedStonesLabelTextForMove:move];
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
  if (self.isBoardPositionValid)
  {
    if (_boardPosition == newValue)
      return;
  }
  else
  {
    self.isBoardPositionValid = true;
  }

  _boardPosition = newValue;
  [self setupRealContent];
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(bool)newValue
{
  if (self.isCurrentBoardPositionValid)
  {
    if (_currentBoardPosition == newValue)
      return;
  }
  else
  {
    self.isCurrentBoardPositionValid = true;
  }

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

#pragma mark - Other methods

// -----------------------------------------------------------------------------
/// @brief Invalidates the content of this BoardPositionView. The view content
/// is guaranteed to be updated when @e boardPosition is set the next time.
// -----------------------------------------------------------------------------
- (void) invalidateContent
{
  self.isBoardPositionValid = false;
  self.isCurrentBoardPositionValid = false;
}

@end
