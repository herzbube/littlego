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
/// @brief The SetAdditiveKnowledgeTypeCommand class is responsible for
/// submitting a "uct_param_policy knowledge_type" command to the GTP engine.
/// Command execution occurs synchronously.
///
/// The additive knowledge type used as the command argument is determined by
/// looking at the device memory:
/// - If there is not enough memory, the rulebased knowledge type is used
/// - If there is sufficient memory, the knowledge type that uses Greenpeep
///   patterns is used
///
/// The threshold to determine whether the device has sufficient memory is
/// taken from the user defaults system.
///
/// @note On devices with 512 MB of memory this command must be executed *AFTER*
/// the initial "uct_max_memory" GTP command has been submitted to the GTP
/// engine. Reason: The "uct_param_policy knowledge_type" GTP command triggers
/// initialization of the UCT search tree in Fuego. The tree is initialized with
/// the number of nodes defined by the current value of "uct_max_memory". If no
/// explicit value has been set yet, the default number of nodes uses up half of
/// the amount of memory that the device has! On devices with 512 MB of RAM,
/// this immediately causes enough memory pressure to crash the application,
/// before "uct_max_memory" has a chance to reduce the amount of memory required
/// by the UCT search tree.
// -----------------------------------------------------------------------------
@interface SetAdditiveKnowledgeTypeCommand : CommandBase
{
}

@end
