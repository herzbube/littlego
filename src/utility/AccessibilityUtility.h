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


// -----------------------------------------------------------------------------
/// @brief The AccessibilityUtility class is a container for various utility
/// functions related to accessibility.
///
/// All functions in AccessibilityUtility are class methods, so there is no need
/// to create an instance of AccessibilityUtility.
// -----------------------------------------------------------------------------
@interface AccessibilityUtility : NSObject
{
}

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel
                                                        value:(NSString*)accessibilityValue;
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                    forPoints:(NSArray*)points
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel;
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                             forPointVertexes:(NSArray*)pointVertexes
                                                   identifier:(NSString*)accessibilityIdentifier
                                                        label:(NSString*)accessibilityLabel;

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                          forLineGridWithSize:(enum GoBoardSize)boardSize;

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                 forBoardSize:(enum GoBoardSize)boardSize;

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                                forStarPoints:(NSArray*)starPoints;
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                         forStarPointVertexes:(NSArray*)starPointVertexes;

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                            forHandicapPoints:(NSArray*)handicapPoints;
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                     forHandicapPointVertexes:(NSArray*)handicapPointVertexes;

+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                               forStonePoints:(NSArray*)stonePoints
                                                    withColor:(enum GoColor)color;
+ (UIAccessibilityElement*) uiAccessibilityElementInContainer:(id)container
                                        forStonePointVertexes:(NSArray*)stonePointVertexes
                                                    withColor:(enum GoColor)color;

+ (NSString*) accessibilityIdentifierForNodeSymbol:(enum NodeTreeViewCellSymbol)nodeSymbol;

@end
