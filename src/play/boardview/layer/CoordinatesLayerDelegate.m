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
#import "CoordinatesLayerDelegate.h"
#import "BoardViewDrawingHelper.h"
#import "../../model/BoardViewMetrics.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for CoordinatesLayerDelegate.
// -----------------------------------------------------------------------------
@interface CoordinatesLayerDelegate()
@property(nonatomic, retain) UIColor* textColor;
@property(nonatomic, retain) NSShadow* shadow;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@end


@implementation CoordinatesLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CoordinatesLayerDelegate object.
///
/// @note This is the designated initializer of CoordinatesLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile
            metrics:(BoardViewMetrics*)metrics
               axis:(enum CoordinateLabelAxis)axis
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;
  self.coordinateLabelAxis = axis;
  // Drawing the label in white makes it stand out nicely from the wooden
  // background. The drop shadow is essential so that the label is visible even
  // if it overlays a white stone.
  self.textColor = [UIColor whiteColor];
  self.shadow = [[[NSShadow alloc] init] autorelease];
  self.shadow.shadowColor = [UIColor blackColor];
  self.shadow.shadowBlurRadius = 5.0;
  self.shadow.shadowOffset = CGSizeMake(1.0, 1.0);
  self.paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
  self.paragraphStyle.alignment = NSTextAlignmentCenter;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CoordinatesLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.textColor = nil;
  self.shadow = nil;
  self.paragraphStyle = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case BVLDEventBoardGeometryChanged:
    case BVLDEventBoardSizeChanged:
    case BVLDEventInvalidateContent:
    {
      self.dirty = true;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  UIFont* coordinateLabelFont = self.boardViewMetrics.coordinateLabelFont;
  if (! coordinateLabelFont)
    return;

  CGRect tileRect = [BoardViewDrawingHelper canvasRectForTile:self.tile
                                                      metrics:self.boardViewMetrics];

  NSDictionary* textAttributes = @{ NSFontAttributeName : coordinateLabelFont,
                                    NSForegroundColorAttributeName : self.textColor,
                                    NSShadowAttributeName: self.shadow,
                                    NSParagraphStyleAttributeName : self.paragraphStyle };

  CGRect coordinateLabelRect = CGRectZero;
  coordinateLabelRect.size = self.boardViewMetrics.coordinateLabelMaximumSize;
  if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
  {
    coordinateLabelRect.origin.x = (self.boardViewMetrics.topLeftPointX
                                    - floor(self.boardViewMetrics.coordinateLabelMaximumSize.width / 2));
    coordinateLabelRect.origin.y = floor((self.boardViewMetrics.coordinateLabelStripWidth
                                          - self.boardViewMetrics.coordinateLabelMaximumSize.height) / 2);
  }
  else
  {
    coordinateLabelRect.origin.x = floor((self.boardViewMetrics.coordinateLabelStripWidth
                                          - self.boardViewMetrics.coordinateLabelMaximumSize.width) / 2);
    coordinateLabelRect.origin.y = (self.boardViewMetrics.topLeftPointY
                                    + (self.boardViewMetrics.numberOfCells * self.boardViewMetrics.pointDistance)
                                    - floor(self.boardViewMetrics.coordinateLabelMaximumSize.height / 2));
  }

  // NSString's drawInRect:withAttributes: is a UIKit drawing function. To make
  // it work we need to push our layer drawing context to the top of the UIKit
  // context stack (which is currently empty).
  UIGraphicsPushContext(context);
  GoPoint* point = [[GoGame sharedGame].board pointAtVertex:@"A1"];
  while (point)
  {
    if (CGRectIntersectsRect(tileRect, coordinateLabelRect))
    {
      CGRect drawingRect = [BoardViewDrawingHelper drawingRectFromCanvasRect:coordinateLabelRect
                                                              inTileWithRect:tileRect];

      NSString* coordinateLabelText;
      if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
        coordinateLabelText = point.vertex.letterAxisCompound;
      else
        coordinateLabelText = point.vertex.numberAxisCompound;
      [coordinateLabelText drawInRect:drawingRect withAttributes:textAttributes];
    }

    if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
    {
      point = point.right;
      coordinateLabelRect.origin.x += self.boardViewMetrics.pointDistance;
    }
    else
    {
      point = point.above;
      coordinateLabelRect.origin.y -= self.boardViewMetrics.pointDistance;
    }
  }
  UIGraphicsPopContext();  // balance UIGraphicsPushContext()
}

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayCoordinateLabels
{
  if (! self.boardViewMetrics.coordinateLabelFont)
    return false;
  else
    return self.boardViewMetrics.displayCoordinates;
}

@end
