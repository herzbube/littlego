// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "InterruptComputerCommand.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpClient.h"
#import "../../main/ApplicationDelegate.h"


@implementation InterruptComputerCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a InterruptComputerCommand object.
///
/// @note This is the designated initializer of InterruptComputerCommand.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  GoGame* sharedGame = [GoGame sharedGame];
  assert(sharedGame);
  if (! sharedGame)
  {
    DDLogError(@"%@: GoGame object is nil", [self shortDescription]);
    return nil;
  }
  assert(sharedGame.isComputerThinking);
  if (! sharedGame.isComputerThinking)
  {
    DDLogError(@"%@: Computer is not thinking", [self shortDescription]);
    return nil;
  }

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this InterruptComputerCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  GtpClient* gtpClient = delegate.gtpClient;
  [gtpClient interrupt];
  return true;
}

@end
