// -----------------------------------------------------------------------------
// Copyright 2011-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewBoardTabDelegate.h"
#import "../../../go/GoBoardPosition.h"
#import "../../../go/GoGame.h"
#import "../../../go/GoMove.h"
#import "../../../go/GoNode.h"
#import "../../../go/GoPlayer.h"
#import "../../../go/GoPoint.h"
#import "../../../go/GoUtilities.h"
#import "../../../go/GoVertex.h"
#import "../../../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Board" tab of the
/// "Game Info" table view.
// -----------------------------------------------------------------------------
enum GameInfoBoardTabTableViewSection
{
  BoardPositionSection,
  MaxSection,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BoardPositionSection.
// -----------------------------------------------------------------------------
enum BoardPositionSectionItem
{
  CurrentBoardPositionItem,
  CurrentBoardPositionMoveItem,
  MovesAfterCurrentBoardPositionItem,
  MaxBoardPositionSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewBoardTabDelegate.
// -----------------------------------------------------------------------------
@interface GameInfoViewBoardTabDelegate()
@end


@implementation GameInfoViewBoardTabDelegate

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewBoardTabDelegate object.
///
/// @note This is the designated initializer of GameInfoViewBoardTabDelegate.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewBoardTabDelegate
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return MaxBoardPositionSectionItem;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
  if (! nodeWithMostRecentMove)
  {
    return @"You are viewing a board position before the first move was played.";
  }
  else
  {
    bool nodeWithNextMoveExists = [GoUtilities nodeWithNextMoveExists:boardPosition.currentNode inCurrentGameVariation:game];
    if (nodeWithNextMoveExists)
      return @"You are viewing a board position in the middle of the game.";
    else
      return @"You are viewing the board position after the most recent move of the game has been played.";
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [self tableView:tableView boardInfoTypeCellForRowAtIndexPath:indexPath];
}

#pragma mark - Private helpers for tableView:cellForRowAtIndexPath:().

// -----------------------------------------------------------------------------
/// @brief Private helper for tableView:cellForRowAtIndexPath:().
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView boardInfoTypeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  switch (indexPath.row)
  {
    case CurrentBoardPositionItem:
    {
      cell.textLabel.text = @"You are viewing move number";
      GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
      if (nodeWithMostRecentMove)
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", nodeWithMostRecentMove.goMove.moveNumber];
      else
        cell.detailTextLabel.text = @"n/a";
      break;
    }
    case CurrentBoardPositionMoveItem:
    {
      cell.textLabel.text = @"Move info";
      GoNode* nodeWithMostRecentMove = [GoUtilities nodeWithMostRecentMove:boardPosition.currentNode];
      if (nodeWithMostRecentMove)
        cell.detailTextLabel.text = [GoUtilities stringWithDescriptionOfMove:nodeWithMostRecentMove.goMove];
      else
        cell.detailTextLabel.text = @"n/a";
      break;
    }
    case MovesAfterCurrentBoardPositionItem:
    {
      int numberOfMovesAfterCurrentBoardPosition = [GoUtilities numberOfMovesAfterNode:boardPosition.currentNode inCurrentGameVariation:game];
      cell.textLabel.text = @"Moves after current position";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", numberOfMovesAfterCurrentBoardPosition];
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
