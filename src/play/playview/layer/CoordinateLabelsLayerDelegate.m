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
#import "../../model/PlayViewModel.h"
#import "../../../go/GoBoard.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoVertex.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
// CoordinateLabelsLayerDelegate.
// -----------------------------------------------------------------------------
@interface CoordinateLabelsLayerDelegate()
@property(nonatomic, retain) UIColor* textColor;
@property(nonatomic, retain) NSShadow* shadow;
@property(nonatomic, retain) NSMutableParagraphStyle* paragraphStyle;
@end


@implementation CoordinateLabelsLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a CoordinateLabelsLayerDelegate object.
///
/// @note This is the designated initializer of CoordinateLabelsLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithMainView:(UIView*)mainView
                metrics:(PlayViewMetrics*)metrics
                  model:(PlayViewModel*)playViewModel
                   axis:(enum CoordinateLabelAxis)axis
{
  // Call designated initializer of superclass (PlayViewLayerDelegateBase)
  self = [super initWithMainView:mainView metrics:metrics model:playViewModel];
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
  self.paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
  self.paragraphStyle.alignment = NSTextAlignmentCenter;
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
      self.layer.frame = self.playViewMetrics.rect;
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
  UIFont* coordinateLabelFont = self.playViewMetrics.coordinateLabelFont;
  if (! coordinateLabelFont)
    return;
  DDLogVerbose(@"CoordinateLabelsLayerDelegate is drawing axis %d with font size %f",
               self.coordinateLabelAxis,
               coordinateLabelFont.pointSize);

  NSDictionary* textAttributes = @{ NSFontAttributeName : coordinateLabelFont,
                                    NSForegroundColorAttributeName : self.textColor,
                                    NSShadowAttributeName: self.shadow,
                                    NSParagraphStyleAttributeName : self.paragraphStyle };

  CGRect coordinateLabelRect = CGRectZero;
  coordinateLabelRect.size = self.playViewMetrics.coordinateLabelMaximumSize;
  if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
  {
    coordinateLabelRect.origin.x = (self.playViewMetrics.topLeftPointX
                                    - floor(self.playViewMetrics.coordinateLabelMaximumSize.width / 2));
    coordinateLabelRect.origin.y = floor((self.playViewMetrics.coordinateLabelStripWidth
                                          - self.playViewMetrics.coordinateLabelMaximumSize.height) / 2);
  }
  else
  {
    coordinateLabelRect.origin.x = floor((self.playViewMetrics.coordinateLabelStripWidth
                                          - self.playViewMetrics.coordinateLabelMaximumSize.width) / 2);
    coordinateLabelRect.origin.y = (self.playViewMetrics.topLeftPointY
                                    + (self.playViewMetrics.numberOfCells * self.playViewMetrics.pointDistance)
                                    - floor(self.playViewMetrics.coordinateLabelMaximumSize.height / 2));
  }


  // NSString's drawInRect:withAttributes: is a UIKit drawing function. To make
  // it work we need to push our layer drawing context to the top of the UIKit
  // context stack (which is currently empty).
  UIGraphicsPushContext(context);
  GoPoint* point = [[GoGame sharedGame].board pointAtVertex:@"A1"];
  while (point)
  {
    NSString* coordinateLabelText;
    if (CoordinateLabelAxisLetter == self.coordinateLabelAxis)
      coordinateLabelText = point.vertex.letterAxisCompound;
    else
      coordinateLabelText = point.vertex.numberAxisCompound;
    [coordinateLabelText drawInRect:coordinateLabelRect withAttributes:textAttributes];
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

// -----------------------------------------------------------------------------
/// @brief Private helper for drawLayer:inContext:
// -----------------------------------------------------------------------------
- (bool) shouldDisplayCoordinateLabels
{
  if (! self.playViewMetrics.coordinateLabelFont)
    return false;
  else
    return self.playViewModel.displayCoordinates;
}

@end
