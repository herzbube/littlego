// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoTimeDataValidator.h"
#import "GoBoardPosition.h"
#import "GoGame.h"
#import "GoMove.h"
#import "GoNode.h"
#import "GoNodeModel.h"
#import "GoNodeTimeData.h"
#import "GoPlayer.h"
#import "GoTimeSettings.h"
#import "GoTimeSystem.h"
#import "../utility/ExceptionUtility.h"


#pragma mark - Initialization of global symbols declared in the header file

// -----------------------------------------------------------------------------
// See header file for documentation of the two constants and the function
// -----------------------------------------------------------------------------
const GoTimeDataValidationResult GoTimeDataValidationResultValid = { true, -1 };
const GoTimeDataValidationResult GoTimeDataValidationResultInvalid = { false, -1 };
GoTimeDataValidationResult GoTimeDataValidationResultMake(bool isTimeDataValid,
                                                          enum GoTimeDataInvalidReason timeDataInvalidReason)
{
  return (GoTimeDataValidationResult) {isTimeDataValid, timeDataInvalidReason};
}


#pragma mark - Time system specific validators - declarations

@protocol NodeTimeDataValidator <NSObject>
@required
// -----------------------------------------------------------------------------
/// @brief Validates the node time data in @a currentNodeTimeData using the
/// time system specific rules implemented by the validator. The rules are
/// parameterized with the values provided by @a timeSystem.
/// @a predecessorNodeTimeData holds the predecessor node time data for the same
/// player. @a predecessorNodeTimeData is @e nil if @a currentNodeTimeData is
/// the game variation's first GoNodeTimeData object.
// -----------------------------------------------------------------------------
- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem;
@end

@interface AbsoluteNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end

@interface CanadianNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end

@interface JapaneseNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end

@interface FischerNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end

@interface SteadyAverageNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end

@interface TotalAverageNodeTimeDataValidator : NSObject <NodeTimeDataValidator>
{
}
@end


#pragma mark - TimeDataValidationContext struct

// -----------------------------------------------------------------------------
/// @brief The TimeDataValidationContext struct stores contextual data that is
/// needed to validate the time data in a node.
///
/// The goal is the decoupling of the selection logic (i.e. which nodes need to
/// be validated), from the actual validation logic. The validation logic can
/// be made reusable by letting the selection logic pass a
/// TimeDataValidationContext object to the validation logic.
// -----------------------------------------------------------------------------
struct TimeDataValidationContext
{
  GoNode* currentNode;
  GoNodeTimeData* nodeTimeData;
  GoTimeSystem* absoluteTimeSystem;
  bool absoluteTimeSystemIsPresent;
  GoTimeSystem* periodBasedTimeSystem;
  bool periodBasedTimeSystemIsPresent;
  id<NodeTimeDataValidator> absoluteNodeTimeDataValidator;
  id<NodeTimeDataValidator> periodBasedNodeTimeDataValidator;
  bool didSwitchToPeriodBasedTimeSystemBlack;
  bool didSwitchToPeriodBasedTimeSystemWhite;
  GoNodeTimeData* predecessorNodeTimeDataBlack;
  GoNodeTimeData* predecessorNodeTimeDataWhite;
  GoTimeDataValidationResult previousValidationResult;
  bool overallIsTimeDataValid;
};
typedef struct TimeDataValidationContext TimeDataValidationContext;


#pragma mark - GoTimeDataValidator implementation

@implementation GoTimeDataValidator

