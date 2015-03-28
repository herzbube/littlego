// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "MagnifyingView.h"
#import "UiUtilities.h"


@implementation MagnifyingView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an MagnifyingView object.
///
/// @note This is the designated initializer of MagnifyingView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.magnifiedImage = nil;
  self.gradientEnabled = true;

  // The amount of alpha that we set here influences how dark the loupe appears.
  // Alternatively, to make the loupe lighter, we could also start not with
  // black, but with an intermediate gray (not tested).
  self.gradientOuterColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
  // It's important that the we use white, not black, as the second color,
  // because this makes the fading into nothingness much smoother. If we use
  // black as the second color then the fading is much more noticeable; it also
  // causes the loupe to become darker because there is more "blackness".
  self.gradientInnerColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
  // The following calculation looks good for size 100.0f. Using a percentage
  // instead of absolute values hopefully makes the code behave reasonably if
  // a different size is chosen.
  self.gradientInnerCircleCenterDistanceFromBottom = floorf(rect.size.height * 0.25f);
  self.gradientInnerCircleEdgeDistanceFromBottom = floorf(rect.size.height * 0.05f);
  self.borderEnabled = true;
  self.borderColor = [UIColor blackColor];
  self.borderWidth = 1.0f;
  self.hotspotEnabled = true;
  self.hotspotColor = [UIColor redColor];
  self.hotspotRadius = 2.0f;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MagnifyingView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.magnifiedImage = nil;
  self.gradientOuterColor = nil;
  self.gradientInnerColor = nil;
  self.borderColor = nil;
  self.hotspotColor = nil;
  [super dealloc];
}

#pragma mark - Setter implementation

// -----------------------------------------------------------------------------
/// @brief Updates the content of the view, causing the view to redraw itself.
// -----------------------------------------------------------------------------
- (void) setMagnifiedImage:(UIImage*)magnifiedImage
{
  if (_magnifiedImage)
    [_magnifiedImage autorelease];
  _magnifiedImage = magnifiedImage;
  if (_magnifiedImage)
    [_magnifiedImage retain];
  [self setNeedsDisplay];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (void) drawRect:(CGRect)rect
{
  CGPoint magnifyingGlassCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

  // Take the lesser dimension as the radius, in case the view is, for some
  // reason, rectangular instead of square
  CGFloat magnifyingGlassRadius;
  if (rect.size.height >= rect.size.width)
    magnifyingGlassRadius = magnifyingGlassCenter.x - rect.origin.x;
  else
    magnifyingGlassRadius = magnifyingGlassCenter.y - rect.origin.y;

  const CGFloat startRadius = [UiUtilities radians:0];
  const CGFloat endRadius = [UiUtilities radians:360];
  const int clockwise = 0;

  CGContextRef context = UIGraphicsGetCurrentContext();

  // Save the current state so that we can restore it later to remove the
  // clipping path we are going to create next
  CGContextSaveGState(context);

  // The clipping path we create here will remain in effect both for drawing
  // the image with the magnified content, and for the gradient
  CGContextAddArc(context,
                  magnifyingGlassCenter.x,
                  magnifyingGlassCenter.y,
                  magnifyingGlassRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextClip(context);

  [_magnifiedImage drawInRect:rect];

  if (self.gradientEnabled)
  {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSArray* colors = [NSArray arrayWithObjects:(id)self.gradientOuterColor.CGColor, (id)self.gradientInnerColor.CGColor, nil];
    CGFloat locations[] = { 0.0f, 1.0f };
    // NSArray is toll-free bridged, so we can simply cast to CGArrayRef
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (CFArrayRef)colors,
                                                        locations);
    CGGradientDrawingOptions gradientOptions = 0;
    CGPoint gradientOuterCircleCenter = magnifyingGlassCenter;
    CGFloat gradientOuterCircleRadius = magnifyingGlassRadius;

    CGPoint gradientInnerCircleCenter;
    gradientInnerCircleCenter.x = magnifyingGlassCenter.x;
    gradientInnerCircleCenter.y = CGRectGetMaxY(rect) - self.gradientInnerCircleCenterDistanceFromBottom;
    CGFloat gradientInnerCircleRadius = self.gradientInnerCircleCenterDistanceFromBottom - self.gradientInnerCircleEdgeDistanceFromBottom;
    CGContextDrawRadialGradient(context,
                                gradient,
                                gradientOuterCircleCenter,
                                gradientOuterCircleRadius,
                                gradientInnerCircleCenter,
                                gradientInnerCircleRadius,
                                gradientOptions);

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
  }

  // Restore the state in order to remove the clipping path. Do this only
  // ***AFTER*** the gradient is drawn. This allows "unusual" gradient
  // configurations which would cause parts of the gradient to be drawn outside
  // the clipping path.
  CGContextRestoreGState(context);

  if (self.borderEnabled)
  {
    CGContextAddArc(context,
                    magnifyingGlassCenter.x,
                    magnifyingGlassCenter.y,
                    // Reduce the radius because the circle will be stroked
                    magnifyingGlassRadius - (self.borderWidth / 2.0f),
                    startRadius,
                    endRadius,
                    clockwise);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextSetLineWidth(context, self.borderWidth);
    CGContextStrokePath(context);
  }

  if (self.hotspotEnabled)
  {
    CGContextAddArc(context,
                    magnifyingGlassCenter.x,
                    magnifyingGlassCenter.y,
                    self.hotspotRadius,
                    startRadius,
                    endRadius,
                    clockwise);
    CGContextSetFillColorWithColor(context, self.hotspotColor.CGColor);
    CGContextFillPath(context);
  }
}

@end
