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
/// @brief The GtpCommand class represents a Go Text Protocol (GTP) command.
///
/// @ingroup gtp
///
/// GtpCommand is mainly a wrapper around a string that forms the actual GTP
/// command, including all of the command's arguments.
///
/// GtpCommand conveniently knows how to submit itself to the application's
/// GtpClient, thus clients do not have to concern themselves with where to
/// obtain a GtpClient instance.
// -----------------------------------------------------------------------------
@interface GtpCommand : NSObject
{
}

+ (GtpCommand*) command:(NSString*)command;
- (void) submit;

/// @brief The GTP command string, including arguments.
@property(retain) NSString* command;

@end
