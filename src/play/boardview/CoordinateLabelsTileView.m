// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "CoordinateLabelsTileView.h"
#import "layer/CoordinatesLayerDelegate.h"
#import "../model/PlayViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardTileView.
// -----------------------------------------------------------------------------
@interface CoordinateLabelsTileView()
@property(nonatomic, retain) BVCoordinatesLayerDelegate* layerDelegate;
@property(nonatomic, assign) bool drawLayerWasDelayed;
@end


@implementation CoordinateLabelsTileView

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;


// -----------------------------------------------------------------------------
/// @brief Initializes a CoordinateLabelsTileView object with frame rectangle
/// @a rect that draws along the axis @a axis.
///
/// @note This is the designated initializer of CoordinateLabelsTileView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect axis:(enum CoordinateLabelAxis)axis
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.coordinateLabelAxis = axis;
  self.row = -1;
  self.column = -1;
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  self.layerDelegate = [[[BVCoordinatesLayerDelegate alloc] initWithTile:self
                                                                 metrics:metrics
                                                                    axis:axis] autorelease];
  [self.layer addSublayer:self.layerDelegate.layer];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  [metrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];

  self.drawLayerWasDelayed = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CoordinateLabelsTileView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  [metrics removeObserver:self forKeyPath:@"rect"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
  self.layerDelegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed drawing of the view
/// layer. CoordinateLabelsTileView methods that need a view update should
/// invoke this helper instead of drawLayer().
///
/// If no long-running actions are in progress, this helper invokes
/// drawLayer(), thus triggering the update in UIKit.
///
/// If any long-running actions are in progress, this helper sets
/// @e drawLayerWasDelayed to true.
// -----------------------------------------------------------------------------
- (void) delayedDrawLayer
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayerWasDelayed = true;
  else
    [self drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the view layer that it needs to update now if it is dirty.
/// This marks one update cycle.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.drawLayerWasDelayed = false;
  [self.layerDelegate drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  [self.layerDelegate notify:BVLDEventGoGameStarted eventInfo:nil];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayerWasDelayed)
    [self drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  if (object == metrics)
  {
    if ([keyPath isEqualToString:@"rect"])
    {
      [self.layerDelegate notify:BVLDEventBoardGeometryChanged eventInfo:nil];
      [self delayedDrawLayer];
    }
    else if ([keyPath isEqualToString:@"boardSize"])
    {
      [self.layerDelegate notify:BVLDEventBoardSizeChanged eventInfo:nil];
      [self delayedDrawLayer];
    }
    else if ([keyPath isEqualToString:@"displayCoordinates"])
    {
      [self.layerDelegate notify:BVLDEventDisplayCoordinatesChanged eventInfo:nil];
      [self delayedDrawLayer];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Re-draws the entire content of this CoordinateLabelsTileView.
// -----------------------------------------------------------------------------
- (void) redraw
{
  // TODO xxx why exactly do we need this?
  [self.layerDelegate notify:BVLDEventBoardGeometryChanged eventInfo:nil];
  [self delayedDrawLayer];
}

@end
