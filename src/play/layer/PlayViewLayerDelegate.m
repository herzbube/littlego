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
#import "PlayViewLayerDelegate.h"
#import "../PlayViewMetrics.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewLayerDelegate.
// -----------------------------------------------------------------------------
@interface PlayViewLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) CALayer* layer;
@property(nonatomic, retain, readwrite) PlayViewMetrics* playViewMetrics;
@property(nonatomic, retain, readwrite) PlayViewModel* playViewModel;
//@}
@end


@implementation PlayViewLayerDelegate

@synthesize layer;
@synthesize playViewMetrics;
@synthesize playViewModel;
@synthesize dirty;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewLayerDelegate object.
///
/// @note This is the designated initializer of PlayViewLayerDelegate.
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
  self.layer.frame = playViewMetrics.rect;

  // KVO observing
  [self.playViewMetrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];
  [self.playViewMetrics addObserver:self forKeyPath:@"boardDimension" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.playViewMetrics removeObserver:self forKeyPath:@"rect"];
  [self.playViewMetrics removeObserver:self forKeyPath:@"boardDimension"];
  self.layer = nil;
  self.playViewMetrics = nil;
  self.playViewModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"rect"])
  {
    self.layer.frame = playViewMetrics.rect;
    self.dirty = true;
  }
  else if ([keyPath isEqualToString:@"boardDimension"])
  {
    // TODO set needsDisplay to false if the concrete layer does not need an
    // update on boardDimension change
    self.dirty = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Triggers update in the layer managed by this delegate if the dirty
/// flag is currently true.
// -----------------------------------------------------------------------------
- (void) updateIfDirty
{
  if (self.dirty)
  {
    self.dirty = false;
    [self.layer setNeedsDisplay];
  }
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

// -----------------------------------------------------------------------------
/// @brief Drawing primitive that draws a stone with its center at the layer
/// coordinates @a coordinates and using color @a color to fill the stone.
///
/// This is a convenience method intended to be used by sub-classes.
// -----------------------------------------------------------------------------
- (void) drawStone:(CGContextRef)context color:(UIColor*)color coordinates:(CGPoint)coordinates
{
	CGContextSetFillColorWithColor(context, color.CGColor);
  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  CGContextAddArc(context, coordinates.x + gHalfPixel,
                  coordinates.y + gHalfPixel,
                  self.playViewMetrics.stoneRadius,
                  startRadius,
                  endRadius,
                  clockwise);
  CGContextFillPath(context);
}

@end
