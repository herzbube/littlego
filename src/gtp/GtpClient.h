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
/// submitted via submit:(). submit:() must be invoked in the main thread's
/// context; it returns immediately, while the command is processed and passed
/// on to the GtpEngine asynchronously in the secondary thread's context. When
/// GtpClient receives the response from GtpEngine, it posts
/// #gtpResponseReceivedNotification to the default NSNotificationCenter.
/// Clients that have registered for the notification are thus notified of the
/// response, again in the context of the main thread. The GtpResponse object
/// encapsulating the response is associated with the notification.
///
/// @note As a convenience, GtpCommand is capable of submitting itself so that
/// clients do not have to concern themselves with where to obtain an instance
/// of GtpClient.
// -----------------------------------------------------------------------------
@interface GtpClient : NSObject
{
@private
  /// @brief Secondary thread used to communicate with GtpEngine.
  NSThread* m_thread;
}

+ (GtpClient*) clientWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe;
- (void) submit:(GtpCommand*)command;

/// @brief Set this property to true to trigger termination of the secondary
/// thread.
@property(getter=shouldExit, setter=exit) bool shouldExit;

@end
