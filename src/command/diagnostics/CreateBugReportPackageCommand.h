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
/// @brief The CreateBugReportPackageCommand class is responsible for collecting
/// information to include in a bug report and packaging the information into a
/// single archive file for later processing. The path of the archive is
/// available from the property @e bugReportFilePath.
// -----------------------------------------------------------------------------
@interface CreateBugReportPackageCommand : CommandBase
{
}

- (id) init;

/// @brief Full path to the archive file that contains the collected bug report
/// information.
@property(nonatomic, retain) NSString* bugReportFilePath;

@end
