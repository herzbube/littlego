// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "TerritoryLayerDelegate.h"
#import "../PlayViewMetrics.h"
#import "../PlayViewModel.h"
#import "../ScoringModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardRegion.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
@interface TerritoryLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) ScoringModel* scoringModel;
//@}
@end


@implementation TerritoryLayerDelegate


@synthesize scoringModel;


// -----------------------------------------------------------------------------
/// @brief Initializes a TerritoryLayerDelegate object.
///
/// @note This is the designated initializer of TerritoryLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics playViewModel:(PlayViewModel*)playViewModel scoringModel:(ScoringModel*)theScoringModel
{
  // Call designated initializer of superclass (PlayViewLayerDelegate)
  self = [super initWithLayer:aLayer metrics:metrics model:playViewModel];
  if (! self)
    return nil;
  self.scoringModel = theScoringModel;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TerritoryLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.scoringModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief CALayer delegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  UIColor* colorBlack = [UIColor colorWithWhite:0.0 alpha:self.scoringModel.alphaTerritoryColorBlack];
  UIColor* colorWhite = [UIColor colorWithWhite:1.0 alpha:self.scoringModel.alphaTerritoryColorWhite];
  UIColor* colorInconsistencyFound;
  enum InconsistentTerritoryMarkupType inconsistentTerritoryMarkupType = self.scoringModel.inconsistentTerritoryMarkupType;
  switch (inconsistentTerritoryMarkupType)
  {
    case InconsistentTerritoryMarkupTypeDotSymbol:
    {
      colorInconsistencyFound = self.scoringModel.inconsistentTerritoryDotSymbolColor;
      break;
    }
    case InconsistentTerritoryMarkupTypeFillColor:
    {
      UIColor* fillColor = self.scoringModel.inconsistentTerritoryFillColor;
      colorInconsistencyFound = [UIColor colorWithRed:fillColor.red
                                                green:fillColor.green
                                                 blue:fillColor.blue
                                                alpha:self.scoringModel.inconsistentTerritoryFillColorAlpha];
      break;
    }
    case InconsistentTerritoryMarkupTypeNeutral:
    {
      colorInconsistencyFound = nil;
      break;
    }
    default:
    {
      DDLogError(@"Unknown value %d for property ScoringModel.inconsistentTerritoryMarkupType", inconsistentTerritoryMarkupType);
      colorInconsistencyFound = nil;
      break;
    }
  }
  
  NSEnumerator* enumerator = [[GoGame sharedGame].board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    bool inconsistencyFound = false;
    UIColor* color;
    switch (point.region.territoryColor)
    {
      case GoColorBlack:
        color = colorBlack;
        break;
      case GoColorWhite:
        color = colorWhite;
        break;
      case GoColorNone:
        if (! point.region.territoryInconsistencyFound)
          continue;  // territory is truly neutral, no markup needed
        else if (InconsistentTerritoryMarkupTypeNeutral == inconsistentTerritoryMarkupType)
          continue;  // territory is inconsistent, but user does not want markup
        else
        {
          inconsistencyFound = true;
          color = colorInconsistencyFound;
        }
        break;
      default:
        continue;
    }
    
    if (inconsistencyFound && InconsistentTerritoryMarkupTypeDotSymbol == inconsistentTerritoryMarkupType)
    {
      CGPoint coordinates = [self.playViewMetrics coordinatesFromPoint:point];
      CGContextSetFillColorWithColor(context, color.CGColor);
      const int startRadius = 0;
      const int endRadius = 2 * M_PI;
      const int clockwise = 0;
      CGContextAddArc(context,
                      coordinates.x + gHalfPixel,
                      coordinates.y + gHalfPixel,
                      self.playViewMetrics.stoneRadius * self.scoringModel.inconsistentTerritoryDotSymbolPercentage,
                      startRadius,
                      endRadius,
                      clockwise);
      CGContextFillPath(context);
    }
    else
    {
      CGRect square = [self.playViewMetrics squareAtPoint:point];
      [color set];  // all fill and stroke operations after this statement will use this color
      UIRectFillUsingBlendMode(square, kCGBlendModeNormal);
      CGContextStrokePath(context);
    }
  }
}

@end
