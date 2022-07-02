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
#import "PlaceMarkupConnectionPanGestureHandler.h"
#import "../../boardview/BoardView.h"
#import "../../gameaction/GameActionManager.h"
#import "../../model/MarkupModel.h"
#import "../../../utility/MarkupUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlaceMarkupConnectionPanGestureHandler.
// -----------------------------------------------------------------------------
@interface PlaceMarkupConnectionPanGestureHandler()
@property(nonatomic, assign) BoardView* boardView;
@property(nonatomic, assign) MarkupModel* markupModel;
@end


@implementation PlaceMarkupConnectionPanGestureHandler

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a PlaceMarkupConnectionPanGestureHandler object.
///
/// @note This is the designated initializer of
/// PlaceMarkupConnectionPanGestureHandler.
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
/// PlaceMarkupConnectionPanGestureHandler object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.boardView = nil;
  self.markupModel = nil;

  [super dealloc];
}

#pragma mark - PanGestureHandler overrides

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
                    gestureStartPoint:(GoPoint*)startPoint
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief PanGestureHandler method.
// -----------------------------------------------------------------------------
- (void) handleGestureWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                               gestureStartPoint:(GoPoint*)gestureStartPoint
                             gestureCurrentPoint:(GoPoint*)gestureCurrentPoint
{
  enum GoMarkupConnection connection = [MarkupUtilities connectionForMarkupType:self.markupModel.markupType];

  if (recognizerState == UIGestureRecognizerStateEnded || recognizerState == UIGestureRecognizerStateCancelled)
  {
    [self.boardView moveMarkupConnection:connection
                          withStartPoint:nil
                              toEndPoint:nil];

    NSArray* connectionInformation = @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewMarkupLocationDidChange
                                                        object:connectionInformation];

    if (recognizerState == UIGestureRecognizerStateEnded && gestureStartPoint && gestureCurrentPoint && gestureStartPoint != gestureCurrentPoint)
    {
      [[GameActionManager sharedGameActionManager] placeMarkupConnection:connection
                                                               fromPoint:gestureStartPoint
                                                                 toPoint:gestureCurrentPoint
                                                          markupWasMoved:false];
    }
  }
  else
  {
    [self.boardView moveMarkupConnection:connection
                          withStartPoint:gestureStartPoint
                              toEndPoint:gestureCurrentPoint];

    NSArray* connectionInformation = (gestureStartPoint && gestureCurrentPoint)
      ? @[[NSNumber numberWithInt:self.markupModel.markupType], gestureStartPoint, gestureCurrentPoint]
      : @[];
    [[NSNotificationCenter defaultCenter] postNotificationName:boardViewMarkupLocationDidChange
                                                        object:connectionInformation];
  }
}

@end
