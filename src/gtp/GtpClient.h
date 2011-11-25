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


// This file is #import'ed from pure Objective-C implementations, therefore it
// must not contain any C++ syntax.

// Forward declarations
@class GtpCommand;


// -----------------------------------------------------------------------------
/// @brief The GtpClient class represents a Go Text Protocol (GTP) client.
///
/// @ingroup gtp
///
/// GtpClient communicates with its counterpart GtpEngine via named pipes.
/// When GtpClient is instantiated using clientWithInputPipe:outputPipe:() it
/// spawns a new secondary thread, then blocks and waits for GTP commands to be
/// submitted via submit:(). submit:() is usually (but not necessarily) invoked
/// in the main thread's context. If the command's @e waitUntilDone property is
/// false (the default), submit:() returns immediately, while the command is
/// processed and passed on to the GtpEngine asynchronously in the secondary
/// thread's context. If the command's @e waitUntilDone property is true,
/// submit:() blocks and waits until after the command has been processed and
/// its answer was received.
///
/// @note As a convenience, GtpCommand is capable of submitting itself so that
/// clients do not have to concern themselves with where to obtain an instance
/// of GtpClient.
///
/// Command submission and response receipt are bracketed by a pair of
/// notifications that are sent just before the command is submitted
/// (#gtpCommandWillBeSubmitted), and right after the response to the command
/// was received (#gtpResponseWasReceived). The GtpCommand and GtpResponse
/// objects are attached to their respective notification.
///
/// Clients listening for both notifications are guaranteed to receive
/// #gtpCommandWillBeSubmitted before they receive the matching
/// #gtpResponseWasReceived. Both notifications are delivered in the context of
/// the thread that the command was submitted in (which is not necessarily the
/// main thread).
///
/// After #gtpResponseWasReceived has been delivered, the response target (the
/// object stored in GtpCommand's @e responseTarget property) is notified by
/// invoking the response target selector (the selector stored in GtpCommand's
/// @e responseTargetSelector property). This occurs in the same thread context
/// that the notifications are delivered in.
// -----------------------------------------------------------------------------
@interface GtpClient : NSObject
{
}

+ (GtpClient*) clientWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe;
- (void) submit:(GtpCommand*)command;

/// @brief Set this property to true to trigger termination of the secondary
/// thread.
@property(assign, getter=shouldExit, setter=exit:) bool shouldExit;

@end
