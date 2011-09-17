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
#import "FinalScoreCommand.h"
#import "../go/GoGame.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpResponse.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for FinalScoreCommand.
// -----------------------------------------------------------------------------
@interface FinalScoreCommand()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name GTP response handlers
//@{
- (void) gtpResponseReceived:(GtpResponse*)response;
//@}
@end


@implementation FinalScoreCommand

@synthesize game;


// -----------------------------------------------------------------------------
/// @brief Initializes a FinalScoreCommand object.
///
/// @note This is the designated initializer of FinalScoreCommand.
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
    return nil;

  self.game = sharedGame;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this FinalScoreCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.game = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  GtpCommand* command = [GtpCommand command:@"final_score"
                             responseTarget:self
                                   selector:@selector(gtpResponseReceived:)];
  [command submit];

  // Thinking state must change after any of the other things; this order is
  // important for observer notifications
  self.game.computerThinks = true;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered whenever the GTP engine responds to a command.
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  if (! response.status)
  {
    assert(0);
    return;
  }

  // TODO parse result; if Fuego is unable to calculate the score, the raw
  // response text is "? cannot score", which results in response.status
  // becoming false
  self.game.score = response.parsedResponse;

  // Thinking state must change after any of the other things; this order is
  // important for observer notifications
  self.game.computerThinks = false;
}

@end
