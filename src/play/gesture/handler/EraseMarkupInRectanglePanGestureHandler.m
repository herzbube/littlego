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
#import "EraseMarkupInRectanglePanGestureHandler.h"
#import "../../boardview/BoardView.h"
#import "../../gameaction/GameActionManager.h"
#import "../../model/MarkupModel.h"


NS_ASSUME_NONNULL_BEGIN

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EraseMarkupInRectanglePanGestureHandler.
// -----------------------------------------------------------------------------
@interface EraseMarkupInRectanglePanGestureHandler()
@property(nonatomic, assign) BoardView* boardView;
@property(nonatomic, assign) MarkupModel* markupModel;
@end


@implementation EraseMarkupInRectanglePanGestureHandler

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a EraseMarkupInRectanglePanGestureHandler object.
///
/// @note This is the designated initializer of
/// EraseMarkupInRectanglePanGestureHandler.
// -----------------------------------------------------------------------------
- (id) initWithBoardView:(BoardView*)boardView markupModel:(MarkupModel*)markupModel
{
  // Call designated initializer of superclass (PanGestureHandler)
  self = [super init];
  if (! self)
    return nil;

  self.boardView = boardView;
  self.markupModel = markupModel;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// EraseMarkupInRectanglePanGestureHandler object.
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
  if (recognizerState == UIGestureRecognizerStateEnded || recognizerState == UIGestureRecognizerStateCancelled)
  {
    [self.boardView updateSelectionRectangleFromPoint:nil
                                              toPoint:nil];

    NSArray* selectionRectangleInformation = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewSelectionRectangleDidChange
                                                        object:selectionRectangleInformation];

    if (recognizerState == UIGestureRecognizerStateEnded && gestureStartPoint && gestureCurrentPoint)
    {
      [[GameActionManager sharedGameActionManager] handleMarkupEditingEraseMarkupInRectangleFromPoint:gestureStartPoint
                                                                                              toPoint:gestureCurrentPoint];
    }
  }
  else
  {
    [self.boardView updateSelectionRectangleFromPoint:gestureStartPoint
                                              toPoint:gestureCurrentPoint];

    NSArray* selectionRectangleInformation = (gestureStartPoint && gestureCurrentPoint)
      ? @[gestureStartPoint, gestureCurrentPoint]
      : @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewSelectionRectangleDidChange
                                                        object:selectionRectangleInformation];
  }
}

@end

NS_ASSUME_NONNULL_END
