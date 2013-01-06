// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionListController.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoMoveModel.h"
#import "../go/GoPlayer.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BoardPositionListController.
// -----------------------------------------------------------------------------
@interface BoardPositionListController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name ItemScrollViewDataSource protocol
//@{
- (int) numberOfItemsInItemScrollView:(ItemScrollView*)itemScrollView;
- (UIView*) itemScrollView:(ItemScrollView*)itemScrollView itemViewAtIndex:(int)index;
- (int) itemWidthInItemScrollView:(ItemScrollView*)itemScrollView;
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView;
//@}
/// @name Private helpers
//@{
- (void) setupConstantProperties;
- (void) setupLabelSize;
- (void) setupStoneImageSize;
- (void) setupStoneImages;
- (void) setupBoardPositionViewSize;
- (void) setupBoardPositionListViewSize;
- (void) setupBoardPositionListView;
- (NSString*) labelTextForMove:(GoMove*)move moveIndex:(int)moveIndex;
- (UILabel*) labelWithText:(NSString*)labelText;
- (UIImageView*) stoneImageViewForMove:(GoMove*)move;
- (UIView*) boardPositionViewForMove:(GoMove*)move;
- (UIImage*) stoneImageWithSize:(CGSize)size color:(UIColor*)color;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) int labelWidth;
@property(nonatomic, assign) int labelHeight;
@property(nonatomic, assign) int labelNumberOfLines;
@property(nonatomic, assign) int labelOneLineHeight;
@property(nonatomic, assign) CGRect labelFrame;
@property(nonatomic, assign) int stoneImageWidthAndHeight;
@property(nonatomic, retain) UIImage* blackStoneImage;
@property(nonatomic, retain) UIImage* whiteStoneImage;
@property(nonatomic, assign) CGRect stoneImageViewFrame;
@property(nonatomic, assign) int boardPositionViewWidth;
@property(nonatomic, assign) int boardPositionViewHeight;
/// @brief Number of pixels to use for internal padding of a board position view
/// (i.e. how much space should be between the left view edge and the label,
/// and the right view edge and the stone image).
@property(nonatomic, assign) int boardPositionViewHorizontalPadding;
/// @brief Number of pixels to use for internal spacing of a board position view
/// (i.e. how much space should be between the label and the stone image).
@property(nonatomic, assign) int boardPositionViewHorizontalSpacing;
@property(nonatomic, assign) CGRect boardPositionViewFrame;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) ItemScrollView* boardPositionListView;
@property(nonatomic, assign, readwrite) int boardPositionListViewWidth;
@property(nonatomic, assign, readwrite) int boardPositionListViewHeight;
//@}
@end


@implementation BoardPositionListController

@synthesize boardPositionListView;
@synthesize labelWidth;
@synthesize labelHeight;
@synthesize labelNumberOfLines;
@synthesize labelOneLineHeight;
@synthesize labelFrame;
@synthesize stoneImageWidthAndHeight;
@synthesize blackStoneImage;
@synthesize whiteStoneImage;
@synthesize stoneImageViewFrame;
@synthesize boardPositionViewWidth;
@synthesize boardPositionViewHeight;
@synthesize boardPositionViewHorizontalPadding;
@synthesize boardPositionViewHorizontalSpacing;
@synthesize boardPositionListViewWidth;
@synthesize boardPositionListViewHeight;
@synthesize boardPositionViewFrame;


