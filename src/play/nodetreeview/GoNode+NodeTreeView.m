// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNode+NodeTreeView.h"
#import "../../go/GoGame.h"
#import "../../go/GoMove.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoNodeSetup.h"


@implementation GoNode(GoNode_NodeTreeView)

// -----------------------------------------------------------------------------
/// @brief Returns the #NodeTreeViewCellSymbol enumeration value corresponding
/// to the node symbol that best describes the content of the node.
///
/// Rules of precedence how the node symbol is determined:
/// - If the node contains either a move or setup information (it cannot contain
///   both), this has the highest priority.
///   - If the node contains a move the node symbol should be a Go stone whose
///     color matches the color of the player who made the move.
///   - If the node contains setup information, the node symbol should describe
///     the type of setup information as accurately as possible. A distinction
///     should be made whether only black or white setup stones are placed, or
///     stones already present on the board are removed, or a combination
///     thereof.
/// - If the node contains neither a move nor setup information, annotations and
///   markup have the next-highest priority. If the node contains annotations
///   and/or markup (it can contain both), the node symbol should describe
///   which of the combinations the node contains (only annotations, only
///   markup, or both).
/// - If the node has no content, the distinction with the next-highest priority
///   is whether the node is the root node or not.
///   - If the node is the root node, then the node symbol should describe
///     whether the game was created with handicap and/or komi. If neither
///     handicap nor komi is set, the node symbol should simply indicate that
///     the node is the root node.
///   - If the node is not the root node, the node symbol should simply indicate
///     that the node is not the root node.
// -----------------------------------------------------------------------------
- (enum NodeTreeViewCellSymbol) nodeSymbol
{
  GoNodeSetup* nodeSetup = self.goNodeSetup;
  if (nodeSetup)
  {
    bool hasBlackSetupStones = nodeSetup.blackSetupStones;
    bool hasWhiteSetupStones = nodeSetup.whiteSetupStones;
    bool hasNoSetupStones = nodeSetup.noSetupStones;

    if (hasBlackSetupStones)
    {
      if (hasWhiteSetupStones)
      {
        if (hasNoSetupStones)
          return NodeTreeViewCellSymbolBlackAndWhiteAndNoSetupStones;
        else
          return NodeTreeViewCellSymbolBlackAndWhiteSetupStones;
      }
      else if (hasNoSetupStones)
        return NodeTreeViewCellSymbolBlackAndNoSetupStones;
      else
        return NodeTreeViewCellSymbolBlackSetupStones;
    }
    else if (hasWhiteSetupStones)
    {
      if (hasNoSetupStones)
        return NodeTreeViewCellSymbolWhiteAndNoSetupStones;
      else
        return NodeTreeViewCellSymbolWhiteSetupStones;
    }
    else
    {
      return NodeTreeViewCellSymbolNoSetupStones;
    }
  }
  else if (self.goMove)
  {
    if (self.goMove.player.isBlack)
      return NodeTreeViewCellSymbolBlackMove;
    else
      return NodeTreeViewCellSymbolWhiteMove;
  }
  else if (self.goNodeAnnotation)
  {
    if (self.goNodeMarkup)
      return NodeTreeViewCellSymbolAnnotationsAndMarkup;
    else
      return NodeTreeViewCellSymbolAnnotations;
  }
  else if (self.goNodeMarkup)
  {
    return NodeTreeViewCellSymbolMarkup;
  }
  else if (self.isRoot)
  {
    GoGame* game = [GoGame sharedGame];
    bool hasHandicap = game.handicapPoints.count > 0;
    bool hasKomi = game.komi > 0.0;
    if (hasHandicap && hasKomi)
      return NodeTreeViewCellSymbolHandicapAndKomi;
    else if (hasHandicap)
      return NodeTreeViewCellSymbolHandicap;
    else if (hasKomi)
      return NodeTreeViewCellSymbolKomi;
    else
      return NodeTreeViewCellSymbolRoot;
  }

  return NodeTreeViewCellSymbolEmpty;
}

@end
