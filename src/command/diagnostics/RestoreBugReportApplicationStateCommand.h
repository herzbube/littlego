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
/// @brief The RestoreBugReportApplicationStateCommand class is responsible for
/// restoring the application state from the information contained in a bug
/// report diagnostics information package.
///
/// RestoreBugReportApplicationStateCommand performs the following operations
/// to bring the application into the same state that existed when the
/// diagnostics information package was generated:
/// - Unarchive in-memory objects from the appropriate dump file that is part
///   of the diagnostics information package
/// - Enable scoring mode if necessary
/// - Load the .sgf file that corresponds to the current game into the GTP
///   engine
///
/// To achieve its task, RestoreBugReportApplicationStateCommand looks for the
/// diagnostics information package in a pre-determined folder (cf.
/// BugReportUtilities).
// -----------------------------------------------------------------------------
@interface RestoreBugReportApplicationStateCommand : CommandBase
{
}

- (id) init;

@end
