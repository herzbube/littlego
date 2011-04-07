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
/// @brief The GtpEngine class represents a Go Text Protocol (GTP) engine.
///
/// @ingroup gtp
///
/// GtpClient communicates with its counterpart GtpClient via named pipes.
/// When GtpClient is instantiated using engineWithInputPipe:outputPipe:() it
/// spawns a new secondary thread, then invokes the engine's main method, and
/// finally blocks and waits for the engine's main method to return. It is
/// expected that this happens when the engine receives a "quit" command.
// -----------------------------------------------------------------------------
@interface GtpEngine : NSObject
{
@private
  /// @brief Secondary thread used to communicate with GtpEngine.
  NSThread* m_thread;
}

+ (GtpEngine*) engineWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe;

@end
