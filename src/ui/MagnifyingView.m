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
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MagnifyingView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.magnifiedImage = nil;
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

  // First draw the clipped image
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  CGContextAddArc(context,
                  magnifyingGlassCenter.x,
                  magnifyingGlassCenter.y,
                  magnifyingGlassRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextClip(context);
  [_magnifiedImage drawInRect:rect];
  CGContextRestoreGState(context);

  // Next draw the stroked circle
  CGFloat magnifyingGlassBorderThickness = 1.0f;
  CGContextAddArc(context,
                  magnifyingGlassCenter.x,
                  magnifyingGlassCenter.y,
                  // Reduce the radius because the circle will be stroked
                  magnifyingGlassRadius - (magnifyingGlassBorderThickness / 2.0f),
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
  CGContextSetLineWidth(context, magnifyingGlassBorderThickness);
  CGContextStrokePath(context);

  // Finally draw the hot spot that marks the center of magnification
  CGFloat hotspotRadius = 2.0f;
  CGContextAddArc(context,
                  magnifyingGlassCenter.x,
                  magnifyingGlassCenter.y,
                  hotspotRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextSetFillColorWithColor(context, [UIColor redColor].CGColor);
  CGContextFillPath(context);
}

@end
