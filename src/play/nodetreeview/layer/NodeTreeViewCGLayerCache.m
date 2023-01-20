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
#import "NodeTreeViewCGLayerCache.h"


// Store layers in a global array variable because access is by simple indexing
// and therefore very fast. Since only one instance of NodeTreeViewCGLayerCache
// can exist, there are no array access conflicts to solve.
static const int arraySizeLayers = NodeTreeViewLayerTypeMax;
static CGLayerRef layers[arraySizeLayers];


@implementation NodeTreeViewCGLayerCache

#pragma mark - Handle shared object

static NodeTreeViewCGLayerCache* sharedCache = nil;

+ (NodeTreeViewCGLayerCache*) sharedCache
{
  if (! sharedCache)
    sharedCache = [[NodeTreeViewCGLayerCache alloc] init];
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

- (CGLayerRef) layerOfType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType
{
  return layers[nodeTreeViewLayerType];
}

- (void) setLayer:(CGLayerRef)layer ofType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType
{
  CGLayerRetain(layer);
  layers[nodeTreeViewLayerType] = layer;
}

- (void) invalidateLayerOfType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType
{
  if (layers[nodeTreeViewLayerType])
  {
    CGLayerRelease(layers[nodeTreeViewLayerType]);
    layers[nodeTreeViewLayerType] = NULL;
  }
}

- (void) invalidateAllNodeSymbolLayers
{
  for (int layerIndex = NodeTreeViewLayerTypeNodeSymbolFirst;
       layerIndex <= NodeTreeViewLayerTypeNodeSymbolLast;
       ++layerIndex)
  {
    if (layers[layerIndex])
    {
      CGLayerRelease(layers[layerIndex]);
      layers[layerIndex] = NULL;
    }
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