#pragma mark - GoTimeDataValidator implementation - Public API

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the entire node tree available from
/// @a game and returns the overall result. If the time data in the entire node
/// tree is valid, then the overall result is #GoTimeDataValidationResultValid.
/// Otherwise the overall result is #GoTimeDataValidationResultInvalid.
///
/// As a side effect, updates the properties @e isTimeDataValid and
/// @e timeDataInvalidReason in all GoNode objects that this function
/// examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeDataInNodeTree:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInNodeTree failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return [GoTimeDataValidator validateTimeDataInNodeTreeInternal:game];
}

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the current game variation available from
/// @a game and returns the result. The validation examines the time data in
/// all nodes of the game variation.
///
/// As a side effect, updates the properties @e isTimeDataValid and
/// @e timeDataInvalidReason in all GoNode objects that this function
/// examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeDataInCurrentGameVariation:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariation failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return [GoTimeDataValidator validateTimeDataInCurrentGameVariationInternal:game
                                                                   untilNode:game.nodeModel.leafNode];
}

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the current game variation available from
/// @a game and returns the result. The validation examines the time data in
/// the nodes starting from the root node up until, and including,
/// @a lastNodeToValidate. @a lastNodeToValidate must be part of the current
/// game variation.
///
/// As a side effect, updates the properties @e isTimeDataValid and
/// @e timeDataInvalidReason in all GoNode objects that this function
/// examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil, or if
/// @a lastNodeToValidate is @e nil, or if @a lastNodeToValidate is not part of
/// the current game variation.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeDataInCurrentGameVariation:(GoGame*)game
                                                            untilNode:(GoNode*)lastNodeToValidate
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariationUntilNode failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  if (! lastNodeToValidate)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariationUntilNode failed, lastNodeToValidate argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  GoNodeModel* nodeModel = game.nodeModel;
  bool nodeIsInCurrentGameVariation = [nodeModel indexOfNode:lastNodeToValidate] >= 0;
  if (! nodeIsInCurrentGameVariation)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariationUntilNode failed, lastNodeToValidate is not in current game variation";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return [GoTimeDataValidator validateTimeDataInCurrentGameVariationInternal:game
                                                                   untilNode:lastNodeToValidate];
}

// -----------------------------------------------------------------------------
/// @brief Returns the validation state, i.e. the result of the most recent
/// validation, of the time data in the current game variation available from
/// @a game. Actually, returns the state of the game variation's leaf node.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validationStateOfCurrentGameVariation:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validationStateOfCurrentGameVariation failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return [GoTimeDataValidator validationStateOfNode:game.nodeModel.leafNode];
}

// -----------------------------------------------------------------------------
/// @brief Returns the validation state, i.e. the result of the most recent
/// validation, of the time data in the currently selected node (i.e. the
/// current board position) available from @a game.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validationStateOfCurrentNode:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validationStateOfCurrentNode failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return [GoTimeDataValidator validationStateOfNode:game.boardPosition.currentNode];
}

