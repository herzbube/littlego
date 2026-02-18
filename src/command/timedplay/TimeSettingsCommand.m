// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "TimeSettingsCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeModel.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"


@implementation TimeSettingsCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoGame* game = [GoGame sharedGame];
  GoNode* rootNode = game.nodeModel.rootNode;

  // The GTP 2.0 specification defines the type of all parameters to be "int".
  // Fuego's implementation of the command faithfully uses "int" as well.
  int mainTimeInSeconds;
  int overtimeInSeconds;
  int overtimeNumberOfStones;

  if (rootNode.isTimeDataValid)
  {
    GoTimeSettings* timeSettings = game.timeSettings;
    GoTimeSystem* absoluteTimeSystem = timeSettings.absoluteTimeSystem;
    mainTimeInSeconds = (absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute
                         ? absoluteTimeSystem.periodDurationInSeconds
                         : 0);

    GoTimeSystem* periodBasedTimeSystem = timeSettings.periodBasedTimeSystem;
    switch (periodBasedTimeSystem.goTimeSystemType)
    {
      case GoTimeSystemTypeCanadian:
      case GoTimeSystemTypeJapanese:
      case GoTimeSystemTypeFischer:
      case GoTimeSystemTypeSteadyAverage:
      case GoTimeSystemTypeTotalAverage:
        // We use floor() because 1) we could get a fractional value from SGF
        // data; but 2) the command supports only integer values; so 3) we round
        // down and not up, to prevent Fuego from using more time than the app
        // allows (otherwise the app might see the player losing on time).
        //
        // Because the root node has valid time data we know that the int value
        // range cannot be exceeded, so it's safe to cast to int here => See
        // GoTimeDataValidator which sets, for instance,
        // GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum.
        overtimeInSeconds = (int)floor(periodBasedTimeSystem.periodDurationInSeconds);
        overtimeNumberOfStones = (int)periodBasedTimeSystem.minimumNumberOfMovesPerPeriod;
        break;
      case GoTimeSystemTypeNone:
        overtimeInSeconds = 0;
        overtimeNumberOfStones = 0;
        break;
      default:
        DDLogError(@"%@: Unexpected time type found: %d", self, periodBasedTimeSystem.goTimeSystemType);
        overtimeInSeconds = 0;
        overtimeNumberOfStones = 0;
        break;
    }
  }
  else
  {
    mainTimeInSeconds = 0;
    overtimeInSeconds = 1;
    overtimeNumberOfStones = 0;
  }

  // The command is allowed only when no moves have been played => clear_board
  // must have been executed
  NSString* commandString = [NSString stringWithFormat:@"time_settings %d %d %d",
                             mainTimeInSeconds,
                             overtimeInSeconds,
                             overtimeNumberOfStones];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  if (! command.response.status)
  {
    DDLogError(@"%@: GTP command '%@' failed with response %@", self, commandString, command.response.parsedResponse);
    return false;
  }

  return true;
}

@end
