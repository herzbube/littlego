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


// System includes
#include <fstream>   // ifstream and ofstream


@interface GtpClient : NSObject
{
@private
  std::ofstream m_commandStream;
  std::ifstream m_responseStream;
  NSThread* m_thread;
}

+ (GtpClient*) clientWithInputPipe:(NSString*)inputPipe outputPipe:(NSString*)outputPipe responseReceiver:(id)aReceiver;
- (void) setCommand:(NSString*)newValue;

@property(retain) id responseReceiver;   // todo: should be private
@property(getter=shouldExit, setter=exit) bool shouldExit;

@end
