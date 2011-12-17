// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GtpCommand;


// -----------------------------------------------------------------------------
/// @brief The GtpResponse class represents a Go Text Protocol (GTP) response.
///
/// @ingroup gtp
///
/// GtpResponse is mainly a wrapper around a string that forms the actual GTP
/// response. The raw response includes the status prefix, while the parsed
/// response does not.
// -----------------------------------------------------------------------------
@interface GtpResponse : NSObject
{
}

+ (GtpResponse*) response:(NSString*)response toCommand:(GtpCommand*)command;
- (NSString*) parsedResponse;

/// @brief The raw response string, which includes the status prefix.
@property(nonatomic, retain, readonly) NSString* rawResponse;
/// @brief The GtpCommand object that this GtpResponse "belongs" to.
///
/// @note GtpResponse does not retain the command object to avoid a retain
/// cycle.
@property(nonatomic, assign, readonly) GtpCommand* command;
/// @brief The response status, i.e. whether command execution was successful
/// (status is true) or not (status is false).
@property(nonatomic, assign, readonly) bool status;

@end
