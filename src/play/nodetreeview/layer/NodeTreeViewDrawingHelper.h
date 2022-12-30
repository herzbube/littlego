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


// Forward declarations
@class NodeTreeViewCellPosition;
@class NodeTreeViewMetrics;
@protocol Tile;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewDrawingHelper class provides drawing helper functions
/// for use by clients that are drawing UI elements on the node tree view.
///
/// There is no need to create an instance of NodeTreeViewDrawingHelper because
/// the class contains only functions and class methods.
// -----------------------------------------------------------------------------
@interface NodeTreeViewDrawingHelper : NSObject
{
}

/// @name Layer creation functions
///
/// @brief These functions exist as CF-like creation functions to make Xcode's
/// analyze tool happy. If these functions are declared as Obj-C methods, the
/// analyze tool reports a possible memory leak because it does not see the
/// method as conforming to Core Foundation's ownership policy naming
/// conventions.
//@{
CGLayerRef CreateNodeSymbolLayer(CGContextRef context, enum NodeTreeViewCellSymbol symbolType, bool condensed, NodeTreeViewMetrics* metrics);
//@}

/// @name Drawing helpers
//@{
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
        centeredAt:(NodeTreeViewCellPosition*)position
    inTileWithRect:(CGRect)tileRect
       withMetrics:(NodeTreeViewMetrics*)metrics;

+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
              part:(int)part
      partPosition:(NodeTreeViewCellPosition*)position
    inTileWithRect:(CGRect)tileRect
       withMetrics:(NodeTreeViewMetrics*)metrics;

+ (CGRect) canvasRectForTile:(id<Tile>)tile
                     metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForMultipartCellPart:(int)part
                             partPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForCellAtPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                         centeredAt:(NodeTreeViewCellPosition*)position
                            metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForSize:(CGSize)size
                  centeredAt:(NodeTreeViewCellPosition*)position
                     metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForCell:(bool)condensed
                  withMetrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForNodeSymbolInCell:(bool)condensed
                              withMetrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForNodeSymbolInCell:(bool)condensed
                   withDrawingRectForCell:(CGRect)drawingRectForCell
                              withMetrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(NodeTreeViewMetrics*)metrics;
//@}

@end
