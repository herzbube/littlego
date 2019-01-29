// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "../CommandBase.h"

// Forward declarations
@class GoPoint;


// -----------------------------------------------------------------------------
/// @brief The ToggleScoringStateOfStoneGroupCommand class is responsible for
/// toggling either the "dead state" or the "seki state" of the stone group
/// that covers the intersection identified by the GoPoint object that is
/// passed to the initializer. ToggleScoringStateOfStoneGroupCommand also
/// calculates a new score.
///
/// ToggleScoringStateOfStoneGroupCommand currently does not save the
/// application state. Should the app crash the changed scoring state of the
/// stone group is lost, as is the newly calculated score.
///
/// It is expected that this command is only executed while the UI area "Play"
/// is in scoring mode.
// -----------------------------------------------------------------------------
@interface ToggleScoringStateOfStoneGroupCommand : CommandBase
{
}

- (id) initWithPoint:(GoPoint*)point;

@end
