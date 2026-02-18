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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The TimeLeftCommand class is responsible for submitting the
/// "time_left" to the GTP engine. Command execution occurs synchronously.
///
/// TimeLeftCommand should be invoked while the player's clock is not started.
/// If the player's clock is started, TimeLeftCommand will get inaccurate values
/// from GoPlayerTimeData. Notably, GoPlayerTimeData will report a remaining
/// time value that is too high because time has already elapsed since the
/// clock was started. As a consequence, Fuego may take too long to think and
/// may lose on time.
///
/// "time_left" is a standard GTP command, i.e. it's described in the
/// GTP 2.0 specification and is not a Fuego-specific GTP command. It has the
/// following parameters:
/// - Player for which the information applies
/// - Number of seconds remaining
/// - Number of stones remaining. While main time is in effect, the number of
///   remaining stones is given as 0.
///
/// TimeLeftCommand does not submit the "time_left" GTP command if the current
/// game does not use timed play. The assumption is that in this case Fuego
/// was configured with a "time_settings" GTP command that indicates "no time
/// limits", in which case the currently active GTP engine profile's
/// fuegoMaxThinkingTime property value will take over.
///
/// If the current game uses timed play, TimeLeftCommand uses the following
/// logic to determine the parameters of the GTP command:
/// - If the current node has valid time data, it can be assumed that the clock
///   of the player whose turn it is can provide the parameters. TimeLeftCommand
///   therefore uses values it obtains from the player's GoPlayerTimeData object
///   as the GTP command's parameter values.
/// - If the current node has invalid time data, the clock of the player whose
///   turn it is cannot be assumed to contain valid data. TimeLeftCommand
///   instead uses the active GTP engine profile's @e fuegoMaxThinkingTime
///   property for the remaining time parameter, and 1 as the remaining moves
///   parameter. Because remaining moves is != 0, Fuego will think it is in
///   overtime and will use the remaining time divided by the remaining moves.
///   Because the latter is 1, Fuego will use the whole duration indicated by
///   the @e fuegoMaxThinkingTime property.
// -----------------------------------------------------------------------------
@interface TimeLeftCommand : CommandBase
{
}

@end
