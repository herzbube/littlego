// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewLayerDelegateBase.h"
#import "../../model/NodeTreeViewMetrics.h"


@implementation NodeTreeViewLayerDelegateBase

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// NodeTreeViewLayerDelegate protocol.
@synthesize layer = _layer;
@synthesize tile = _tile;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewLayerDelegateBase object. Creates a new
/// CALayer that uses this NodeTreeViewLayerDelegateBase as its delegate.
///
/// @note This is the designated initializer of NodeTreeViewLayerDelegateBase.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(NodeTreeViewMetrics*)metrics
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = [CALayer layer];
  self.tile = tile;
  self.nodeTreeViewMetrics = metrics;
  self.dirty = false;

  CGRect layerFrame = CGRectZero;
  layerFrame.size = metrics.tileSize;
  self.layer.frame = layerFrame;

  self.layer.delegate = self;
  // Without this, all manner of drawing looks blurry on Retina displays
  self.layer.contentsScale = metrics.contentsScale;

  // This disables the implicit animation that normally occurs when the layer
  // delegate is drawing. As always, stackoverflow.com is our friend:
  // http://stackoverflow.com/questions/2244147/disabling-implicit-animations-in-calayer-setneedsdisplayinrect
  NSMutableDictionary* newActions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"contents", nil];
  self.layer.actions = newActions;
  [newActions release];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewLayerDelegateBase
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.layer = nil;
  self.tile = nil;
  self.nodeTreeViewMetrics = nil;

  [super dealloc];
}

#pragma mark - NodeTreeViewLayerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief NodeTreeViewLayerDelegate method. See the
/// NodeTreeViewLayerDelegateBase class documentation for details about this
/// implementation.
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
/// @brief NodeTreeViewLayerDelegate method. See the
/// NodeTreeViewLayerDelegateBase class documentation for details about this
/// implementation.
// -----------------------------------------------------------------------------
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  // empty "do-nothing" implementation
}

#pragma mark - Helper methods for subclasses

@end
