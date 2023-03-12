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


// Forward declarations
@class GoPoint;
@class BoardViewMetrics;
@class MarkupModel;
@protocol Tile;


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
CGLayerRef CreateSymbolLayer(CGContextRef context, enum GoMarkupSymbol symbol, UIColor* symbolFillColor, UIColor* symbolStrokeColor, MarkupModel* markupModel, BoardViewMetrics* metrics);
CGLayerRef CreateConnectionLayer(CGContextRef context, enum GoMarkupConnection connection, UIColor* connectionFillColor, UIColor* connectionStrokeColor, GoPoint* fromPoint, GoPoint* toPoint, CGRect canvasRect, BoardViewMetrics* metrics);
CGLayerRef CreateSquareSymbolLayer(CGContextRef context, UIColor* symbolColor, BoardViewMetrics* metrics);
CGLayerRef CreateDeadStoneSymbolLayer(CGContextRef context, BoardViewMetrics* metrics);
CGLayerRef CreateTerritoryLayer(CGContextRef context, enum TerritoryMarkupStyle territoryMarkupStyle, BoardViewMetrics* metrics);
//@}

/// @name Drawing helpers
//@{
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics;

+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
      inCanvasRect:(CGRect)canvasRect
    inTileWithRect:(CGRect)tileRect
       withMetrics:(BoardViewMetrics*)metrics;

+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
     inTileWithRect:(CGRect)tileRect
        withMetrics:(BoardViewMetrics*)metrics;

+ (CGRect) canvasRectForStoneAtPoint:(GoPoint*)point
                             metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectFromPoint:(GoPoint*)fromPoint
                       toPoint:(GoPoint*)toPoint
                       metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForRowContainingPoint:(GoPoint*)point
                                   metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                    centeredAtPoint:(GoPoint*)point
                            metrics:(BoardViewMetrics*)metrics;
+ (CGRect) canvasRectForSize:(CGSize)size
             centeredAtPoint:(GoPoint*)point
                     metrics:(BoardViewMetrics*)metrics;
+ (CGRect) drawingRectForTile:(id<Tile>)tile
              centeredAtPoint:(GoPoint*)point
                  withMetrics:(BoardViewMetrics*)metrics;
+ (CGRect) drawingRectForTile:(id<Tile>)tile
                    fromPoint:(GoPoint*)fromPoint
                      toPoint:(GoPoint*)toPoint
                  withMetrics:(BoardViewMetrics*)metrics;
+ (CGRect) drawingRectForTile:(id<Tile>)tile
         inRowContainingPoint:(GoPoint*)point
                  withMetrics:(BoardViewMetrics*)metrics;
//@}

/// @name Drawing and caching helpers
//@{
+ (CGLayerRef) cachedBlackStoneLayerWithContext:(CGContextRef)context
                                    withMetrics:(BoardViewMetrics*)metrics;
+ (CGLayerRef) cachedWhiteStoneLayerWithContext:(CGContextRef)context
                                    withMetrics:(BoardViewMetrics*)metrics;
+ (CGLayerRef) cachedCrossHairStoneLayerWithContext:(CGContextRef)context
                                        withMetrics:(BoardViewMetrics*)metrics;
//@}

/// @name Drawing arrows
//@{
#define kArrowPointCount 7

+ (CGPathRef) newPathWithArrowFromPoint:(CGPoint)startPoint
                                toPoint:(CGPoint)endPoint
                              tailWidth:(CGFloat)tailWidth
                              headWidth:(CGFloat)headWidth
                             headLength:(CGFloat)headLength;
+ (void) getAxisAlignedArrowPoints:(CGPoint[kArrowPointCount])points
                    forArrowLength:(CGFloat)arrowLength
                         tailWidth:(CGFloat)tailWidth
                         headWidth:(CGFloat)headWidth
                        headLength:(CGFloat)headLength;
+ (CGAffineTransform) transformForStartPoint:(CGPoint)startPoint
                                    endPoint:(CGPoint)endPoint
                                 arrowLength:(CGFloat)arrowLength;
+ (CGFloat) distanceFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;
//@}

@end
