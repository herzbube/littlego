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
@class BoardTileView;
@class GoPoint;
@class PlayViewMetrics;


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
CGLayerRef BVCreateStarPointLayer(CGContextRef context, PlayViewMetrics* metrics);
CGLayerRef BVCreateStoneLayerWithImage(CGContextRef context, NSString* stoneImageName, PlayViewMetrics* metrics);
CGLayerRef BVCreateSquareSymbolLayer(CGContextRef context, UIColor* symbolColor, PlayViewMetrics* metrics);
//@}

/// @name Drawing helpers
//@{
+ (void) drawLayer:(CGLayerRef)layer
       withContext:(CGContextRef)context
   centeredAtPoint:(GoPoint*)point
    inTileWithRect:(CGRect)tileRect
       withMetrics:(PlayViewMetrics*)metrics;

+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
        withMetrics:(PlayViewMetrics*)metrics;

+ (void) drawString:(NSString*)string
        withContext:(CGContextRef)context
         attributes:(NSDictionary*)attributes
     inRectWithSize:(CGSize)size
    centeredAtPoint:(GoPoint*)point
     inTileWithRect:(CGRect)tileRect
        withMetrics:(PlayViewMetrics*)metrics;

+ (CGRect) canvasRectForTileView:(BoardTileView*)tileView
                         metrics:(PlayViewMetrics*)metrics;
+ (CGRect) canvasRectForScaledLayer:(CGLayerRef)layer
                    centeredAtPoint:(GoPoint*)point
                            metrics:(PlayViewMetrics*)metrics;
+ (CGRect) canvasRectForSize:(CGSize)size
             centeredAtPoint:(GoPoint*)point
                     metrics:(PlayViewMetrics*)metrics;

+ (CGRect) drawingRectForScaledLayer:(CGLayerRef)layer
                         withMetrics:(PlayViewMetrics*)metrics;
//@}

@end
