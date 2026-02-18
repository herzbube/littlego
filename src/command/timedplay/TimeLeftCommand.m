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
#import "TimeLeftCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoNode.h"
#import "../../go/GoPlayer.h"
#import "../../go/GoPlayerTimeData.h"
#import "../../go/GoTimeSettings.h"
#import "../../go/GoTimeSystem.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../player/GtpEngineProfile.h"
#import "../../player/GtpEngineProfileModel.h"


struct TimeLeftParameterValues
{
  // The GTP 2.0 specification defines the type of all parameters to be "int".
  // Fuego's implementation of the command faithfully uses "int" as well.
  int remainingNumberOfSeconds;
  int remainingNumberOfStones;
};
typedef struct TimeLeftParameterValues TimeLeftParameterValues;


@implementation TimeLeftCommand

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GoGame* game = [GoGame sharedGame];
  if (! game.timeSettings.isGameUsingTimedPlay)
    return true;

  GoPlayer* nextMovePlayer = game.nextMovePlayer;

  TimeLeftParameterValues timeLeftParameterValues;

  GoNode* currentNode = game.boardPosition.currentNode;
  if (currentNode.isTimeDataValid)
    timeLeftParameterValues = [self timeLeftParameterValuesFromPlayerTimeData:nextMovePlayer.timeData];
  else
    timeLeftParameterValues = [self timeLeftParameterValuesFromActiveGtpEngineProfile];

  NSString* commandString = [NSString stringWithFormat:@"time_left %@ %d %d",
                             nextMovePlayer.colorString,
                             timeLeftParameterValues.remainingNumberOfSeconds,
                             timeLeftParameterValues.remainingNumberOfStones];
  GtpCommand* command = [GtpCommand command:commandString];
  [command submit];
  if (! command.response.status)
  {
    DDLogError(@"%@: GTP command '%@' failed with response %@", self, commandString, command.response.parsedResponse);
    return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (TimeLeftParameterValues) timeLeftParameterValuesFromPlayerTimeData:(GoPlayerTimeData*)playerTimeData
{
  TimeLeftParameterValues timeLeftParameterValues;

  if (playerTimeData.clockState == GoClockStateStarted)
    DDLogError(@"%@: Player clock is already started, time_left will use remaining time that is too high", self);

  // We use floor() because 1) we are almost certain to get a fractional
  // value; but 2) the command supports only integer values; so 3) we round
  // down and not up, to prevent Fuego from using more time than the app
  // allows (otherwise the app might see the player losing on time).
  //
  // Because the current node has valid time data we know that the int value
  // range cannot be exceeded, so it's safe to cast to int here => See
  // GoTimeDataValidator which sets, for instance,
  // GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum.
  timeLeftParameterValues.remainingNumberOfSeconds = (int)floor(playerTimeData.remainingTimeInSeconds);
  timeLeftParameterValues.remainingNumberOfStones = (int)playerTimeData.remainingNumberOfMoves;

  if (timeLeftParameterValues.remainingNumberOfStones == 0 &&
      ! playerTimeData.isRemainingTimeAbsoluteTime)
  {
    GoTimeSystem* periodBasedTimeSystem = [GoGame sharedGame].timeSettings.periodBasedTimeSystem;

    if (periodBasedTimeSystem.goUnusedTimeHandling == GoUnusedTimeHandlingUseForExtraMoves)
    {
      // Handling for GoTimeSystemTypeSteadyAverage: Allow Fuego to aggressively
      // use all the remaining time for a single move, if it wants to. Because
      // it did not use the time so far, it may continue to play faster.
      timeLeftParameterValues.remainingNumberOfStones = 1;
    }
    else
    {
      // remainingNumberOfStones == 0 means SgTimeRecord::UseOvertime() returns
      // false, i.e. Fuego will assume it is in overtime. It will then use a lot
      // less time than remainingNumberOfSeconds would allow.
      // See SgDefaultTimeControl::TimeForCurrentMove().
      DDLogWarn(@"%@: remainingNumberOfStones is unexpectedly 0, Fuego will treat remainingNumberOfSeconds as main time", self);
    }
  }

  return timeLeftParameterValues;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for doIt().
// -----------------------------------------------------------------------------
- (TimeLeftParameterValues) timeLeftParameterValuesFromActiveGtpEngineProfile
{
  GtpEngineProfileModel* model = [Registry sharedRegistry].modelProvider.gtpEngineProfileModel;
  GtpEngineProfile* activeProfile = model.activeProfile;

  TimeLeftParameterValues timeLeftParameterValues;

  // fuegoMaxThinkingTime cannot be higher than fuegoMaxThinkingTimeMaximum.
  // This constant's value is well below the maximum range for int, therefore
  // it is safe to cast to int here.
  timeLeftParameterValues.remainingNumberOfSeconds = (int)activeProfile.fuegoMaxThinkingTime;
  timeLeftParameterValues.remainingNumberOfStones = 1;

  return timeLeftParameterValues;
}

@end
