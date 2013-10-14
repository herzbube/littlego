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
/// @brief The GenerateTerritoryStatisticsCommand class is responsible for
/// submitting a command to the GTP engine that generates territory statistics.
/// Command execution occurs synchronously.
///
/// GenerateTerritoryStatisticsCommand currently uses the "reg_genmove" GTP
/// command to generate territory statistics. "reg_genmove" does not actually
/// make a move, it only lets the GTP engine make a suggestion. In order to be
/// able to make a suggestion, the GTP engine is forced to calculate playouts
/// which, as a side-effect, generates territory statistics.
// -----------------------------------------------------------------------------
@interface GenerateTerritoryStatisticsCommand : CommandBase
{
}

@end
