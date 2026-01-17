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
/// @brief The TimeSettingsCommand class is responsible for submitting the
/// "time_settings" to the GTP engine. Command execution occurs synchronously.
///
/// Time settings cannot be changed if moves have already been played, therefore
/// TimeSettingsCommand must always be executed before any moves are played, or
/// the GTP command will fail.
///
/// "time_settings" is a standard GTP command, i.e. it's described in the
/// GTP 2.0 specification and is not a Fuego-specific GTP command. It has the
/// following parameters:
/// - Main time duration in seconds
/// - Overtime period duration in seconds (called "Byo yomi time" in the
///   GTP 2.0 specification)
/// - Number of stones per overtime period (called "Byo yomi stones" in the
///   GTP 2.0 specification)
///
/// TimeSettingsCommand uses the current GoGame object's time settings to
/// determine the parameters of the GTP command. The command is designed to set
/// up one of the following scenarios:
/// - Main time only, no overtime. To set up this scenario, TimeSettingsCommand
///   uses a non-zero value for the main time duration parameter, and zero
///   values for the two overtime parameters.
/// - Main time + overtime (using the Canadian Timing system). To set up this
///   scenario, TimeSettingsCommand uses non-zero values for all parameters.
/// - Overtime only (using the Canadian Timing system), no main time. To set up
///   this scenario, TimeSettingsCommand uses a zero value for the main time
///   duration parameter, and non-zero values for the two overtime parameters.
/// - Neither main time nor overtime. The GTP 2.0 specification says to use
///   a non-zero value for the overtime period duration and a zero value for
///   the number of stones parameter. The GTP 2.0 specification does not
///   mention the value of the main time duration parameter. To set up this
///   scenario, TimeSettingsCommand uses the parameter values "0 1 0".
///
/// The GTP command and also Fuego do not understand any overtime system except
/// Canadian Timing, TimeSettingsCommand uses the following values for the other
/// time systems that Little Go supports:
/// - Japanese Timing
///   - Overtime period duration in seconds = Duration of a single period.
///   - Number of stones per overtime period = 1.
/// - Fischer Timing
///   - Overtime period duration in seconds = Duration of initial time.
///   - Number of stones per overtime period = 1.
/// - Steady Average Timing
///   - Overtime period duration in seconds = Period duration.
///   - Number of stones per overtime period = Number of stones per period.
/// - Total Average Timing
///   - Overtime period duration in seconds = Period duration.
///   - Number of stones per overtime period = Number of stones per period.
///
/// The app will later use the "time_left" GTP command to continuously configure
/// Fuego with the remaining time and (if in overtime) the remaining number of
/// stones for the period. See TimeLeftCommand for details.
// -----------------------------------------------------------------------------
@interface TimeSettingsCommand : CommandBase
{
}

@end
