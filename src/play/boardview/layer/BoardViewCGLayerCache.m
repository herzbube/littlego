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
static BoardViewCGLayerCacheEntry layers[arraySizeLayers];


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
    layers[layerIndex] = (BoardViewCGLayerCacheEntry){false, NULL};
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

- (BoardViewCGLayerCacheEntry) layerOfType:(enum LayerType)layerType
{
  return layers[layerType];
}

- (void) setLayer:(CGLayerRef)layer ofType:(enum LayerType)layerType
{
  CGLayerRetain(layer);
  layers[layerType] = (BoardViewCGLayerCacheEntry){true, layer};
}

- (void) invalidateLayerOfType:(enum LayerType)layerType
{
  BoardViewCGLayerCacheEntry entry = layers[layerType];
  if (entry.isValid && entry.layer)
    CGLayerRelease(entry.layer);
  layers[layerType] = (BoardViewCGLayerCacheEntry){false, NULL};
}

- (void) invalidateAllLayers
{
  for (int layerIndex = 0; layerIndex < arraySizeLayers; ++layerIndex)
    [self invalidateLayerOfType:layerIndex];
}

@end
