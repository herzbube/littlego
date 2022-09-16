// -----------------------------------------------------------------------------
// Copyright 2014-2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardView.h"
#import "BoardViewAccessibility.h"
#import "BoardTileView.h"
#import "../model/BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../go/GoGame.h"
#import "../../go/GoUtilities.h"
#import "../../main/ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardView.
// -----------------------------------------------------------------------------
@interface BoardView()
@property(nonatomic, retain) GoPoint* crossHairPoint;
@property(nonatomic, assign) bool crossHairPointIsLegalMove;
@property(nonatomic, retain) GoPoint* connectionStartPoint;
@property(nonatomic, retain) GoPoint* connectionEndPoint;
@property(nonatomic, retain) GoPoint* selectionRectangleFromPoint;
@property(nonatomic, retain) GoPoint* selectionRectangleToPoint;
@property(nonatomic, assign) float crossHairPointDistanceFromFinger;
@property(nonatomic, retain) BoardViewAccessibility* boardViewAccessibility;
@end


@implementation BoardView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (TiledScrollView)
  self = [super initWithFrame:rect tileViewClass:[BoardTileView class]];
  if (! self)
    return nil;

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;
  self.connectionStartPoint = nil;
  self.connectionEndPoint = nil;
  self.selectionRectangleFromPoint = nil;
  self.selectionRectangleToPoint = nil;
  self.boardViewAccessibility = [[[BoardViewAccessibility alloc] initWithBoardView:self] autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.crossHairPoint = nil;
  self.connectionStartPoint = nil;
  self.connectionEndPoint = nil;
  self.selectionRectangleFromPoint = nil;
  self.selectionRectangleToPoint = nil;
  self.boardViewAccessibility = nil;

  [super dealloc];
}

#pragma mark - Gesture handling

// -----------------------------------------------------------------------------
/// @brief Returns a BoardViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// BoardViewIntersectionNull if there is no "closest" intersection.
///
/// @see BoardViewMetrics::intersectionNear:() for details.
// -----------------------------------------------------------------------------
- (BoardViewIntersection) intersectionNear:(CGPoint)coordinates
{
  BoardViewMetrics* metrics = [ApplicationDelegate sharedDelegate].boardViewMetrics;
  return [metrics intersectionNear:coordinates];
}

#pragma mark - Cross-hair handling

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point.
/// @a isLegalMove specifies whether an actual play move at the intersection
/// would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairToPoint:(GoPoint*)point
{
  if (self.crossHairPoint == point)
    return;

  self.crossHairPoint = point;

  [self notifyTiles:BVLDEventCrossHairChanged eventInfo:point];
}

#pragma mark - Play stone handling

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair plus stone being played to the intersection
/// identified by @a point. @a isLegalMove specifies whether an actual play move
/// at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairWithStoneTo:(GoPoint*)point
                      isLegalMove:(bool)isLegalMove
                  isIllegalReason:(enum GoMoveIsIllegalReason)illegalReason
{
  if (self.crossHairPoint == point && self.crossHairPointIsLegalMove == isLegalMove)
    return;

  self.crossHairPointIsLegalMove = isLegalMove;
  self.crossHairPoint = point;

  [self notifyTiles:BVLDEventCrossHairChanged eventInfo:point];
  [self notifyTiles:BVLDEventPlayStoneDidChange eventInfo:point];
}

#pragma mark - Markup handling

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair plus the symbol markup element @a symbol to the
/// intersection identified by @a point.
// -----------------------------------------------------------------------------
- (void) moveCrossHairWithSymbol:(enum GoMarkupSymbol)symbol
                         toPoint:(GoPoint*)point
{
  if (self.crossHairPoint == point)
    return;

  self.crossHairPoint = point;

  NSArray* eventInfo;
  if (point)
    eventInfo = @[[NSNumber numberWithInt:symbol], point];
  else
    eventInfo = @[];

  [self notifyTiles:BVLDEventCrossHairChanged eventInfo:point];
  [self notifyTiles:BVLDEventMarkupSymbolDidMove eventInfo:eventInfo];
}