// -----------------------------------------------------------------------------
/// @brief Returns the size of the font used to render text in the board
/// position list view.
// -----------------------------------------------------------------------------
+ (int) boardPositionListViewFontSize
{
  return 11;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionListController object.
///
/// @note This is the designated initializer of BoardPositionListController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // The order in which these methods are invoked is important
  [self setupConstantProperties];
  [self setupLabelSize];
  [self setupStoneImageSize];
  [self setupStoneImages];
  [self setupBoardPositionViewSize];
  [self setupBoardPositionListViewSize];
  [self setupBoardPositionListView];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  // KVO observing
  [[GoGame sharedGame].boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionListController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  self.boardPositionListView = nil;
  self.blackStoneImage = nil;
  self.whiteStoneImage = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a number of properties whose values are constant.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupConstantProperties
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.labelNumberOfLines = 2;
    self.boardPositionViewHorizontalPadding = 2;
    self.boardPositionViewHorizontalSpacing = 2;
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the label used in each board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupLabelSize
{
  // The text must include the word "Pass" because this is the longest string
  // that can possibly appear in the label of a board position view. The text
  // must also include a line break because the label of a board position view
  // has 2 lines.
  NSString* textToDetermineLabelSize = @"A\nPass";
  UIFont* font = [UIFont systemFontOfSize:[BoardPositionListController boardPositionListViewFontSize]];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize labelSize = [textToDetermineLabelSize sizeWithFont:font
                                          constrainedToSize:constraintSize
                                              lineBreakMode:UILineBreakModeWordWrap];
  self.labelWidth = labelSize.width;
  self.labelHeight = labelSize.height;
  self.labelOneLineHeight = self.labelHeight / self.labelNumberOfLines;
  self.labelFrame = CGRectMake(self.boardPositionViewHorizontalPadding,
                               0,
                               self.labelWidth,
                               self.labelHeight);
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the stone image used in each board position
/// view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImageSize
{
  self.stoneImageWidthAndHeight = floor(self.labelOneLineHeight * 0.75);

  CGFloat stoneImageViewX = (self.labelFrame.origin.x
                             + self.labelFrame.size.width
                             + self.boardPositionViewHorizontalSpacing);
  // Vertically center on the first line of the label.
  // Use floor() to prevent half-pixels, which would cause anti-aliasing when
  // drawing the image
  CGFloat stoneImageViewY = floor((self.labelOneLineHeight - self.stoneImageWidthAndHeight) / 2);
  self.stoneImageViewFrame = CGRectMake(stoneImageViewX,
                                        stoneImageViewY,
                                        self.stoneImageWidthAndHeight,
                                        self.stoneImageWidthAndHeight);
}

// -----------------------------------------------------------------------------
/// @brief Creates the stone images displayed in each board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupStoneImages
{
  self.blackStoneImage = [self stoneImageWithSize:self.stoneImageViewFrame.size
                                            color:[UIColor blackColor]];
  self.whiteStoneImage = [self stoneImageWithSize:self.stoneImageViewFrame.size
                                            color:[UIColor whiteColor]];
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of a board position view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionViewSize
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.boardPositionViewWidth = ((2 * self.boardPositionViewHorizontalPadding)
                                   + self.labelWidth
                                   + self.boardPositionViewHorizontalSpacing
                                   + self.stoneImageWidthAndHeight);
    self.boardPositionViewHeight = self.labelHeight;
    self.boardPositionViewFrame = CGRectMake(0, 0, self.boardPositionViewWidth, self.boardPositionViewHeight);
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates the size of the board position list view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListViewSize
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    // TODO xxx should align with Go board, also what about buttons?
    self.boardPositionListViewWidth = [UiElementMetrics screenWidth];
    self.boardPositionListViewHeight = self.boardPositionViewHeight;
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and sets up the board position list view.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListView
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    CGRect boardPositionListViewFrame = CGRectMake(0,
                                                   0,
                                                   self.boardPositionListViewWidth,
                                                   self.boardPositionListViewHeight);
    enum ItemScrollViewOrientation boardPositionListViewOrientation = ItemScrollViewOrientationHorizontal;
    self.boardPositionListView = [[ItemScrollView alloc] initWithFrame:boardPositionListViewFrame
                                                           orientation:boardPositionListViewOrientation];
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [oldGame.boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [newGame.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [self.boardPositionListView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self.boardPositionListView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) numberOfItemsInItemScrollView:(ItemScrollView*)itemScrollView
{
  return [GoGame sharedGame].moveModel.numberOfMoves;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) itemWidthInItemScrollView:(ItemScrollView*)itemScrollView
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    return self.boardPositionViewWidth;
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView
{
  // TODO xxx implement for iPad; take orientation into account
  NSException* exception = [NSException exceptionWithName:NSGenericException
                                                   reason:@"Not implemented yet"
                                                 userInfo:nil];
  @throw exception;
}

// -----------------------------------------------------------------------------
/// @brief ItemScrollViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UIView*) itemScrollView:(ItemScrollView*)itemScrollView itemViewAtIndex:(int)index
{
  GoMove* move = [[GoGame sharedGame].moveModel moveAtIndex:index];
  NSString* labelText = [self labelTextForMove:move moveIndex:index];
  UILabel* label = [self labelWithText:labelText];
  UIImageView* stoneImageView = [self stoneImageViewForMove:move];
  UIView* boardPositionView = [self boardPositionViewForMove:move];
  [boardPositionView addSubview:label];
  [boardPositionView addSubview:stoneImageView];
  return boardPositionView;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for itemScrollView:itemViewAtIndex:().
// -----------------------------------------------------------------------------
- (NSString*) labelTextForMove:(GoMove*)move moveIndex:(int)moveIndex
{
  NSString* vertexString;
  if (GoMoveTypePlay == move.type)
    vertexString = move.point.vertex.string;
  else
    vertexString = @"Pass";
  int moveNumber = moveIndex + 1;
  return [NSString stringWithFormat:@"%d\n%@", moveNumber, vertexString];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for itemScrollView:itemViewAtIndex:().
// -----------------------------------------------------------------------------
- (UILabel*) labelWithText:(NSString*)labelText
{
  UILabel* label = [[[UILabel alloc] initWithFrame:self.labelFrame] autorelease];
  label.font = [UIFont systemFontOfSize:[BoardPositionListController boardPositionListViewFontSize]];
  [label setNumberOfLines:self.labelNumberOfLines];
  label.backgroundColor = [UIColor clearColor];
  label.text = labelText;
  return label;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for itemScrollView:itemViewAtIndex:().
// -----------------------------------------------------------------------------
- (UIImageView*) stoneImageViewForMove:(GoMove*)move
{
  UIImage* stoneImage;
  if (move.player.black)
    stoneImage = self.blackStoneImage;
  else
    stoneImage = self.whiteStoneImage;
  UIImageView* stoneImageView = [[[UIImageView alloc] initWithImage:stoneImage] autorelease];
  stoneImageView.frame = self.stoneImageViewFrame;
  return stoneImageView;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for itemScrollView:itemViewAtIndex:().
// -----------------------------------------------------------------------------
- (UIView*) boardPositionViewForMove:(GoMove*)move
{
  UIView* boardPositionView = [[[UIView alloc] initWithFrame:self.boardPositionViewFrame] autorelease];
  if (move.player.black)
    boardPositionView.backgroundColor = [UIColor whiteColor];
  else
    boardPositionView.backgroundColor = [UIColor lightGrayColor];
  return boardPositionView;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for stoneImageViewForMove:().
// -----------------------------------------------------------------------------
- (UIImage*) stoneImageWithSize:(CGSize)size color:(UIColor*)color
{
  CGFloat diameter = size.width;
  // -1 because the center pixel does not count for drawing
  CGFloat radius = (diameter - 1) / 2;
  // -1 because center coordinates are zero-based, but diameter is a size (i.e.
  // 1-based)
  CGFloat centerXAndY = (diameter - 1) / 2.0;
  CGPoint center = CGPointMake(centerXAndY, centerXAndY);

  UIGraphicsBeginImageContext(size);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextTranslateCTM(context, gHalfPixel, gHalfPixel);  // avoid anti-aliasing
  [UiUtilities drawCircleWithContext:context center:center radius:radius fill:true color:color];
  UIImage* stoneImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return stoneImage;
}

@end
