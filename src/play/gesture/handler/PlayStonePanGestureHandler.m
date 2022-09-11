// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayStonePanGestureHandler.h"
#import "../../boardview/BoardView.h"
#import "../../gameaction/GameActionManager.h"
#import "../../../go/GoGame.h"


NS_ASSUME_NONNULL_BEGIN

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayStonePanGestureHandler.
// -----------------------------------------------------------------------------
@interface PlayStonePanGestureHandler()
@property(nonatomic, assign) BoardView* boardView;
@end


@implementation PlayStonePanGestureHandler

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayStonePanGestureHandler object.
///
/// @note This is the designated initializer of PlayStonePanGestureHandler.
// -----------------------------------------------------------------------------
- (id) initWithBoardView:(BoardView*)boardView
{
  // Call designated initializer of superclass (PanGestureHandler)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = boardView;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayStonePanGestureHandler
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - PanGestureHandler overrides

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
                    gestureStartPoint:(GoPoint*)gestureStartPoint
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (void) handleGestureWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                               gestureStartPoint:(GoPoint*)gestureStartPoint
                             gestureCurrentPoint:(nullable GoPoint*)gestureCurrentPoint
{
  bool isLegalMove = false;
  enum GoMoveIsIllegalReason illegalReason = GoMoveIsIllegalReasonUnknown;
  if (gestureCurrentPoint)
    isLegalMove = [[GoGame sharedGame] isLegalMove:gestureCurrentPoint isIllegalReason:&illegalReason];

  if (recognizerState == UIGestureRecognizerStateEnded || recognizerState == UIGestureRecognizerStateCancelled)
  {
    [self.boardView moveCrossHairWithStoneTo:nil
                                 isLegalMove:true
                             isIllegalReason:illegalReason];

    NSArray* stonePlacementInformation = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewStoneLocationDidChange
                                                        object:stonePlacementInformation];

    if (recognizerState == UIGestureRecognizerStateEnded && isLegalMove)
    {
      [[GameActionManager sharedGameActionManager] playAtIntersection:gestureCurrentPoint];
    }
  }
  else
  {
    [self.boardView moveCrossHairWithStoneTo:gestureCurrentPoint
                                 isLegalMove:isLegalMove
                             isIllegalReason:illegalReason];

    NSArray* stonePlacementInformation = gestureCurrentPoint
      ? @[gestureCurrentPoint, [NSNumber numberWithBool:isLegalMove], [NSNumber numberWithInt:illegalReason]]
      : @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewStoneLocationDidChange
                                                        object:stonePlacementInformation];
  }
}

@end

NS_ASSUME_NONNULL_END
