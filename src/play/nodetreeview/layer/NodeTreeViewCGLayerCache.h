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


/// @brief Enumerates all possible types of reusable CGLayer objects to draw the
/// node tree.
///
/// Entries in this enumeration must start with numeric value 0 and have
/// monotonically increasing values so that iterating all entries based on
/// numeric values is possible.
enum NodeTreeViewLayerType
{
  NodeTreeViewLayerTypeEmpty = 0,
  NodeTreeViewLayerTypeBlackSetupStones,
  NodeTreeViewLayerTypeWhiteSetupStones,
  NodeTreeViewLayerTypeNoSetupStones,
  NodeTreeViewLayerTypeBlackAndWhiteSetupStones,
  NodeTreeViewLayerTypeBlackAndNoSetupStones,
  NodeTreeViewLayerTypeWhiteAndNoSetupStones,
  NodeTreeViewLayerTypeBlackAndWhiteAndNoSetupStones,
  NodeTreeViewLayerTypeBlackMoveCondensed,
  NodeTreeViewLayerTypeBlackMoveUncondensed,
  NodeTreeViewLayerTypeWhiteMoveCondensed,
  NodeTreeViewLayerTypeWhiteMoveUncondensed,
  NodeTreeViewLayerTypeAnnotations,
  NodeTreeViewLayerTypeMarkup,
  NodeTreeViewLayerTypeAnnotationsAndMarkup,
  NodeTreeViewLayerTypeMax,  // Helper enum value used for iteration etc.
  NodeTreeViewLayerTypeFirst = 0,                           // Helper enum value used for iteration
  NodeTreeViewLayerTypeLast = NodeTreeViewLayerTypeMax - 1  // Helper enum value used for iteration
};


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCGLayerCache class provides a cache of CGLayer
/// objects that can be reused for drawing the node tree.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCGLayerCache : NSObject
{
}

+ (NodeTreeViewCGLayerCache*) sharedCache;
+ (void) releaseSharedCache;

- (CGLayerRef) layerOfType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType;
- (void) setLayer:(CGLayerRef)layer ofType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType;
- (void) invalidateLayerOfType:(enum NodeTreeViewLayerType)nodeTreeViewLayerType;
- (void) invalidateAllLayers;

@end