// -----------------------------------------------------------------------------
/// @brief Returns the validation state, i.e. the result of the most recent
/// validation, of the time data in @a node.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validationStateOfNode:(GoNode*)node
{
  if (! node)
  {
    NSString* errorMessage = @"validationStateOfNode failed, node argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  return GoTimeDataValidationResultMake(node.isTimeDataValid, node.timeDataInvalidReason);
}

#pragma mark - GoTimeDataValidator implementation - Internal backends

// -----------------------------------------------------------------------------
/// @brief Internal backend method. Performs no parameter validation, this is
/// the job of the public callers.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeDataInNodeTreeInternal:(GoGame*)game
{
  TimeDataValidationContext context;
  [GoTimeDataValidator setupTimeDataValidationContext:&context withGame:game];

  NSMutableArray* stack = [NSMutableArray array];
  NSNull* nullValue = [NSNull null];

  context.currentNode = game.nodeModel.rootNode;

  while (true)
  {
    while (context.currentNode)
    {
      [GoTimeDataValidator visitNode:&context];
      [GoTimeDataValidator pushContextData:&context onStack:stack nullValue:nullValue];
      [GoTimeDataValidator updatePredecessorNodeTimeData:&context];

      context.currentNode = context.currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      [GoTimeDataValidator popContextData:&context fromStack:stack nullValue:nullValue];

      context.currentNode = context.currentNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }

  return (context.overallIsTimeDataValid
          ? GoTimeDataValidationResultValid
          : GoTimeDataValidationResultInvalid);
}

// -----------------------------------------------------------------------------
/// @brief Internal backend method. Performs no parameter validation, this is
/// the job of the public callers.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeDataInCurrentGameVariationInternal:(GoGame*)game
                                                                    untilNode:(GoNode*)lastNodeToValidate
{
  TimeDataValidationContext context;
  [GoTimeDataValidator setupTimeDataValidationContext:&context withGame:game];

  GoNodeModel* nodeModel = game.nodeModel;
  int numberOfNodes = nodeModel.numberOfNodes;

  GoNode* node = nil;
  for (int nodeIndex = 0;
       nodeIndex < numberOfNodes && node != lastNodeToValidate;
       nodeIndex++)
  {
    context.currentNode = [nodeModel nodeAtIndex:nodeIndex];

    [GoTimeDataValidator visitNode:&context];
    [GoTimeDataValidator updatePredecessorNodeTimeData:&context];
  }

  return (context.overallIsTimeDataValid
          ? GoTimeDataValidationResultValid
          : GoTimeDataValidationResultInvalid);
}

#pragma mark - GoTimeDataValidator implementation - Validation logic

// -----------------------------------------------------------------------------
/// @brief Initializes @a context using time settings information obtained from
/// @a game.
// -----------------------------------------------------------------------------
+ (void) setupTimeDataValidationContext:(TimeDataValidationContext*)context
                               withGame:(GoGame*)game
{
  GoTimeSettings* timeSettings = game.timeSettings;

  context->currentNode = nil;
  context->nodeTimeData = nil;
  context->absoluteTimeSystem = timeSettings.absoluteTimeSystem;
  context->absoluteTimeSystemIsPresent = (context->absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute);
  context->periodBasedTimeSystem = timeSettings.periodBasedTimeSystem;
  context->periodBasedTimeSystemIsPresent = (context->periodBasedTimeSystem.goTimeSystemType != GoTimeSystemTypeNone);
  context->absoluteNodeTimeDataValidator = [GoTimeDataValidator getValidator:context->absoluteTimeSystem.goTimeSystemType];
  context->periodBasedNodeTimeDataValidator = [GoTimeDataValidator getValidator:context->periodBasedTimeSystem.goTimeSystemType];
  context->didSwitchToPeriodBasedTimeSystemBlack = (context->absoluteTimeSystemIsPresent ? false : true);
  context->didSwitchToPeriodBasedTimeSystemWhite = context->didSwitchToPeriodBasedTimeSystemBlack;
  context->predecessorNodeTimeDataBlack = nil;
  context->predecessorNodeTimeDataWhite = nil;
  context->previousValidationResult = [GoTimeDataValidator validateTimeSettings:timeSettings];
  context->overallIsTimeDataValid = context->previousValidationResult.isTimeDataValid;
}

// -----------------------------------------------------------------------------
/// @brief Validates the content of @a timeSettings.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidationResult) validateTimeSettings:(GoTimeSettings*)timeSettings
{
  // Check for custom time system first, because a custom time system
  // automatically means "no timed play"
  if (timeSettings.periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeCustom)
  {
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonCustomTimeSystem);
  }
  else if (! timeSettings.isGameUsingTimedPlay)
  {
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonGameDoesNotUseTimedPlay);
  }
  else if (timeSettings.absoluteTimeSystem.supportsTimedPlay &&
           timeSettings.absoluteTimeSystem.periodDurationInSeconds > gMaximumRemainingTimeInSeconds)
  {
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum);
  }
  else if (timeSettings.periodBasedTimeSystem.supportsTimedPlay)
  {
    if (timeSettings.periodBasedTimeSystem.periodDurationInSeconds > gMaximumRemainingTimeInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonPeriodDurationExceedsMaximum);
    else if (timeSettings.periodBasedTimeSystem.extraTimeDurationInSeconds > gMaximumRemainingTimeInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum);
    else if (timeSettings.periodBasedTimeSystem.minimumNumberOfMovesPerPeriod > gMaximumRemainingNumberOfMovesOrPeriods)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum);
    else if (timeSettings.periodBasedTimeSystem.numberOfPeriods > gMaximumRemainingNumberOfMovesOrPeriods)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum);
  }

  // No further time system consistency checks needed - initializers of
  // GoTimeSystem and GoTimeSettings prevent combinations that the app does not
  // support.

  return GoTimeDataValidationResultValid;
}

// -----------------------------------------------------------------------------
/// @brief Validates the data found in the node whose reference is stored in
/// property @e currentNode in @a context. Invokes visitNodeTimeData:() if the
/// node contains a GoNodeTimeData object.
// -----------------------------------------------------------------------------
+ (void) visitNode:(TimeDataValidationContext*)context
{
  context->nodeTimeData = context->currentNode.goNodeTimeData;

  if (context->previousValidationResult.isTimeDataValid)
  {
    GoMove* move = context->currentNode.goMove;
    GoNodeTimeData* nodeTimeData = context->nodeTimeData;

    bool hasMove = move;
    bool hasNodeTimeData = nodeTimeData;
    if (hasMove != hasNodeTimeData)
    {
      if (hasMove)
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMoveNodeHasNoTimeData);
      else
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonNonMoveNodeHasTimeData);
    }
    else if (hasMove) // implies that hasNodeTimeData is also true
    {
      if (move.player.black != nodeTimeData.isTimeDataForBlackPlayer)
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch);
    }

    if (context->overallIsTimeDataValid)
      context->overallIsTimeDataValid = context->previousValidationResult.isTimeDataValid;
  }

  if (context->nodeTimeData)
  {
    [GoTimeDataValidator visitNodeTimeData:context];
  }

  context->currentNode.isTimeDataValid = context->previousValidationResult.isTimeDataValid;
  context->currentNode.timeDataInvalidReason = context->previousValidationResult.timeDataInvalidReason;
}

