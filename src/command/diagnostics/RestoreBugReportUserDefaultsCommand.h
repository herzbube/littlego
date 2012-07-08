// -----------------------------------------------------------------------------
// Copyright 2012 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The RestoreBugReportUserDefaultsCommand class is responsible for
/// inserting those user defaults into the user defaults system that are
/// supplied by a bug report's diagnostics information package.
///
/// To achieve its task, RestoreBugReportUserDefaultsCommand looks for a user
/// defaults dump file in a pre-determined folder (cf. BugReportUtilities).
/// It loads the user defaults from the dump file into dictionary and updates
/// the user defaults system with all key/value pairs from the dictionary.
///
/// The current set of user defaults is overwritten by this operation.
///
/// @note As part of its execution, RestoreBugReportUserDefaultsCommand extracts
/// the contents of the diagnostics information file into a separate folder.
/// Since RestoreBugReportUserDefaultsCommand is the first command to be run
/// in a series that processes diagnostics information, the other commands
/// expect the diagnostics information folder to exist when it is their turn to
/// run.
// -----------------------------------------------------------------------------
@interface RestoreBugReportUserDefaultsCommand : CommandBase
{
}

- (id) init;

@end
