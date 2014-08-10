// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "UpdateTerritoryStatisticsCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../play/model/BoardViewModel.h"


@implementation UpdateTerritoryStatisticsCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  BoardViewModel* model = [ApplicationDelegate sharedDelegate].boardViewModel;
  if (! model.displayPlayerInfluence)
  {
    DDLogVerbose(@"%@: Display of player influence is turned off, nothing to do.", [self shortDescription]);
    return true;
  }
  GtpCommand* command = [GtpCommand command:@"uct_stat_territory"];
  [command submit];
  if (! command.response.status)
    return false;
  bool success = [self updateBoardWithGtpResponse:command.response.parsedResponse];
  if (! success)
    return false;
  [[NSNotificationCenter defaultCenter] postNotificationName:territoryStatisticsChanged object:nil];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (bool) updateBoardWithGtpResponse:(NSString*)gtpResponse
{
  GoBoard* board = [GoGame sharedGame].board;
  struct GoVertexNumeric vertexNumeric;
  vertexNumeric.x = 1;
  vertexNumeric.y = board.size;  // start at the top of the board
  NSArray* responseLines = [gtpResponse componentsSeparatedByString:@"\n"];
  for (NSString* responseLine in responseLines)
  {
    if (0 == vertexNumeric.y)
    {
      assert(false);
      DDLogError(@"%@: GTP response has too many lines", [self shortDescription]);
      return false;
    }
    NSMutableArray* territoryStatisticScores = [NSMutableArray arrayWithArray:[responseLine componentsSeparatedByString:@" "]];
    [territoryStatisticScores removeObject:@""];
    if (territoryStatisticScores.count != board.size)
      continue;  // skip the first line which is empty
    // Start at the left edge of the board
    NSString* vertexLeftEdge = [GoVertex vertexFromNumeric:vertexNumeric].string;
    GoPoint* point = [board pointAtVertex:vertexLeftEdge];
    for (NSString* territoryStatisticScore in territoryStatisticScores)
    {
      if (! point)
      {
        assert(false);
        DDLogError(@"%@: Line in GTP response has too many elements", [self shortDescription]);
        return false;
      }
      point.territoryStatisticsScore = [territoryStatisticScore floatValue];
      point = point.right;  // continue on the same line to the right
    }
    if (point)
    {
      assert(false);
      DDLogError(@"%@: Line in GTP response has not enough elements", [self shortDescription]);
      return false;
    }
    vertexNumeric.y--;  // move down one line
  }
  if (0 != vertexNumeric.y)
  {
    assert(false);
    DDLogError(@"%@: GTP response has not enough lines", [self shortDescription]);
    return false;
  }
  return true;
}

@end
