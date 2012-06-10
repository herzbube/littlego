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


// -----------------------------------------------------------------------------
/// @brief The GtpLogItem class collects data that describes a GTP command and
/// its response.
// -----------------------------------------------------------------------------
@interface GtpLogItem : NSObject <NSCoding>
{
}

- (id) init;
- (UIImage*) imageRepresentingResponseStatus;

/// @brief The command that was submitted.
@property(nonatomic, retain) NSString* commandString;
/// @brief String representation of the timestamp when the command was
/// submitted.
@property(nonatomic, retain) NSString* timeStamp;
/// @brief True if this GtpLogItem has response data for the command. If this
/// property is false, the remaining response properties have undefined values.
@property(nonatomic, assign) bool hasResponse;
/// @brief True if the response indicates that command execution was successful,
/// false if not.
///
/// If @e hasResponse is false the value of this property is undefined
@property(nonatomic, assign) bool responseStatus;
/// @brief The parsed response string.
///
/// If @e hasResponse is false the value of this property is undefined
@property(nonatomic, retain) NSString* parsedResponseString;
/// @brief The raw response string.
///
/// If @e hasResponse is false the value of this property is undefined
@property(nonatomic, retain) NSString* rawResponseString;

@end
