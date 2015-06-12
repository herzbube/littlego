// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GenerateTerritoryStatisticsCommand.h"
#import "UpdateTerritoryStatisticsCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoPlayer.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


@implementation GenerateTerritoryStatisticsCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoGame* game = [GoGame sharedGame];
  if (! game)
    return false;
  NSString* commandString = @"reg_genmove ";
  commandString = [commandString stringByAppendingString:game.nextMovePlayer.colorString];
  GtpCommand* command = [GtpCommand asynchronousCommand:commandString
                                         responseTarget:self
                                               selector:@selector(gtpResponseReceived:)];
  [command submit];
  game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonPlayerInfluence;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered when the GTP engine responds to the command submitted
/// in doIt().
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  if (! response.status)
  {
    DDLogError(@"%@: Aborting due to failed GTP command", [self shortDescription]);
    assert(0);
    return;
  }
  [[[[UpdateTerritoryStatisticsCommand alloc] init] autorelease] submit];
  [GoGame sharedGame].reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;
}

@end