// -----------------------------------------------------------------------------
/// @brief Validates the data found in the GoNodeTimeData object whose reference
/// is stored in property @e nodeTimeData in @a context. Uses one of the
/// NodeTimeDataValidator objects found in @a context to perform most of the
/// validation logic. Which one is used depends on which time system is in use.
// -----------------------------------------------------------------------------
+ (void) visitNodeTimeData:(TimeDataValidationContext*)context
{
  bool* didSwitchToPeriodBasedTimeSystem;
  GoNodeTimeData* predecessorNodeTimeData;
  if (context->nodeTimeData.isTimeDataForBlackPlayer)
  {
    didSwitchToPeriodBasedTimeSystem = &(context->didSwitchToPeriodBasedTimeSystemBlack);
    predecessorNodeTimeData = context->predecessorNodeTimeDataBlack;
  }
  else
  {
    didSwitchToPeriodBasedTimeSystem = &(context->didSwitchToPeriodBasedTimeSystemWhite);
    predecessorNodeTimeData = context->predecessorNodeTimeDataWhite;
  }

  // The switch between time systems can occur only once, and it happens
  // when we encounter the first GoNodeTimeData that does not hold
  // absolute time data.
  if (! *didSwitchToPeriodBasedTimeSystem && ! context->nodeTimeData.isRemainingTimeAbsoluteTime)
    *didSwitchToPeriodBasedTimeSystem = true;

  if (context->previousValidationResult.isTimeDataValid)
  {
    // First perform general validations that don't depend on the time system
    // that is in effect
    if (context->nodeTimeData.remainingTimeInSeconds > gMaximumRemainingTimeInSeconds)
      context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeExceedsMaximum);
    else if (context->nodeTimeData.remainingNumberOfMoves > gMaximumRemainingNumberOfMovesOrPeriods)
      context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum);
    else if (context->nodeTimeData.remainingNumberOfPeriods > gMaximumRemainingNumberOfMovesOrPeriods)
      context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum);
    else if (context->nodeTimeData.isRemainingTimeAbsoluteTime)
    {
      if (! context->absoluteTimeSystemIsPresent)
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem);
      else if (*didSwitchToPeriodBasedTimeSystem)
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData);
    }
    else
    {
      if (! context->periodBasedTimeSystemIsPresent)
        context->previousValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem);
    }

    // If data is still valid, perform validations that depend on the time
    // system that is in effect
    if (context->previousValidationResult.isTimeDataValid)
    {
      if (context->nodeTimeData.isRemainingTimeAbsoluteTime)
      {
        context->previousValidationResult = [context->absoluteNodeTimeDataValidator validateNodeTimeData:context->nodeTimeData
                                                                                 predecessorNodeTimeData:predecessorNodeTimeData
                                                                                              timeSystem:context->absoluteTimeSystem];
      }
      else
      {
        // The concrete validators will ignore predecessorNodeTimeData if its
        // property isRemainingTimeAbsoluteTime is true
        context->previousValidationResult = [context->periodBasedNodeTimeDataValidator validateNodeTimeData:context->nodeTimeData
                                                                                    predecessorNodeTimeData:predecessorNodeTimeData
                                                                                                 timeSystem:context->periodBasedTimeSystem];
      }
    }

    if (context->overallIsTimeDataValid)
      context->overallIsTimeDataValid = context->previousValidationResult.isTimeDataValid;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the appropriate predecessor GoNodeTimeData object in
/// @a context. This method is intended to be used before the validation
/// iteration proceeds to the next node.
// -----------------------------------------------------------------------------
+ (void) updatePredecessorNodeTimeData:(TimeDataValidationContext*)context
{
  if (context->nodeTimeData)
  {
    if (context->nodeTimeData.isTimeDataForBlackPlayer)
      context->predecessorNodeTimeDataBlack = context->nodeTimeData;
    else
      context->predecessorNodeTimeDataWhite = context->nodeTimeData;
  }
}

