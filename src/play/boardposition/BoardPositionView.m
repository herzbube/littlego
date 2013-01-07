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
#import "BoardPositionView.h"
#import "BoardPositionViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoMoveModel.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for BoardPositionView.
// -----------------------------------------------------------------------------
@interface BoardPositionView()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (void) setupView;
- (NSString*) labelTextForMove:(GoMove*)move moveIndex:(int)moveIndex;
- (UILabel*) labelWithText:(NSString*)labelText;
- (UIImageView*) stoneImageViewForMove:(GoMove*)move;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) int boardPosition;
@property(nonatomic, assign) BoardPositionViewMetrics* viewMetrics;
//@}
@end


@implementation BoardPositionView

@synthesize boardPosition;
@synthesize viewMetrics;


// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionView object that represents the board
/// position identified by @a aBoardPosition and uses @a aViewMetrics to obtain
/// sizes and other attributes that define the view's layout.
///
/// @note This is the designated initializer of BoardPositionView.
// -----------------------------------------------------------------------------
- (id) initWithBoardPosition:(int)aBoardPosition viewMetrics:(BoardPositionViewMetrics*)aViewMetrics
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
  if (! self)
    return nil;

  self.boardPosition = aBoardPosition;
  self.viewMetrics = aViewMetrics;

  [self setupView];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionView
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.viewMetrics = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the layout of this BoardPositionView.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupView
{
  self.frame = self.viewMetrics.boardPositionViewFrame;

  if (0 == self.boardPosition)
  {
    // TODO xxx do stuff for board position 0
  }
  else
  {
    int moveIndex = self.boardPosition - 1;
    GoMove* move = [[GoGame sharedGame].moveModel moveAtIndex:moveIndex];
    NSString* labelText = [self labelTextForMove:move moveIndex:moveIndex];
    UILabel* label = [self labelWithText:labelText];
    UIImageView* stoneImageView = [self stoneImageViewForMove:move];
    [self addSubview:label];
    [self addSubview:stoneImageView];

    if (move.player.black)
      self.backgroundColor = [UIColor whiteColor];
    else
      self.backgroundColor = [UIColor lightGrayColor];
  }
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for setupView().
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
/// @brief This is an internal helper for setupView().
// -----------------------------------------------------------------------------
- (UILabel*) labelWithText:(NSString*)labelText
{
  UILabel* label = [[[UILabel alloc] initWithFrame:self.viewMetrics.labelFrame] autorelease];
  label.font = [UIFont systemFontOfSize:[BoardPositionViewMetrics boardPositionViewFontSize]];
  [label setNumberOfLines:self.viewMetrics.labelNumberOfLines];
  label.backgroundColor = [UIColor clearColor];
  label.text = labelText;
  return label;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper for setupView().
// -----------------------------------------------------------------------------
- (UIImageView*) stoneImageViewForMove:(GoMove*)move
{
  UIImage* stoneImage;
  if (move.player.black)
    stoneImage = self.viewMetrics.blackStoneImage;
  else
    stoneImage = self.viewMetrics.whiteStoneImage;
  UIImageView* stoneImageView = [[[UIImageView alloc] initWithImage:stoneImage] autorelease];
  stoneImageView.frame = self.viewMetrics.stoneImageViewFrame;
  return stoneImageView;
}

@end
