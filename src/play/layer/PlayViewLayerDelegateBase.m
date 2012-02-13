// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewLayerDelegateBase.h"
#import "../PlayViewMetrics.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewLayerDelegateBase.
// -----------------------------------------------------------------------------
@interface PlayViewLayerDelegateBase()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation PlayViewLayerDelegateBase

@synthesize layer;
@synthesize playViewMetrics;
@synthesize playViewModel;
@synthesize dirty;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewLayerDelegateBase object. The layer object is
/// set up to use the PlayViewLayerDelegateBase object as its delegate.
///
/// @note This is the designated initializer of PlayViewLayerDelegateBase.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = aLayer;
  self.playViewMetrics = metrics;
  self.playViewModel = model;
  self.dirty = false;

  self.layer.delegate = self;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewLayerDelegateBase
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.layer = nil;
  self.playViewMetrics = nil;
  self.playViewModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method. See the PlayViewLayerDelegateBase class
/// documentation for details about this implementation.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  if (self.dirty)
  {
    self.dirty = false;
    [self.layer setNeedsDisplay];
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewLayerDelegate method. See the PlayViewLayerDelegateBase class
/// documentation for details about this implementation.
// -----------------------------------------------------------------------------
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // empty "do-nothing" implementation
}

// -----------------------------------------------------------------------------
/// @brief Drawing primitive that draws a line between points @a start and
/// @a end, using width @a width and stroke color @a color.
///
/// This is a convenience method intended to be used by sub-classes.
// -----------------------------------------------------------------------------
- (void) drawLine:(CGContextRef)context startPoint:(CGPoint)start endPoint:(CGPoint)end color:(UIColor*)color width:(CGFloat)width
{
  CGContextBeginPath(context);
  CGContextMoveToPoint(context, start.x + gHalfPixel, start.y + gHalfPixel);
  CGContextAddLineToPoint(context, end.x + gHalfPixel, end.y + gHalfPixel);
  CGContextSetStrokeColorWithColor(context, color.CGColor);
  CGContextSetLineWidth(context, width);
  CGContextStrokePath(context);
}

@end