// -----------------------------------------------------------------------------
/// @brief Pushes data found in @a context onto @a stack, using @a nullValue
/// in place of @e nil (because NSArray cannot store @e nil). This method is
/// intended to be used when iterating over a node tree.
// -----------------------------------------------------------------------------
+ (void) pushContextData:(TimeDataValidationContext*)context
                 onStack:(NSMutableArray*)stack
               nullValue:(NSNull*)nullValue
{
  [stack addObject:@[context->currentNode,
                     context->predecessorNodeTimeDataBlack ? context->predecessorNodeTimeDataBlack : nullValue,
                     @(context->didSwitchToPeriodBasedTimeSystemBlack),
                     context->predecessorNodeTimeDataWhite ? context->predecessorNodeTimeDataWhite : nullValue,
                     @(context->didSwitchToPeriodBasedTimeSystemWhite),
                     [NSNumber numberWithBool:context->previousValidationResult.isTimeDataValid],
                     @(context->previousValidationResult.timeDataInvalidReason)]];
}

// -----------------------------------------------------------------------------
/// @brief Pops the last element in @a stack and populates @a context with the
/// data found in the element, replacing @a nullValue with @e nil. This is the
/// counterpart to pushContextData:onStack:nullValue:(). This method is intended
/// to be used when iterating over a node tree.
// -----------------------------------------------------------------------------
+ (void) popContextData:(TimeDataValidationContext*)context
              fromStack:(NSMutableArray*)stack
              nullValue:(NSNull*)nullValue
{
  NSArray* tuple = stack.lastObject;
  [stack removeLastObject];

  context->currentNode = tuple.firstObject;
  context->predecessorNodeTimeDataBlack = [tuple objectAtIndex:1];
  if ((id)context->predecessorNodeTimeDataBlack == nullValue)
    context->predecessorNodeTimeDataBlack = nil;
  context->didSwitchToPeriodBasedTimeSystemBlack = [[tuple objectAtIndex:2] intValue];
  context->predecessorNodeTimeDataWhite = [tuple objectAtIndex:3];
  if ((id)context->predecessorNodeTimeDataWhite == nullValue)
    context->predecessorNodeTimeDataWhite = nil;
  context->didSwitchToPeriodBasedTimeSystemBlack = [[tuple objectAtIndex:4] intValue];
  context->previousValidationResult.isTimeDataValid = [[tuple objectAtIndex:5] boolValue];
  context->previousValidationResult.timeDataInvalidReason = [[tuple objectAtIndex:6] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns a NodeTimeDataValidator object that understands how to
/// validate the time data in a GoNodeTimeData object according to the rules of
/// time system @a timeSystemType. Returns @e nil if @a timeSystemType has an
/// unsupported value.
// -----------------------------------------------------------------------------
+ (id<NodeTimeDataValidator>) getValidator:(enum GoTimeSystemType)timeSystemType
{
  switch (timeSystemType)
  {
    case GoTimeSystemTypeAbsolute:
      return [[[AbsoluteNodeTimeDataValidator alloc] init] autorelease];
    case GoTimeSystemTypeCanadian:
      return [[[CanadianNodeTimeDataValidator alloc] init] autorelease];
    case GoTimeSystemTypeJapanese:
      return [[[JapaneseNodeTimeDataValidator alloc] init] autorelease];
    case GoTimeSystemTypeFischer:
      return [[[FischerNodeTimeDataValidator alloc] init] autorelease];
    case GoTimeSystemTypeSteadyAverage:
      return [[[SteadyAverageNodeTimeDataValidator alloc] init] autorelease];
    case GoTimeSystemTypeTotalAverage:
      return [[[TotalAverageNodeTimeDataValidator alloc] init] autorelease];
    default:
      // Rely on the caller having ruled out all the other time systems
      return nil;
  }
}

@end

#pragma mark - Time system specific validators - implementations

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Absolute
/// time system.
// -----------------------------------------------------------------------------
@implementation AbsoluteNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingTimeInSeconds < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeNegative);

  if (predecessorNodeTimeData)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > predecessorNodeTimeData.remainingTimeInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing);
  }
  else
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);
  }

  return GoTimeDataValidationResultValid;
}

