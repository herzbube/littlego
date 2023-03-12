// -----------------------------------------------------------------------------
// Copyright 2014-2022 Patrick Näf (herzbube@herzbube.ch)
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


/// @brief Enumerates all possible types of reusable CGLayer objects.
///
/// Entries in this enumeration must start with numeric value 0 and have
/// monotonically increasing values so that iterating all entries based on
/// numeric values is possible.
enum LayerType
{
  StarPointLayerType = 0,
  BlackStoneLayerType,
  WhiteStoneLayerType,
  CrossHairStoneLayerType,
  BlackLastMoveLayerType,
  WhiteLastMoveLayerType,
  BlackTerritoryLayerType,
  WhiteTerritoryLayerType,
  InconsistentFillColorTerritoryLayerType,
  InconsistentDotSymbolTerritoryLayerType,
  DeadStoneSymbolLayerType,
  BlackSekiStoneSymbolLayerType,
  WhiteSekiStoneSymbolLayerType,
  BlackCircleSymbolLayerType,
  WhiteCircleSymbolLayerType,
  BlackSquareSymbolLayerType,
  WhiteSquareSymbolLayerType,
  BlackTriangleSymbolLayerType,
  WhiteTriangleSymbolLayerType,
  BlackXSymbolLayerType,
  WhiteXSymbolLayerType,
  BlackSelectedSymbolLayerType,
  WhiteSelectedSymbolLayerType,
  SelectionRectangleLayerType,
  MaxLayerType  // Helper enum value used for iteration etc.
};


/// @brief A cache entry in BoardViewCGLayerCache.
///
/// The Go board view is resizable. Because of this when layers are created for
/// drawing the board the result may be a NULL layer if the metrics refer to
/// extremely small board dimensions. In such a case, a NULL layer must
/// therefore be considered a valid entry in BoardViewCGLayerCache. Consequently
/// NULL can not be used as a special CGLayerRef marker value to distinguish
/// between valid or invalid cache entries. Instead the
/// BoardViewCGLayerCacheEntry struct contains the boolean member @e isValid to
/// indicate validity.
typedef struct
{
  bool isValid;
  CGLayerRef layer;
}
BoardViewCGLayerCacheEntry;


// -----------------------------------------------------------------------------
/// @brief The BoardViewCGLayerCache class provides a cache of CGLayer objects
/// that can be reused for drawing the Go board.
// -----------------------------------------------------------------------------
@interface BoardViewCGLayerCache : NSObject
{
}

+ (BoardViewCGLayerCache*) sharedCache;
+ (void) releaseSharedCache;

- (BoardViewCGLayerCacheEntry) layerOfType:(enum LayerType)layerType;
- (void) setLayer:(CGLayerRef)layer ofType:(enum LayerType)layerType;
- (void) invalidateLayerOfType:(enum LayerType)layerType;
- (void) invalidateAllLayers;

@end
