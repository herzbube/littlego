// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// GtpClient communicates with its counterpart GtpEngine via C++ Standard
/// Library I/O streams. When GtpClient is instantiated using
/// clientWithStreamBuffers:() it spawns a new secondary thread, then blocks
/// and waits for GTP commands to be submitted via submit:(). submit:() is
/// usually (but not necessarily) invoked in the main thread's context. If the
/// command's @e waitUntilDone property is false, submit:() returns immediately,
/// while the command is processed and passed on to the GtpEngine asynchronously
/// in the secondary thread's context. If the command's @e waitUntilDone
/// property is true, submit:() blocks and waits until after the command has
/// been processed and its answer was received.
///
/// @note As a convenience, GtpCommand is capable of submitting itself so that
/// clients do not have to concern themselves with where to obtain an instance
/// of GtpClient.
///
///
/// @par Public notifications
///
/// Command submission and response receipt are bracketed by a pair of
/// notifications that are sent just before the command is submitted
/// (#gtpCommandWillBeSubmitted), and right after the response to the command
/// was received (#gtpResponseWasReceived). The GtpCommand and GtpResponse
/// objects are attached to their respective notification.
///
/// Observers listening for both notifications are guaranteed to receive
/// #gtpCommandWillBeSubmitted before they receive the matching
/// #gtpResponseWasReceived. Both notifications are delivered in the context of
/// the secondary thread that processes commands.
///
///
/// @par Private notification of response target
///
/// In addition to #gtpResponseWasReceived, which is sent to the general public,
/// the response target (the object stored in GtpCommand's @e responseTarget
/// property) is also privately notified by invoking the response target
/// selector (the selector stored in GtpCommand's @e responseTargetSelector
/// property). This notification occurs in the context of the thread that
/// submitted the command (which may or may not be the main thread).
///
/// There is no guarantee as to who is notified first of a GTP response: The
/// response target via its selector, or any public observers listening for
/// #gtpResponseWasReceived.
///
/// Specification of a response target is optional. If no response target is
/// specified for a GtpCommand, no private notification is sent.
// -----------------------------------------------------------------------------
@interface GtpClient : NSObject
{
}

+ (GtpClient*) clientWithStreamBuffers:(NSArray*)streamBuffers;
- (void) submit:(GtpCommand*)command;
- (void) interrupt;

/// @brief Set this property to true to trigger termination of the secondary
/// thread.
@property(assign, getter=shouldExit, setter=exit:) bool shouldExit;

@end
