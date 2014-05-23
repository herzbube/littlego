// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, assign) UILabel* boardPositionLabel;
@property(nonatomic, assign) UILabel* intersectionLabel;
@property(nonatomic, assign) UILabel* capturedStonesLabel;
@property(nonatomic, assign) UIImageView* stoneImageView;
@end


@implementation BoardPositionView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionView object that represents the board
/// position identified by @a boardPosition.
///
/// @note This is the designated initializer of BoardPositionView.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)boardPosition
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:CGRectZero];
  if (! self)
    return nil;
  CGRect bounds = self.bounds;
  bounds.size = [BoardPositionView boardPositionViewSize];
  self.bounds = bounds;
  _boardPosition = boardPosition;  // don't use self, we don't want to trigger the setter
  _currentBoardPosition = false;   // ditto
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureSubviews];
  [self setupRealContent];
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
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:CGRectZero];
  if (! self)
    return nil;
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
  self.boardPositionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.intersectionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.capturedStonesLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  self.stoneImageView = [[UIImageView alloc] initWithImage:nil];
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
                            @"H:|-2-[boardPositionLabel]-2-[stoneImageView]-2-|",
                            @"H:|-2-[intersectionLabel]-2-[capturedStonesLabel]-2-|",
                            @"V:|-2-[boardPositionLabel]-0-[intersectionLabel]-2-|",
                            @"V:[capturedStonesLabel]-2-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self];
  [AutoLayoutUtility alignFirstView:self.stoneImageView
                     withSecondView:self.boardPositionLabel
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self];
  // Let the boardPositionLabel expand
  [self.stoneImageView setContentHuggingPriority:UILayoutPriorityDefaultHigh
                                         forAxis:UILayoutConstraintAxisHorizontal];
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
    self.boardPositionLabel.text = [NSString stringWithFormat:@"H: %1d", game.handicapPoints.count];
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
  [self setupBackgroundColorForMove:move];
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
  int numberOfCapturedStones = move.capturedStones.count;
  if (0 == numberOfCapturedStones)
    return nil;
  return [NSString stringWithFormat:@"%d", numberOfCapturedStones];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupRealContent().
// -----------------------------------------------------------------------------
- (void) setupBackgroundColorForMove:(GoMove*)move
{
  if (self.currentBoardPosition)
  {
    self.backgroundColor = [UIColor darkTangerineColor];
  }
  else
  {
    bool isMoveByBlackPlayer;
    if (0 == self.boardPosition)
      isMoveByBlackPlayer = ([GoGame sharedGame].handicapPoints.count > 0);
    else
      isMoveByBlackPlayer = move.player.black;
    // These colors are shown on a very light background (almost white), so
    // they must have a certain "punch"
    if (isMoveByBlackPlayer)
      self.backgroundColor = [UIColor nonPhotoBlueColor];
    else
      self.backgroundColor = [UIColor mayaBlueColor];
  }
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setBoardPosition:(int)newValue
{
  if (_boardPosition == newValue)
    return;
  _boardPosition = newValue;
  [self setupRealContent];
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPosition:(bool)newValue
{
  if (_currentBoardPosition == newValue)
    return;
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
  boardPositionViewSize = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
  // The stone image size is based on the height of one of the labels
  CGFloat stoneImageDimension = offscreenView.boardPositionLabel.intrinsicContentSize.height;
  stoneImageDimension *= 0.75;
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
  CGFloat diameter = dimension;
  // -1 because the center pixel does not count for drawing
  CGFloat radius = (diameter - 1) / 2;
  // -1 because center coordinates are zero-based, but diameter is a size (i.e.
  // 1-based)
  CGFloat centerXAndY = (diameter - 1) / 2.0;
  CGPoint center = CGPointMake(centerXAndY, centerXAndY);

  CGSize imageSize = CGSizeMake(dimension, dimension);
  UIGraphicsBeginImageContext(imageSize);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);  // avoid anti-aliasing
  [UiUtilities drawCircleWithContext:context center:center radius:radius fill:true color:color];
  UIImage* stoneImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return stoneImage;
}

@end
