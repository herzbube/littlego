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
/// @brief The GenerateDiagnosticsInformationFileCommand class is responsible
/// for generating the so-called diagnostics information file.
///
/// The diagnostics information file is a .zip archive that is attached to bug
/// reports. It contains diagnostics information that help with identifying the
/// source of the problem that was reported.
///
/// This command collects the necessary diagnostics information and creates the
/// archive file from the collected information. The full path where the file
/// has been stored is available from the property
/// @e diagnosticsInformationFilePath.
// -----------------------------------------------------------------------------
@interface GenerateDiagnosticsInformationFileCommand : CommandBase
{
}

- (id) init;

/// @brief Full path to the diagnostics information file.
@property(nonatomic, retain) NSString* diagnosticsInformationFilePath;

@end
