// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"
#import "../../utility/UIImageAdditions.h"


// This variable must be accessed via [BoardPositionCollectionViewCell boardPositionCollectionViewCellSize]
static CGSize boardPositionCollectionViewCellSize = { 0.0f, 0.0f };
static int horizontalSpacingSuperview = 0;
static int horizontalSpacingSiblings = 0;
static int verticalSpacingSuperview = 0;
static int verticalSpacingSiblings = 0;
static int stoneImageWidthAndHeight = 0;
static UIImage* blackStoneImage = nil;
static UIImage* whiteStoneImage = nil;
static UIColor* currentBoardPositionCellBackgroundColor = nil;
static UIColor* alternateCellBackgroundColor1 = nil;
static UIColor* alternateCellBackgroundColor2 = nil;
static UIColor* capturedStonesLabelBackgroundColor = nil;
static UIFont* largeFont = nil;
static UIFont* smallFont = nil;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionCollectionViewCell.
// -----------------------------------------------------------------------------
@interface BoardPositionCollectionViewCell()
@property(nonatomic, assign) bool offscreenMode;
@property(nonatomic, assign) UIImageView* stoneImageView;
@property(nonatomic, assign) UILabel* intersectionLabel;
@property(nonatomic, assign) UILabel* boardPositionLabel;
@property(nonatomic, assign) UILabel* capturedStonesLabel;
@property(nonatomic, retain) NSArray* dynamicAutoLayoutConstraints;
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
  _boardPosition = -1;             // don't use self, we don't want to trigger the setter
  self.dynamicAutoLayoutConstraints = nil;
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureView];
  // No content to setup, we first need a board position
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionCollectionViewCell object that is never
/// rendered on screen.
///
/// @note This initializer is privately used for the one-time pre-calculation
/// of the BoardPositionCollectionViewCell size.
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
  // Call designated initializer of superclass (UICollectionViewCell)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;
  self.offscreenMode = true;
  _boardPosition = 0;
  self.dynamicAutoLayoutConstraints = nil;
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureView];
  [self setupDummyContent];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionCollectionViewCell
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.stoneImageView = nil;
  self.intersectionLabel = nil;
  self.boardPositionLabel = nil;
  self.capturedStonesLabel = nil;
  self.dynamicAutoLayoutConstraints = nil;
  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.stoneImageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
  self.intersectionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.boardPositionLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  self.capturedStonesLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  [self addSubview:self.stoneImageView];
  [self addSubview:self.intersectionLabel];
  [self addSubview:self.boardPositionLabel];
  [self addSubview:self.capturedStonesLabel];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.stoneImageView.translatesAutoresizingMaskIntoConstraints = NO;
  self.intersectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionLabel.translatesAutoresizingMaskIntoConstraints = NO;
  self.capturedStonesLabel.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.stoneImageView, @"stoneImageView",
                                   self.intersectionLabel, @"intersectionLabel",
                                   self.boardPositionLabel, @"boardPositionLabel",
                                   self.capturedStonesLabel, @"capturedStonesLabel",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:|-%d-[stoneImageView]", horizontalSpacingSuperview],
                            [NSString stringWithFormat:@"H:[intersectionLabel]-%d-|", horizontalSpacingSuperview],
                            [NSString stringWithFormat:@"H:[boardPositionLabel]-%d-[capturedStonesLabel]-%d-|", horizontalSpacingSiblings, horizontalSpacingSuperview],
                            [NSString stringWithFormat:@"V:|-%d-[stoneImageView]-%d-|", verticalSpacingSuperview, verticalSpacingSuperview],
                            [NSString stringWithFormat:@"V:|-%d-[intersectionLabel]-%d-[boardPositionLabel]-%d-|", verticalSpacingSuperview, verticalSpacingSiblings, verticalSpacingSuperview],
                            [NSString stringWithFormat:@"V:[intersectionLabel]-%d-[capturedStonesLabel]-%d-|", verticalSpacingSiblings, verticalSpacingSuperview],
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self];

  [self updateDynamicAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializers.
// -----------------------------------------------------------------------------
- (void) configureView
{
  self.selectedBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.selectedBackgroundView.backgroundColor = currentBoardPositionCellBackgroundColor;

  self.intersectionLabel.font = largeFont;
  self.boardPositionLabel.font = smallFont;
  self.capturedStonesLabel.font = smallFont;

  self.capturedStonesLabel.textAlignment = NSTextAlignmentRight;
  self.capturedStonesLabel.textColor = capturedStonesLabelBackgroundColor;
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
    self.stoneImageView.image = nil;
    self.intersectionLabel.text = @"Start of the game";
    NSString* komiString = [NSString stringWithKomi:game.komi numericZeroValue:true];
    self.boardPositionLabel.text = [NSString stringWithFormat:@"Handicap: %1lu, Komi: %@", (unsigned long)game.handicapPoints.count, komiString];
    self.capturedStonesLabel.text = nil;
  }
  else
  {
    int moveIndex = self.boardPosition - 1;
    move = [game.moveModel moveAtIndex:moveIndex];
    self.stoneImageView.image = [self stoneImageForMove:move];
    self.intersectionLabel.text = [self intersectionLabelTextForMove:move];
    self.boardPositionLabel.text = [NSString stringWithFormat:@"Move %d", self.boardPosition];
    self.capturedStonesLabel.text = [self capturedStonesLabelTextForMove:move];
  }
  [self updateBackgroundColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the offscreen initializer.
// -----------------------------------------------------------------------------
- (void) setupDummyContent
{
  self.stoneImageView.image = blackStoneImage;
  // These must be longest strings that can possibly appear
  self.intersectionLabel.text = @"Start of the game";
  self.boardPositionLabel.text = @"Handicap: 9, Komi: 7½";
  // If there are captured stones, the board position label will have a much
  // shorter text than what we used above
  self.capturedStonesLabel.text = @"";
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
- (void) updateBackgroundColor
{
  if (0 == (self.boardPosition % 2))
    self.backgroundColor = alternateCellBackgroundColor1;
  else
    self.backgroundColor = alternateCellBackgroundColor2;
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setBoardPosition:(int)newValue
{
  if (_boardPosition == newValue)
    return;
  bool oldPositionIsGreaterThanZero = (_boardPosition > 0);
  bool newPositionIsGreaterThanZero = (newValue > 0);
  _boardPosition = newValue;

  // Optimization: Change Auto Layout constraints only if absolutely necessary
  if (oldPositionIsGreaterThanZero != newPositionIsGreaterThanZero)
    [self updateDynamicAutoLayoutConstraints];
  [self setupRealContent];
}

#pragma mark - Dynamic Auto Layout constraints

// -----------------------------------------------------------------------------
/// @brief Updates dynamic layout constraints according to the current content
/// of this cell.
// -----------------------------------------------------------------------------
- (void) updateDynamicAutoLayoutConstraints
{
  if (self.dynamicAutoLayoutConstraints)
    [self removeConstraints:self.dynamicAutoLayoutConstraints];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.stoneImageView, @"stoneImageView",
                                   self.intersectionLabel, @"intersectionLabel",
                                   self.boardPositionLabel, @"boardPositionLabel",
                                   nil];
  int stoneImageWidth = 0;
  int horizontalSpacingStoneImageView = 0;
  if (self.boardPosition > 0)
  {
    stoneImageWidth = stoneImageWidthAndHeight;
    horizontalSpacingStoneImageView = horizontalSpacingSiblings;
  }
  else
  {
    stoneImageWidth = 0;
    horizontalSpacingStoneImageView = 0;
  }

  NSMutableArray* visualFormats = [NSMutableArray array];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[stoneImageView(==%d)]", stoneImageWidth]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[stoneImageView]-%d-[intersectionLabel]", horizontalSpacingStoneImageView]];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[stoneImageView]-%d-[boardPositionLabel]", horizontalSpacingStoneImageView]];
  self.dynamicAutoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                    withViews:viewsDictionary
                                                                       inView:self];
}

