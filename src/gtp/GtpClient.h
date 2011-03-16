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


@interface GtpClient : NSObject
{
@private
  NSThread* m_thread;
}

+ (GtpClient*) clientWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe responseReceiver:(id)aReceiver;
- (void) setGtpCommand:(NSString*)newValue;
- (void) submit:(GtpCommand*)command;
- (NSString*) generateMove:(bool)forBlack;

@property(assign) id responseReceiver;   // do not retain to prevent possible retain cycle
@property(getter=shouldExit, setter=exit) bool shouldExit;

@end
