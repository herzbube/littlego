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
#import "CommandBase.h"
#import "../AsynchronousCommand.h"


// -----------------------------------------------------------------------------
/// @brief The ToggleTerritoryStatisticsCommand class is responsible for
/// submitting a command to the GTP engine that enables or disables the
/// collection of territory statistics. Command execution occurs synchronously.
///
/// ToggleTerritoryStatisticsCommand looks up the current value of the
/// "display player influence" property in BoardViewModel to find out whether
/// statistics collection must be enabled or disabled. Statistics collection is
/// enabled if the property is true, disabled if the property is false.
///
/// ToggleTerritoryStatisticsCommand initializes the territory statistics
/// in all GoPoint objects with the value zero and triggers a drawing update
/// of the Go board. As a result, if the collection of territory statistics is
/// disabled, all the currently collected statistics are forgotten.
///
/// @note If the collection of territory statistics is enabled, this does not
/// cause territory statistics to be immediately collected - the collecting
/// occurs only when the next GTP command that generates a move is executed.
/// GenerateTerritoryStatisticsCommand can be executed to generate and collect
/// territory statistics without actually generating a move.
///
/// ToggleTerritoryStatisticsCommand is executed asynchronously (unless the
/// executor is another asynchronous command). The reason is that
/// ToggleTerritoryStatisticsCommand may be executed while the GTP engine
/// processes a "genmove" or some other long-running GTP command. In that case
/// ToggleTerritoryStatisticsCommand will block until the GTP engine has
/// finished processing the other command. ToggleTerritoryStatisticsCommand is
/// asynchronous so that the command processor displays the progress HUD while
/// the operation blocks.
// -----------------------------------------------------------------------------
@interface ToggleTerritoryStatisticsCommand : CommandBase <AsynchronousCommand>
{
}

@end
