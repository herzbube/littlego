// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "ToggleTerritoryStatisticsCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../play/model/PlayViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


@implementation ToggleTerritoryStatisticsCommand

@synthesize asynchronousCommandDelegate;


// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  [self setupProgressHUD];
  [self updateBoardWithZeroStatistics];
  bool success = [self submitGtpCommand];
  if (! success)
    return false;
  // Updates the Play view
  [[NSNotificationCenter defaultCenter] postNotificationName:territoryStatisticsChanged object:nil];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt()
// -----------------------------------------------------------------------------
- (void) setupProgressHUD
{
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                     setProgressHUDMode:MBProgressHUDModeIndeterminate];
  NSString* message = @"Waiting for computer...";
  [self.asynchronousCommandDelegate asynchronousCommand:self
                                            didProgress:0.0
                                        nextStepMessage:message];
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (void) updateBoardWithZeroStatistics
{
  GoBoard* board = [GoGame sharedGame].board;
  GoPoint* point = [board pointAtVertex:@"A1"];
  while (point)
  {
    // Zero = no influence = nothing will be drawn on that intersection. Without
    // this initialization, the Play view would draw player influence with data
    // from the last time that the display of player influence was enabled.
    point.territoryStatisticsScore = 0.0f;
    point = point.next;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper
// -----------------------------------------------------------------------------
- (bool) submitGtpCommand
{
  PlayViewModel* model = [ApplicationDelegate sharedDelegate].playViewModel;
  int territoryStaticsParameter = model.displayPlayerInfluence ? 1 : 0;
  NSString* commandString = [NSString stringWithFormat:@"uct_param_globalsearch territory_statistics %d", territoryStaticsParameter];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  return command.response.status;
}

@end
