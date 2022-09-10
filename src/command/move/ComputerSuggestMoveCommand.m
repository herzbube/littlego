// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "ComputerSuggestMoveCommand.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../gtp/GtpCommand.h"
#import "../../gtp/GtpResponse.h"
#import "../../utility/ExceptionUtility.h"
#import "../../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ComputerSuggestMoveCommand.
// -----------------------------------------------------------------------------
@interface ComputerSuggestMoveCommand()
@property(nonatomic, assign) enum GoColor color;
@end


@implementation ComputerSuggestMoveCommand

// -----------------------------------------------------------------------------
/// @brief Initializes a ComputerSuggestMoveCommand.
///
/// @a color is the color of the player for which a move suggestion should be
/// generated. @a color must not be @e GoColorNone.
///
/// @exception NSInvalidArgumentException Is raised if @a color i
/// @e GoColorNone.
///
/// @note This is the designated initializer of ComputerSuggestMoveCommand.
// -----------------------------------------------------------------------------
- (id) initWithColor:(enum GoColor)color
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  if (color != GoColorBlack && color != GoColorWhite)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"ComputerSuggestMoveCommand initialization failed, GoColor has invalid value %d", color];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
    [self release];
    return nil;
  }

  self.color = color;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ComputerSuggestMoveCommand
/// object.
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
  NSString* colorString;
  if (self.color == GoColorBlack)
    colorString = @"B";
  else
    colorString = @"W";

  // It's important that we do not wait for the GTP command to complete. This
  // gives the UI the time to update (e.g. status view, activity indicator).
  NSString* commandString = @"reg_genmove ";
  commandString = [commandString stringByAppendingString:colorString];
  GtpCommand* command = [GtpCommand asynchronousCommand:commandString
                                         responseTarget:self
                                               selector:@selector(gtpResponseReceived:)];
  [command submit];

  [GoGame sharedGame].reasonForComputerIsThinking = GoGameComputerIsThinkingReasonMoveSuggestion;

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is triggered when the GTP engine responds to the command submitted
/// in doIt().
// -----------------------------------------------------------------------------
- (void) gtpResponseReceived:(GtpResponse*)response
{
  GoGame* sharedGame = [GoGame sharedGame];
  sharedGame.reasonForComputerIsThinking = GoGameComputerIsThinkingReasonIsNotThinking;

  enum MoveSuggestionType moveSuggestionType = MoveSuggestionTypePlay;
  GoPoint* point = nil;
  NSString* errorMessage = nil;

  if (! response.status)
  {
    errorMessage = [NSString stringWithFormat:@"The computer failed to generate a move suggestion. Reason:\n\n%@", response.parsedResponse];
  }
  else
  {
    NSString* responseString = [response.parsedResponse lowercaseString];
    if ([responseString isEqualToString:@"pass"])
    {
      moveSuggestionType = MoveSuggestionTypePass;

      enum GoMoveIsIllegalReason illegalReason;
      if (! [sharedGame isLegalPassMoveIllegalReason:&illegalReason])
      {
        NSString* illegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
        errorMessage = [NSString stringWithFormat:@"The computer suggested to pass. This is an illegal move. Reason:\n\n%@",
                        illegalReasonString];
      }
    }
    else if ([responseString isEqualToString:@"resign"])
    {
      moveSuggestionType = MoveSuggestionTypeResign;
    }
    else
    {
      moveSuggestionType = MoveSuggestionTypePlay;
      NSString* colorString = [[NSString stringWithGoColor:self.color] lowercaseString];

      point = [sharedGame.board pointAtVertex:responseString];
      if (point)
      {
        enum GoMoveIsIllegalReason illegalReason;
        if (! [sharedGame isLegalMove:point isIllegalReason:&illegalReason])
        {
          NSString* illegalReasonString = [NSString stringWithMoveIsIllegalReason:illegalReason];
          errorMessage = [NSString stringWithFormat:@"The computer suggested to play a %@ stone on intersection %@. This is an illegal move. Reason:\n\n%@",
                          colorString,
                          response.parsedResponse,
                          illegalReasonString];
        }
      }
      else
      {
        errorMessage = [NSString stringWithFormat:@"The computer suggested to play a %@ stone on intersection %@. This intersection does not exist.",
                        colorString,
                        response.parsedResponse];
      }
    }
  }

  if (errorMessage)
  {
    DDLogError(@"%@: %@", [self shortDescription], errorMessage);
    assert(0);
  }

  NSDictionary* dictionary =
  @{
    moveSuggestionColorKey : [NSNumber numberWithInt:self.color],
    moveSuggestionTypeKey : [NSNumber numberWithInt:moveSuggestionType],
    moveSuggestionPointKey : (point ? point : (id)[NSNull null]),
    moveSuggestionErrorMessageKey : (errorMessage ? errorMessage : (id)[NSNull null]),
  };
  [[NSNotificationCenter defaultCenter] postNotificationName:computerPlayerGeneratedMoveSuggestion object:nil userInfo:dictionary];
}

@end
