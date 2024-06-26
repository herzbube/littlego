// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class NodeTreeViewModel;
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
CGLayerRef CreateNodeSelectionLayer(CGContextRef context, bool condensed, NodeTreeViewModel* model, NodeTreeViewMetrics* metrics);
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

+ (void) drawNodeNumber:(NSString*)nodeNumberText
            withContext:(CGContextRef)context
         textAttributes:(NSDictionary*)textAttributes
             centeredAt:(NodeTreeViewCellPosition*)position
         inTileWithRect:(CGRect)tileRect
            withMetrics:(NodeTreeViewMetrics*)metrics;

+ (void) drawNodeNumber:(NSString*)nodeNumberText
            withContext:(CGContextRef)context
         textAttributes:(NSDictionary*)textAttributes
                   part:(int)part
           partPosition:(NodeTreeViewCellPosition*)position
         inTileWithRect:(CGRect)tileRect
            withMetrics:(NodeTreeViewMetrics*)metrics;

+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
             allowDrawingInCircleWithCenter:(CGPoint)center
                                     radius:(CGFloat)radius;

+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
                 allowDrawingInFullCellRect:(CGRect)fullCellRect
            disallowDrawingInNodeSymbolRect:(CGRect)nodeSymbolRect;

+ (void) setNodeSymbolClippingPathInContext:(CGContextRef)context
         allowDrawingInCircleOfFullCellRect:(CGRect)fullCellRect
            disallowDrawingInNodeSymbolRect:(CGRect)nodeSymbolRect;

+ (void) removeNodeSymbolClippingPathWithContext:(CGContextRef)context;

+ (CGRect) canvasRectForMultipartCellPart:(int)part
                             partPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForNodeNumberMultipartCellPart:(int)part
                                       partPosition:(NodeTreeViewCellPosition*)position
                                            metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForCellAtPosition:(NodeTreeViewCellPosition*)position
                               metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForNodeNumberCellAtPosition:(NodeTreeViewCellPosition*)position
                                         metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                         centeredAt:(NodeTreeViewCellPosition*)position
                            metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) canvasRectForSize:(CGSize)size
                  centeredAt:(NodeTreeViewCellPosition*)position
                     metrics:(NodeTreeViewMetrics*)metrics;

+ (CGRect) drawingRectForMultipartCellPart:(int)part
                              partPosition:(NodeTreeViewCellPosition*)position
                                    onTile:(id<Tile>)tile
                                   metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForCellAtPosition:(NodeTreeViewCellPosition*)position
                                 onTile:(id<Tile>)tile
                                metrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForCell:(bool)condensed
                  withMetrics:(NodeTreeViewMetrics*)metrics;
+ (CGRect) drawingRectForNodeSymbolInCell:(bool)condensed
             centeredInDrawingRectForCell:(CGRect)drawingRectForCell
                              withMetrics:(NodeTreeViewMetrics*)metrics;
+ (void) circularDrawingParametersInRect:(CGRect)rect
                         strokeLineWidth:(CGFloat)strokeLineWidth
                                  center:(CGPoint*)center
                          clippingRadius:(CGFloat*)clippingRadius
                           drawingRadius:(CGFloat*)drawingRadius;
+ (void) circularDrawingParametersInRect:(CGRect)rect
                         strokeLineWidth:(CGFloat)strokeLineWidth
                                  center:(CGPoint*)center
                           drawingRadius:(CGFloat*)drawingRadius;
+ (void) circularClippingParametersInRect:(CGRect)rect
                           clippingCenter:(CGPoint*)clippingCenter
                           clippingRadius:(CGFloat*)clippingRadius;
//@}

@end
