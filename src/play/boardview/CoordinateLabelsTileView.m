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

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;

#pragma mark - Initialization and deallocation

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
  _row = -1;
  _column = -1;

  [self setupLayer];
  [self setupNotificationResponders];

  self.drawLayerWasDelayed = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this CoordinateLabelsTileView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self.layerDelegate.layer removeFromSuperlayer];
  self.layerDelegate = nil;
  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupLayer
{
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  self.layerDelegate = [[[BVCoordinatesLayerDelegate alloc] initWithTile:self
                                                                 metrics:metrics
                                                                    axis:self.coordinateLabelAxis] autorelease];
  [self.layer addSublayer:self.layerDelegate.layer];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  [metrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  [metrics removeObserver:self forKeyPath:@"rect"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
}

#pragma mark - Handle delayed drawing

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

#pragma mark - Tile protocol overrides

// -----------------------------------------------------------------------------
/// @brief Tile protocol method
// -----------------------------------------------------------------------------
- (void) updateWithRow:(int)row column:(int)column
{
  bool shouldInvalidateContent = false;
  if (_row != row)
  {
    _row = row;
    shouldInvalidateContent = true;
  }
  if (_column != column)
  {
    _column = column;
    shouldInvalidateContent = true;
  }
  if (shouldInvalidateContent)
    [self invalidateContent];
}

// -----------------------------------------------------------------------------
/// @brief Tile protocol method
// -----------------------------------------------------------------------------
- (void) invalidateContent
{
  [self.layerDelegate notify:BVLDEventInvalidateContent eventInfo:nil];
  [self delayedDrawLayer];
}

#pragma mark - Notification responders

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

#pragma mark - KVO responder

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

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This implementation is not strictly required because
/// CoordinateLabelsTileView is currently not used in conjunction with Auto
/// Layout.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  return [ApplicationDelegate sharedDelegate].playViewMetrics.tileSize;
}

@end
