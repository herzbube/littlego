// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class GoGame;
@class GoGameRules;
@class GoMove;
@class GoNode;
@class GoPlayer;
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The GoUtilities class is a container for various utility functions
/// that operate on all sorts of objects from the Go module.
///
/// @ingroup go
///
/// All functions in GoUtilities are class methods, so there is no need to
/// create an instance of GoUtilities.
// -----------------------------------------------------------------------------
@interface GoUtilities : NSObject
{
}

+ (void) movePointToNewRegion:(GoPoint*)thePoint;
+ (NSArray*) verticesForHandicap:(int)handicap boardSize:(enum GoBoardSize)boardSize;
+ (NSArray*) pointsForHandicap:(int)handicap inGame:(GoGame*)game;
+ (int) maximumHandicapForBoardSize:(enum GoBoardSize)boardSize;
+ (GoPlayer*) playerAfter:(GoMove*)move inCurrentGameVariation:(GoGame*)game;
+ (NSArray*) pointsInRectangleDelimitedByCornerPoint:(GoPoint*)pointA
                                 oppositeCornerPoint:(GoPoint*)pointB
                                              inGame:(GoGame*)game;
+ (NSArray*) pointsInRowWithPoint:(GoPoint*)point;
+ (NSArray*) pointsInColumnWithPoint:(GoPoint*)point;
+ (NSArray*) pointsInBothFirstArray:(NSArray*)firstArray
                     andSecondArray:(NSArray*)secondArray;
+ (double) defaultKomiForHandicap:(int)handicap scoringSystem:(enum GoScoringSystem)scoringSystem;
+ (GoGameRules*) rulesForRuleset:(enum GoRuleset)ruleset;
+ (enum GoRuleset) rulesetForRules:(GoGameRules*)rules;
+ (enum GoColor) alternatingColorForColor:(enum GoColor)color;
+ (bool) isGameInResumedPlayState:(GoGame*)game;
+ (bool) shouldAllowResumePlay:(GoGame*)game;
+ (NSString*) verticesStringForPoints:(NSArray*)points;
+ (void) recalculateZobristHashes:(GoGame*)game;
+ (void) relinkMoves:(GoGame*)game;
+ (GoNode*) nodeWithMostRecentMove:(GoNode*)node;
+ (GoNode*) nodeWithNextMove:(GoNode*)node inCurrentGameVariation:(GoGame*)game;
+ (bool) nodeWithNextMoveExists:(GoNode*)node inCurrentGameVariation:(GoGame*)game;
+ (int) numberOfMovesBeforeNode:(GoNode*)node;
+ (int) numberOfMovesAfterNode:(GoNode*)node inCurrentGameVariation:(GoGame*)game;
+ (GoNode*) nodeWithMostRecentSetup:(GoNode*)node inCurrentGameVariation:(GoGame*)game;
+ (GoNode*) nodeWithMostRecentBoardStateChange:(GoNode*)node;
+ (bool) showInfoIndicatorForNode:(GoNode*)node;
+ (bool) showHotspotIndicatorForNode:(GoNode*)node;
+ (enum NodeTreeViewCellSymbol) symbolForNode:(GoNode*)node inGame:(GoGame*)game;

@end
