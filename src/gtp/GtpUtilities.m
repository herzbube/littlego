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


// Project includes
#import "GtpUtilities.h"
#import "GtpCommand.h"


@implementation GtpUtilities

// -----------------------------------------------------------------------------
/// @brief Creates and submits a GTP command using @a commandString.
///
/// If @a wait is true, the command is executed synchronously. This method does
/// not return, instead it waits until the response for the command has been
/// received, then it invokes @a aSelector on @a aTarget with the response
/// object as the single argument.
///
/// If @a wait is false, the command is executed asynchronously and this method
/// returns immediately. When the response for the command has been received,
/// @a selector will be invoked on @a aTarget.
// -----------------------------------------------------------------------------
+ (void) submitCommand:(NSString*)commandString target:(id)aTarget selector:(SEL)aSelector waitUntilDone:(bool)wait
{
  GtpCommand* command;
  if (wait)
  {
    command = [GtpCommand command:commandString];
    command.waitUntilDone = true;
  }
  else
  {
    command = [GtpCommand command:commandString
                   responseTarget:aTarget
                         selector:aSelector];
  }
  [command submit];
  if (wait)
  {
    [aTarget performSelector:aSelector withObject:command.response];
  }
}

@end
