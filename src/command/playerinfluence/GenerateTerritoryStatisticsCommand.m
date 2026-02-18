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
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../play/model/BoardViewModel.h"


@implementation GenerateTerritoryStatisticsCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  // Fuego's handler for the "reg_genmove" GTP command ignores the clock (see
  // GoGtpEngine::CmdRegGenMove()), instead it operates with the
  // fuegoMaxThinkingTime time limit (see GtpEngineProfile). Because of this,
  // we don't need to submit a TimeLeftCommand.

  BoardViewModel* model = [Registry sharedRegistry].modelProvider.boardViewModel;
  if (! model.displayPlayerInfluence)
  {
    DDLogVerbose(@"%@: Display of player influence is turned off, nothing to do.", [self shortDescription]);
    return true;
  }

  GoGame* game = [GoGame sharedGame];
  if (! game)
    return false;

  game.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonPlayerInfluence;
  [self postNotificationOnMainThread:territoryStatisticsGenerationWillBegin];

  NSString* commandString = @"reg_genmove ";
  commandString = [commandString stringByAppendingString:game.nextMovePlayer.colorString];
  GtpCommand* command = [GtpCommand asynchronousCommand:commandString
                                         responseTarget:self
                                               selector:@selector(gtpResponseReceived:)];
  [command submit];

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
  [self postNotificationOnMainThread:territoryStatisticsGenerationDidEnd];
}

// -----------------------------------------------------------------------------
/// @brief Posts the notification with the specified name to the global
/// notification center. This method makes sure that the notification is posted
/// synchronously and on the main thread.
// -----------------------------------------------------------------------------
- (void) postNotificationOnMainThread:(NSString*)notificationName
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(postNotificationOnMainThread:)
                           withObject:notificationName
                        waitUntilDone:YES];
    return;
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

@end
