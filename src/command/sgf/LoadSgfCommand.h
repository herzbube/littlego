// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
@class SGFCDocumentReadResult;


// -----------------------------------------------------------------------------
/// @brief The LoadSgfCommand class is responsible for loading an SGF file.
///
/// LoadSgfCommand uses SgfcKit to read the content of the SGF file.
/// LoadSgfCommand performs the read operation with arguments taken from
/// SgfcSettingsModel. LoadSgfCommand makes the result of the operation
/// available as SGFCDocumentReadResult object.
///
/// LoadSgfCommand performs up to two attempts to read the SGF file. The number
/// of attempts is determined by the "encoding mode" user preference. If two
/// read attempts are made the result of both attempts is available separately.
///
/// LoadSgfCommand execution is considered successful if an
/// SGFCDocumentReadResult exists. This means that command execution is
/// successful even if the actual read operation performed by SgfcKit failed
/// due to a fatal error. Whoever invoked LoadSgfCommand is responsible for
/// evaluating the messages in the SGFCDocumentReadResult and taking the
/// appropriate action.
///
/// LoadSgfCommand executes synchronously.
// -----------------------------------------------------------------------------
@interface LoadSgfCommand : CommandBase
{
}

- (id) initWithSgfFilePath:(NSString*)sgfFilePath;

/// @brief SgfcKit object that encapsulates the result of the read operation
/// that was performed with #SgfEncodingModeSingleEncoding.
///
/// Is @e nil if the "encoding mode" user preference specifies
/// #SgfEncodingModeMultipleEncodings.
@property(nonatomic, retain) SGFCDocumentReadResult* sgfDocumentReadResultSingleEncoding;
/// @brief SgfcKit object that encapsulates the result of the read operation
/// that was perform with #SgfEncodingModeMultipleEncodings.
///
/// Is @e nil if the "encoding mode" user preference specifies
/// #SgfEncodingModeSingleEncoding.
///
/// Is also @e nil if the "encoding mode" user preference specifies
/// @e SgfcEncodingModeBoth and the first read operation that was attempted
/// with #SgfEncodingModeMultipleEncodings did not fail with a fatal error.
@property(nonatomic, retain) SGFCDocumentReadResult* sgfDocumentReadResultMultipleEncodings;

@end