@end

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Canadian
/// time system.
// -----------------------------------------------------------------------------
@implementation CanadianNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNegative);

  if (predecessorNodeTimeData && ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (timeSystem.minimumNumberOfMovesPerPeriod > 1)
    {
      // Remaining number of moves should either decrease (before the period
      // reset), or increase (after the period reset)
      if (currentNodeTimeData.remainingNumberOfMoves == predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);

      // remainingNumberOfMoves + remainingTimeInSeconds must decrease or
      // increase together. remainingTimeInSeconds may stay the same if a
      // player makes their move faster than the time keeping resolution of the
      // SGF writer.
      // Important: Unlike the Steady Average time validation logic, here we can
      // use "<" to compare remainingNumberOfMoves, because equality has already
      // been ruled out by the check above.
      bool remainingNumberOfMovesHasDecreased = (currentNodeTimeData.remainingNumberOfMoves < predecessorNodeTimeData.remainingNumberOfMoves);
      if (remainingNumberOfMovesHasDecreased)
      {
        if (currentNodeTimeData.remainingTimeInSeconds > predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased);
      }
      else
      {
        if (currentNodeTimeData.remainingTimeInSeconds < predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased);
      }
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
    }
  }

  return GoTimeDataValidationResultValid;
}

@end

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Japanese
/// time system.
// -----------------------------------------------------------------------------
@implementation JapaneseNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfPeriods > timeSystem.numberOfPeriods)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfPeriods < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsNegative);

  if (predecessorNodeTimeData && ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingNumberOfPeriods > predecessorNodeTimeData.remainingNumberOfPeriods)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing);
  }

  return GoTimeDataValidationResultValid;
}

@end

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Fischer
/// time system.
// -----------------------------------------------------------------------------
@implementation FischerNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNegative);

  if (predecessorNodeTimeData && ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > (predecessorNodeTimeData.remainingTimeInSeconds
                                                      + timeSystem.extraTimeDurationInSeconds))
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows);
    }

    if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
  }
  else
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);
  }

  return GoTimeDataValidationResultValid;
}

@end

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Steady Average
/// time system.
// -----------------------------------------------------------------------------
@implementation SteadyAverageNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNegative);

  if (predecessorNodeTimeData && ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (timeSystem.minimumNumberOfMovesPerPeriod > 1)
    {
      // Remaining number of moves should either decrease (before the period
      // reset), or increase (after the period reset). Exception: If the
      // remaining number of moves is 0 (zero) in both time data objects - this
      // we allow because Steady Average time system uses
      // GoUnusedTimeHandlingUseForExtraMoves, i.e. remaining number of moves
      // may stay 0 until all remaining time has been used.
      if (currentNodeTimeData.remainingNumberOfMoves == predecessorNodeTimeData.remainingNumberOfMoves &&
          (currentNodeTimeData.remainingNumberOfMoves >= 0 || predecessorNodeTimeData.remainingNumberOfMoves >= 0))
      {
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);
      }

      // remainingNumberOfMoves + remainingTimeInSeconds must decrease or
      // increase together. remainingTimeInSeconds may stay the same if a
      // player makes their move faster than the time keeping resolution of the
      // SGF writer.
      // Important: Unlike the Canadian time validation logic, here we have to
      // use "<=" to compare remainingNumberOfMoves, because equality has not
      // been ruled out by the check above. We therefore treat an equal
      // remaining number of moves as if they were decreasing, to enforce that
      // in that case remainingTimeInSeconds also decreases.
      bool remainingNumberOfMovesHasDecreased = (currentNodeTimeData.remainingNumberOfMoves <= predecessorNodeTimeData.remainingNumberOfMoves);
      if (remainingNumberOfMovesHasDecreased)
      {
        if (currentNodeTimeData.remainingTimeInSeconds > predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased);
      }
      else
      {
        if (currentNodeTimeData.remainingTimeInSeconds < predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased);
      }
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
    }
  }

  return GoTimeDataValidationResultValid;
}

@end

// -----------------------------------------------------------------------------
/// @brief Validates the node time data using the rules of the Total Average
/// time system.
// -----------------------------------------------------------------------------
@implementation TotalAverageNodeTimeDataValidator

- (GoTimeDataValidationResult) validateNodeTimeData:(GoNodeTimeData*)currentNodeTimeData
                            predecessorNodeTimeData:(GoNodeTimeData*)predecessorNodeTimeData
                                         timeSystem:(GoTimeSystem*)timeSystem
{
  if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows);

  if (currentNodeTimeData.remainingNumberOfMoves < 0)
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNegative);

  if (predecessorNodeTimeData && ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > (predecessorNodeTimeData.remainingTimeInSeconds
                                                      + timeSystem.periodDurationInSeconds))
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows);
    }

    if (timeSystem.minimumNumberOfMovesPerPeriod > 1)
    {
      if (currentNodeTimeData.remainingNumberOfMoves == predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant);
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant);
    }
  }
  else
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanTimeSystemAllows);
  }

  return GoTimeDataValidationResultValid;
}

@end
