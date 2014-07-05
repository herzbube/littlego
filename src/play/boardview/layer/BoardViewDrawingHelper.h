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


// Forward declarations
@class GoPoint;
@class BoardViewMetrics;
@protocol Tile;

/// @brief Enumerates all possible layer types to mark up territory
// todo xxx move this enum somewhere else. also rename the enum to something
// like TerritoryMarkupStyle
enum TerritoryLayerType
{
  TerritoryLayerTypeBlack,
  TerritoryLayerTypeWhite,
  TerritoryLayerTypeInconsistentFillColor,
  TerritoryLayerTypeInconsistentDotSymbol
};


// -----------------------------------------------------------------------------
/// @brief The BoardViewDrawingHelper class provides a few drawing helper
/// functions for use by clients that are drawing UI elements on the board view.
///
/// There is no need to create an instance of BoardViewDrawingHelper because the
/// class contains only functions and class methods.
// -----------------------------------------------------------------------------
@interface BoardViewDrawingHelper : NSObject
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
CGLayerRef CreateStarPointLayer(CGContextRef context, BoardViewMetrics* metrics);
CGLayerRef CreateStoneLayerWithImage(CGContextRef context, NSString* stoneImageName, BoardViewMetrics* metrics);
CGLayerRef CreateSquareSymbolLayer(CGContextRef context, UIColor* symbolColor, BoardViewMetrics* metrics);
CGLayerRef CreateDeadStoneSymbolLayer(CGContextRef context, float symbolSizePercentage, UIColor* symbolColor, BoardViewMetrics* metrics);
CGLayerRef CreateTerritoryLayer(CGContextRef context, enum TerritoryLayerType layerType, UIColor* territoryColor, float symbolSizePercentage, BoardViewMetrics* metrics);
//@}

/// @name Drawing helpers
//@{
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics;

+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
        withMetrics:(BoardViewMetrics*)metrics;

+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
     inTileWithRect:(CGRect)tileRect
        withMetrics:(BoardViewMetrics*)metrics;

+ (CGRect) canvasRectForTile:(id<Tile>)tile
                     metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForStoneAtPoint:(GoPoint*)point
                             metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                    centeredAtPoint:(GoPoint*)point
                            metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForSize:(CGSize)size
             centeredAtPoint:(GoPoint*)point
                     metrics:(BoardViewMetrics*)metrics;

+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(BoardViewMetrics*)metrics;
+ (CGRect) drawingRectFromCanvasRect:(CGRect)canvasRect
                      inTileWithRect:(CGRect)tileRect;
//@}

@end
