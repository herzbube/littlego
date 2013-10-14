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
#import "CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The UpdateTerritoryStatisticsCommand class is responsible for
/// updating the territory statistics property in all GoPoint objects with
/// values obtained from the GTP engine. Command execution occurs synchronously.
///
/// UpdateTerritoryStatisticsCommand posts the notification
/// #territoryStatisticsChanged after all GoPoint objects have been updated.
///
/// UpdateTerritoryStatisticsCommand executes successfully but does nothing if
/// the user preference to display player influence is turned off.
// -----------------------------------------------------------------------------
@interface UpdateTerritoryStatisticsCommand : CommandBase
{
}

@end