#pragma mark - One-time view size calculation

// -----------------------------------------------------------------------------
/// @brief Returns the pre-calculated size of all
/// BoardPositionCollectionViewCell instances.
///
/// When this method is invoked the first time, it performs the necessary size
/// calculations.
// -----------------------------------------------------------------------------
+ (CGSize) boardPositionCollectionViewCellSize
{
  if (CGSizeEqualToSize(boardPositionCollectionViewCellSize, CGSizeZero))
    [BoardPositionCollectionViewCell setupStaticViewMetrics];
  return boardPositionCollectionViewCellSize;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for boardPositionCollectionViewCellSize().
// -----------------------------------------------------------------------------
+ (void) setupStaticViewMetrics
{
  // TODO xxx experiment with spacing
  horizontalSpacingSuperview = [UiElementMetrics horizontalSpacingSiblings];
  horizontalSpacingSiblings = [UiElementMetrics horizontalSpacingSiblings];
  verticalSpacingSuperview = [UiElementMetrics horizontalSpacingSiblings] / 2;
  verticalSpacingSiblings = 0;

  // TODO xxx experiment with size
  stoneImageWidthAndHeight = floor([UiElementMetrics tableViewCellContentViewHeight] * 0.7);
  CGSize stoneImageSize = CGSizeMake(stoneImageWidthAndHeight, stoneImageWidthAndHeight);
  blackStoneImage = [[[UIImage imageNamed:stoneBlackImageResource] imageByResizingToSize:stoneImageSize] retain];
  whiteStoneImage = [[[UIImage imageNamed:stoneWhiteImageResource] imageByResizingToSize:stoneImageSize] retain];

  currentBoardPositionCellBackgroundColor = [[UIColor darkTangerineColor] retain];
  alternateCellBackgroundColor1 = [[UIColor lightBlueColor] retain];
  alternateCellBackgroundColor2 = [[UIColor whiteColor] retain];
  capturedStonesLabelBackgroundColor = [[UIColor redColor] retain];

  // TODO xxx experiment with font sizes
  largeFont = [[UIFont systemFontOfSize:14] retain];
  smallFont = [[UIFont systemFontOfSize:10] retain];

  BoardPositionCollectionViewCell* offscreenView = [[[BoardPositionCollectionViewCell alloc] initOffscreenView] autorelease];
  [offscreenView layoutIfNeeded];
  boardPositionCollectionViewCellSize = [offscreenView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

@end