// -----------------------------------------------------------------------------
/// @brief Moves the interactively drawn connection of type @a connection so
/// that it is drawn between the points @a startPoint and @a endPoint. If either
/// or both GoPoint parameters is @e nil the connection is removed.
// -----------------------------------------------------------------------------
- (void) moveMarkupConnection:(enum GoMarkupConnection)connection
               withStartPoint:(GoPoint*)startPoint
                   toEndPoint:(GoPoint*)endPoint
{
  if (self.connectionStartPoint == startPoint && self.connectionEndPoint == endPoint)
    return;

  self.connectionStartPoint = startPoint;
  self.connectionEndPoint = endPoint;

  NSArray* eventInfo;
  if (startPoint && endPoint)
    eventInfo = @[[NSNumber numberWithInt:connection], startPoint, endPoint];
  else
    eventInfo = @[];

  [self notifyTiles:BVLDEventMarkupConnectionDidMove eventInfo:eventInfo];
}

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair plus the label markup element @a label with
/// the label text @a labelText to the intersection identified by @a point.
// -----------------------------------------------------------------------------
- (void) moveCrossHairWithLabel:(enum GoMarkupLabel)label
                      labelText:(NSString*)labelText
                        toPoint:(GoPoint*)point
{
  if (self.crossHairPoint == point)
    return;

  self.crossHairPoint = point;

  enum BoardViewLayerDelegateEvent event = label == GoMarkupLabelLabel ? BVLDEventMarkupLabelDidMove : BVLDEventMarkupMarkerDidMove;
  NSArray* eventInfo;
  if (point)
    eventInfo = @[[NSNumber numberWithInt:label], labelText, point];
  else
    eventInfo = @[];

  [self notifyTiles:BVLDEventCrossHairChanged eventInfo:point];
  [self notifyTiles:event eventInfo:eventInfo];
}

// -----------------------------------------------------------------------------
/// @brief Updates the interactively drawn selection rectangle so that it is
/// drawn with the diagonally opposite corner points @a fromPoint and
/// @a toPoint. If either or both GoPoint parameters is @e nil the selection
/// rectangle is removed.
// -----------------------------------------------------------------------------
- (void) updateSelectionRectangleFromPoint:(GoPoint*)fromPoint
                                   toPoint:(GoPoint*)toPoint
{
  if (self.selectionRectangleFromPoint == fromPoint && self.selectionRectangleToPoint == toPoint)
    return;

  self.selectionRectangleFromPoint = fromPoint;
  self.selectionRectangleToPoint = toPoint;

  NSArray* eventInfo;
  if (fromPoint && toPoint)
  {
    NSArray* pointsInSelectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:fromPoint
                                                                           oppositeCornerPoint:toPoint
                                                                                        inGame:[GoGame sharedGame]];
    eventInfo = @[fromPoint, toPoint, pointsInSelectionRectangle];
  }
  else
  {
    eventInfo = @[];
  }

  [self notifyTiles:BVLDEventSelectionRectangleDidChange eventInfo:eventInfo];
}

#pragma mark - UIAccessibilityElement overrides

// -----------------------------------------------------------------------------
/// @brief UIAccessibilityElement method.
// -----------------------------------------------------------------------------
- (BOOL) isAccessibilityElement
{
  // Because BoardView is an UIAccessibilityContainer
  return NO;
}

#pragma mark - UIAccessibilityContainer overrides

// -----------------------------------------------------------------------------
/// @brief UIAccessibilityContainer method.
// -----------------------------------------------------------------------------
- (NSArray*) accessibilityElements
{
  return self.boardViewAccessibility.accessibilityElements;
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Notifies all subviews that are BoardTileView objects that @a event
/// has occurred. The event info object supplied to the tile view is
/// @a eventInfo. Also triggers each subview's delayed drawing mechanism.
// -----------------------------------------------------------------------------
- (void) notifyTiles:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id subview in [self.tileContainerView subviews])
  {
    if (! [subview isKindOfClass:[BoardTileView class]])
      continue;

    BoardTileView* tileView = subview;
    [tileView notifyLayerDelegates:event eventInfo:eventInfo];
    [tileView delayedDrawLayers];
  }
}

@end
