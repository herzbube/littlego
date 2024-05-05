// -----------------------------------------------------------------------------
// Copyright 2019-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "AccessibilityUtility.h"
#import "../go/GoPoint.h"
#import "../go/GoVertex.h"


@implementation AccessibilityUtility

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel
                                                        value:(NSString*)accessibilityValue
{
  UIAccessibilityElement* uiAccessibilityElement = [[[UIAccessibilityElement alloc] initWithAccessibilityContainer:container] autorelease];

  uiAccessibilityElement.isAccessibilityElement = NO;
  uiAccessibilityElement.accessibilityIdentifier = accessibilityIdentifier;
  uiAccessibilityElement.accessibilityLabel = accessibilityLabel;
  uiAccessibilityElement.accessibilityValue = accessibilityValue;

  return uiAccessibilityElement;
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// line grid of a board with the specified board size @a boardSize.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                          forLineGridWithSize:(enum GoBoardSize)boardSize
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                      identifier:@"lineGrid"
                                                           label:@"Line grid"
                                                           value:[NSString stringWithFormat:@"%d x %d", boardSize, boardSize]];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified board size value @a boardSize.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                 forBoardSize:(enum GoBoardSize)boardSize
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                      identifier:@"boardSize"
                                                           label:@"Board size"
                                                           value:[[NSNumber numberWithInt:boardSize] stringValue]];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of points @a points. The array must contain GoPoint objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                    forPoints:(NSArray*)points
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel
{
  NSMutableArray* pointVertexes = [NSMutableArray arrayWithCapacity:0];

  for (GoPoint* point in points)
    [pointVertexes addObject:point.vertex.string];

  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                forPointVertexes:pointVertexes
                                                      identifier:accessibilityIdentifier
                                                           label:accessibilityLabel];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of points @a pointVertexes. The array must contain NSString
/// objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                             forPointVertexes:(NSArray*)pointVertexes
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                      identifier:accessibilityIdentifier
                                                           label:accessibilityLabel
                                                           value:[pointVertexes componentsJoinedByString:@", "]];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of star points @a starPoints. The array must contain GoPoint
/// objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                forStarPoints:(NSArray*)starPoints
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                       forPoints:starPoints
                                                      identifier:@"starPoints"
                                                           label:@"Star points"];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of star points @a starPointVertexes. The array must contain
/// NSString objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                         forStarPointVertexes:(NSArray*)starPointVertexes
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                forPointVertexes:starPointVertexes
                                                      identifier:@"starPoints"
                                                           label:@"Star points"];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of handicap points @a handicapPoints. The array must contain
/// GoPoint objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                forHandicapPoints:(NSArray*)handicapPoints
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                       forPoints:handicapPoints
                                                      identifier:@"handicapPoints"
                                                           label:@"Handicap points"];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of handicap points @a handicapPointVertexes. The array must
/// contain NSString objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                         forHandicapPointVertexes:(NSArray*)handicapPointVertexes
{
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                forPointVertexes:handicapPointVertexes
                                                      identifier:@"handicapPoints"
                                                           label:@"Handicap points"];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of points @a points that are occupied by stones of the
/// specified color @a color. The array must contain GoPoint objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                               forStonePoints:(NSArray*)stonePoints
                                                    withColor:(enum GoColor)color
{
  NSString* accessibilityIdentifier;
  NSString* accessibilityLabel;
  if (color == GoColorBlack)
  {
    accessibilityIdentifier = @"blackStones";
    accessibilityLabel = @"Black stones";
  }
  else
  {
    accessibilityIdentifier = @"whiteStones";
    accessibilityLabel = @"White stones";
  }
  
  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                       forPoints:stonePoints
                                                      identifier:accessibilityIdentifier
                                                           label:accessibilityLabel];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly allocated UIAccessibilityElement that represents the
/// specified list of points @a pointVertexes that are occupied by stones of the
/// specified color @a color. The array must contain NSString objects.
// -----------------------------------------------------------------------------
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                        forStonePointVertexes:(NSArray*)stonePointVertexes
                                                    withColor:(enum GoColor)color
{
  NSString* accessibilityIdentifier;
  NSString* accessibilityLabel;
  if (color == GoColorBlack)
  {
    accessibilityIdentifier = @"blackStones";
    accessibilityLabel = @"Black stones";
  }
  else
  {
    accessibilityIdentifier = @"whiteStones";
    accessibilityLabel = @"White stones";
  }

  return [AccessibilityUtility uiAccessibilityElementInContainer:container
                                                forPointVertexes:stonePointVertexes
                                                      identifier:accessibilityIdentifier
                                                           label:accessibilityLabel];
}

// -----------------------------------------------------------------------------
/// @brief Returns an accessibility identifier that can be used to tag UI
/// elements that represent a node whose symbol is @a nodeSymbol.
// -----------------------------------------------------------------------------
+ (NSString*) accessibilityIdentifierForNodeSymbol:(enum NodeTreeViewCellSymbol)nodeSymbol
{
  switch (nodeSymbol)
  {
    case NodeTreeViewCellSymbolNone:
      return noNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolEmpty:
      return emptyNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolBlackSetupStones:
      return blackSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolWhiteSetupStones:
      return whiteSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolNoSetupStones:
      return clearSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolBlackAndWhiteSetupStones:
      return blackAndWhiteSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolBlackAndNoSetupStones:
      return blackAndClearSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolWhiteAndNoSetupStones:
      return whiteAndClearSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones:
      return blackAndWhiteAndClearSetupStonesNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolBlackMove:
      return blackMoveNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolWhiteMove:
      return whiteMoveNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolAnnotations:
      return annotationsNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolMarkup:
      return markupNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolAnnotationsAndMarkup:
      return annotationsAndMarkupNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolHandicap:
      return handicapNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolKomi:
      return komiNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolHandicapAndKomi:
      return handicapAndKomiNodeImageViewBoardPositionAccessibilityIdentifier;
    case NodeTreeViewCellSymbolRoot:
      return rootNodeImageViewBoardPositionAccessibilityIdentifier;
    default:
      assert(0);
      return nil;  // dummy return
  }
}

@end
