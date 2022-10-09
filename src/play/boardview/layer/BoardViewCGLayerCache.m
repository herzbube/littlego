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
#import "BoardViewCGLayerCache.h"


// Store layers in a global array variable because access is by simple indexing
// and therefore very fast. Since only one instance of BoardViewCGLayerCache
// can exist, there are no array access conflicts to solve.
static const int arraySizeLayers = MaxLayerType;
static CGLayerRef layers[arraySizeLayers];


@implementation BoardViewCGLayerCache

#pragma mark - Handle shared object

static BoardViewCGLayerCache* sharedCache = nil;

+ (BoardViewCGLayerCache*) sharedCache
{
  if (! sharedCache)
    sharedCache = [[BoardViewCGLayerCache alloc] init];
  return sharedCache;
}

+ (void) releaseSharedCache
{
  if (sharedCache)
  {
    [sharedCache release];
    sharedCache = nil;
  }
}

#pragma mark - Initialization and deallocation

- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  for (int layerIndex = 0; layerIndex < arraySizeLayers; ++layerIndex)
    layers[layerIndex] = NULL;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self invalidateAllLayers];
  if (sharedCache == self)
    sharedCache = nil;
  [super dealloc];
}

#pragma mark - Memory management

- (void) didReceiveMemoryWarning:(NSNotification*)notification
{
  [self invalidateAllLayers];
}

#pragma mark - Caching methods

// TODO xxx Currently layer delegates use this method to check if a layer
// exists - if this method returns NULL they assume that the layer does not
// exist and needs to be created. This logic is no longer viable because the
// board view is now resizable and can result in BoardViewDrawingHelper's
// Create...Layer functions returning NULL if the metrics refer to extremely
// small board dimensions. Layer delegates will therefore try to create layers
// over and over again in each drawing cycle, because they stored a NULL value
// in the cache in the previous drawing cycle. BoardViewCGLayerCache needs a
// new mechanism how to check whether a layer needs to be created.
- (CGLayerRef) layerOfType:(enum LayerType)layerType
{
  return layers[layerType];
}

- (void) setLayer:(CGLayerRef)layer ofType:(enum LayerType)layerType
{
  CGLayerRetain(layer);
  layers[layerType] = layer;
}

- (void) invalidateLayerOfType:(enum LayerType)layerType
{
  if (layers[layerType])
  {
    CGLayerRelease(layers[layerType]);
    layers[layerType] = NULL;
  }
}

- (void) invalidateAllLayers
{
  for (int layerIndex = 0; layerIndex < arraySizeLayers; ++layerIndex)
  {
    if (layers[layerIndex])
    {
      CGLayerRelease(layers[layerIndex]);
      layers[layerIndex] = NULL;
    }
  }
}

@end
