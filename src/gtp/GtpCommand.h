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
@class GtpResponse;


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
///
/// GtpCommand can be executed synchronously or asynchronously (the default).
/// In the latter case, a target object and selector may be specified that
/// are invoked when the response to the command has been received. This
/// callback always occurs in the main thread context. The assumtpion here is
/// that the command was submitted in the main thread, and asynchronous
/// execution was chosen because the main thread should remain responsive to
/// user interaction.
// -----------------------------------------------------------------------------
@interface GtpCommand : NSObject
{
}

+ (GtpCommand*) command:(NSString*)command;
+ (GtpCommand*) command:(NSString*)command responseTarget:(id)target selector:(SEL)selector;
- (void) submit;

/// @brief The GTP command string, including arguments.
@property(retain) NSString* command;
/// @brief True if execution should wait for the GTP response (i.e. command
/// execution is synchronous).
///
/// The default for this property is false (i.e. command execution is
/// asynchronous).
///
/// If this property is true, @e responseTarget and @e responseTargetSelector
/// are ignored.
@property bool waitUntilDone;
/// @brief The GtpResponse object that "belongs" to this GtpCommand.
///
/// @note GtpCommand does not retain the response object to avoid a retain
/// cycle.
@property(readwrite, assign) GtpResponse* response;
/// @brief The target on which @e selector is performed when the GTP response
/// for this command is received.
///
/// This property is ignored if @e waitUntilDone is true.
///
/// @note GtpCommand retains the response target to make sure that it is still
/// alive when @e responseTargetSelector is to be performed.
@property(retain) id responseTarget;
/// @brief The selector that is performed on @e target when the GTP response
/// for this command is received. The selector must take a single GtpResponse*
/// argument.
@property(assign) SEL responseTargetSelector;

@end
