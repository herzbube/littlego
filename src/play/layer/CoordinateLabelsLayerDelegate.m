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
#import "CoordinateLabelsLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"

// System includes
#import <QuartzCore/QuartzCore.h>


@implementation CoordinateLabelsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CoordinateLabelsLayerDelegate object.
///
/// @note This is the designated initializer of CoordinateLabelsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)layer
             metrics:(PlayViewMetrics*)metrics
               model:(PlayViewModel*)playViewModel
                axis:(enum CoordinateLabelAxis)axis
                view:(UIView*)view
{
  // Call designated initializer of superclass (PlayViewLayerDelegateBase)
  self = [super initWithLayer:layer metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  self.coordinateLabelAxis = axis;
  self.coordinateLabelView = view;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case PVLDEventRectangleChanged:
    case PVLDEventGoGameStarted:
    {
      self.layer.frame = self.coordinateLabelView.bounds;
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
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  NSString* textToDetermineSize = @"19";
  UIFont* currentCoordinateLabelFont = [UIFont systemFontOfSize:14];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize textSize = [textToDetermineSize sizeWithFont:currentCoordinateLabelFont
                                    constrainedToSize:constraintSize
                                        lineBreakMode:UILineBreakModeWordWrap];

  CGRect coordinateLabelRect = CGRectZero;
  coordinateLabelRect.size = textSize;
  if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
  {
    coordinateLabelRect.origin.x = (self.playViewMetrics.topLeftPointX
                                    - floor(textSize.width / 2));
    coordinateLabelRect.origin.y = floor((self.playViewMetrics.coordinateLabelStripWidth - textSize.height) / 2);
  }
  else
  {
    coordinateLabelRect.origin.x = floor((self.playViewMetrics.coordinateLabelStripWidth - textSize.width) / 2);
    coordinateLabelRect.origin.y = (self.playViewMetrics.topLeftPointY
                                    + (self.playViewMetrics.numberOfCells * self.playViewMetrics.pointDistance)
                                    - floor(textSize.height / 2));
  }

  // Drawing the label in white makes it stand out nicely from the wooden
  // background. The drop shadow is essential so that the label is visible even
  // if it overlays a white stone.
  CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
  CGContextSetShadowWithColor(context, CGSizeMake(1.0, 1.0), 5.0, [UIColor blackColor].CGColor);

  // NSString's drawInRect:withFont:lineBreakMode:alignment: is a UIKit drawing
  // function. To make it work we need to push our layer drawing context to the
  // top of the UIKit context stack (which is currently empty).
  UIGraphicsPushContext(context);
  GoPoint* point = [[GoGame sharedGame].board pointAtVertex:@"A1"];
  while (point)
  {
    NSString* coordinateLabelText;
    if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
      coordinateLabelText = point.vertex.letterAxisCompound;
    else
      coordinateLabelText = point.vertex.numberAxisCompound;
    [coordinateLabelText drawInRect:coordinateLabelRect
                           withFont:currentCoordinateLabelFont
                      lineBreakMode:UILineBreakModeWordWrap
                          alignment:NSTextAlignmentCenter];

    if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
    {
      point = point.right;
      coordinateLabelRect.origin.x += self.playViewMetrics.pointDistance;
    }
    else
    {
      point = point.above;
      coordinateLabelRect.origin.y -= self.playViewMetrics.pointDistance;
    }
  }
  UIGraphicsPopContext();  // balance UIGraphicsPushContext()
}

@end
