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
#import "BoardTileView.h"
#import "layer/GridLayerDelegate.h"
#import "layer/StarPointsLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "../model/PlayViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardTileView.
// -----------------------------------------------------------------------------
@interface BoardTileView()
@property(nonatomic, assign) bool drawLayersWasDelayed;
@property(nonatomic, retain) NSMutableArray* layerDelegates;
//@}
@end


@implementation BoardTileView

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;
  self.row = -1;
  self.column = -1;
  self.layerDelegates = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  self.drawLayersWasDelayed = false;

  PlayViewMetrics* metrics = [ApplicationDelegate sharedDelegate].playViewMetrics;
  PlayViewModel* playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  id<BoardViewLayerDelegate> layerDelegate;
  layerDelegate = [[[BVGridLayerDelegate alloc] initWithTileView:self
                                                         metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVStarPointsLayerDelegate alloc] initWithTileView:self
                                                               metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVStonesLayerDelegate alloc] initWithTileView:self
                                                           metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVSymbolsLayerDelegate alloc] initWithTileView:self
                                                            metrics:metrics
                                                      playViewModel:playViewModel
                                                 boardPositionModel:boardPositionModel] autorelease];
  [self.layerDelegates addObject:layerDelegate];

  NSLog(@"init BoardTileView %@", self);

  return self;
}


- (void) dealloc
{
  NSLog(@"dealloc BoardTileView %@", self);
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  self.layerDelegates = nil;
  [super dealloc];
}

- (void) setRow:(int)row
{
  _row = row;

}
- (void) delayedDrawLayers
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayersWasDelayed = true;
  else
    [self drawLayers];
}


- (void) drawLayers
{
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.drawLayersWasDelayed = false;

  // Disabling animations here is essential for a smooth GUI update after a zoom
  // operation ends. If animations were enabled, setting the layer frames would
  // trigger an animation that looks like a "bounce". For details see
  // http://stackoverflow.com/questions/15370803/how-to-prevent-bounce-effect-when-a-custom-view-redraws-after-zooming
  [CATransaction begin];
  [CATransaction setDisableActions:YES];

  // Draw layers in the order in which they appear in the layerDelegates array
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate drawLayer];

  [CATransaction commit];
}

- (void) notifyLayerDelegates:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate notify:event eventInfo:eventInfo];
}

- (void) layoutSubviews
{
  [super layoutSubviews];
  NSLog(@"tile layoutSubviews, row = %d, column = %d, view = %@", self.row, self.column, self);
}

- (void) goGameDidCreate:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventGoGameStarted eventInfo:nil];
  [self notifyLayerDelegates:BVLDEventRectangleChanged eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayersWasDelayed)
    [self drawLayers];
}

- (void) redraw
{
  [self notifyLayerDelegates:BVLDEventRectangleChanged eventInfo:nil];
  [self delayedDrawLayers];
}

@end
