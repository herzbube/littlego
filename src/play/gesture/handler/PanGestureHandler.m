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
#import "PanGestureHandler.h"
#import "EraseMarkupInRectanglePanGestureHandler.h"
#import "MoveMarkupPanGestureHandler.h"
#import "PlaceMarkupConnectionPanGestureHandler.h"
#import "PlayStonePanGestureHandler.h"


@implementation PanGestureHandler

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a newly created
/// PanGestureHandler object that can handle pan gestures required by
/// @a uiAreaPlayMode and @a markupTool. If no pan gesture is possible for the
/// combination then this method returns @e nil. If a PanGestureHandler object
/// is created it is configured with  @a markupModel, @a boardView and/or
/// @a boardViewMetrics.
// -----------------------------------------------------------------------------
+ (PanGestureHandler*) panGestureHandlerWithUiAreaPlayMode:(enum UIAreaPlayMode)uiAreaPlayMode
                                                markupTool:(enum MarkupTool)markupTool
                                               markupModel:(MarkupModel*)markupModel
                                                 boardView:(BoardView*)boardView
                                          boardViewMetrics:(BoardViewMetrics*)boardViewMetrics
{
  PanGestureHandler* panGestureHandler = nil;

  switch (uiAreaPlayMode)
  {
    case UIAreaPlayModePlay:
    {
      panGestureHandler = [[[PlayStonePanGestureHandler alloc] initWithBoardView:boardView] autorelease];
      break;
    }
    case UIAreaPlayModeEditMarkup:
    {
      switch (markupTool)
      {
        case MarkupToolSymbol:
        case MarkupToolMarker:
        case MarkupToolLabel:
        {
          panGestureHandler = [[[MoveMarkupPanGestureHandler alloc] initWithBoardView:boardView markupModel:markupModel boardViewMetrics:boardViewMetrics] autorelease];
          break;
        }
        case MarkupToolConnection:
        {
          panGestureHandler = [[[PlaceMarkupConnectionPanGestureHandler alloc] initWithBoardView:boardView markupModel:markupModel] autorelease];
          break;
        }
        case MarkupToolEraser:
        {
          panGestureHandler = [[[EraseMarkupInRectanglePanGestureHandler alloc] initWithBoardView:boardView markupModel:markupModel] autorelease];
          break;
        }
        default:
        {
          break;
        }
      }
      break;
    }
    default:
    {
      break;
    }
  }

  return panGestureHandler;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a PanGestureHandler object.
///
/// @note This is the designated initializer of PanGestureHandler.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PanGestureHandler object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - Default implementations of base class interface

// -----------------------------------------------------------------------------
/// @brief Returns @e YES if @a gestureRecognizer should begin with the panning
/// gesture. Returns @e NO if @a gestureRecognizer should not begin with the
/// gesture. The gesture start location is @a gestureStartPoint, which is
/// guaranteed not to be @e nil.
///
/// This default implementation exists only to prevent an "incomplete
/// implementation" compiler warning. It always throws an exception and must be
/// overridden by subclasses.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
                    gestureStartPoint:(GoPoint*)startPoint
{
  DDLogError(@"%@: No override for gestureRecognizerShouldBegin:gestureStartPoint:()", [self shortDescription]);
  [self doesNotRecognizeSelector:_cmd];
  return NO;
}

// -----------------------------------------------------------------------------
/// @brief Handles the most recent change in the panning gesture. The gesture
/// is currently in state @a recognizerState. The gesture start location is
/// @a gestureStartPoint, which is guaranteed not to be @e nil. The current
/// gesture location is @a gestureCurrentPoint, which can be @e nil if the
/// gesture is currently not within the board view.
///
/// This default implementation exists only to prevent an "incomplete
/// implementation" compiler warning. It always throws an exception and must be
/// overridden by subclasses.
// -----------------------------------------------------------------------------
- (void) handleGestureWithGestureRecognizerState:(UIGestureRecognizerState)recognizerState
                               gestureStartPoint:(GoPoint*)gestureStartPoint
                             gestureCurrentPoint:(GoPoint*)gestureCurrentPoint
{
  DDLogError(@"%@: No override for handleGestureWithGestureRecognizerState:gestureStartPoint:gestureCurrentPoint:()", [self shortDescription]);
  [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Protected helper

// -----------------------------------------------------------------------------
/// @brief Returns a short description for this PanGestureHandler object that
/// consists only of the class name and the object's address in memory.
///
/// This method is useful for logging a short but unique reference to the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) shortDescription
{
  return [NSString stringWithFormat:@"%@(%p)", NSStringFromClass([self class]), self];
}

@end
