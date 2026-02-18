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
#import "GoUtilities.h"
#import "../main/ModelProvider.h"
#import "../main/Registry.h"
#import "../play/model/TimedPlayModel.h"

#import "../utility/ExceptionUtility.h"


#pragma mark - Initialization of global symbols declared in the header file

// -----------------------------------------------------------------------------
// See header file for documentation of the two constants and the function
// -----------------------------------------------------------------------------
const GoTimeDataValidationResult GoTimeDataValidationResultValid = { true, -1, -1 };
const GoTimeDataValidationResult GoTimeDataValidationResultInvalid = { false, -1, -1 };
GoTimeDataValidationResult GoTimeDataValidationResultMake(bool isTimeDataValid,
                                                          enum GoTimeDataInvalidReason timeDataInvalidReason,
                                                          enum GoTimeDataValidationMode timeDataValidationMode)
{
  return (GoTimeDataValidationResult)
  {
    isTimeDataValid,
    timeDataInvalidReason,
    timeDataValidationMode
  };
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
                                         timeSystem:(GoTimeSystem*)timeSystem
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode;
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
  GoTimeDataValidationResult timeSettingsValidationResult;
  GoTimeDataValidationResult nodeValidationResult;
  GoTimeDataValidationResult previousNodeValidationResult;
};
typedef struct TimeDataValidationContext TimeDataValidationContext;


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoTimeDataValidator.
// -----------------------------------------------------------------------------
@interface GoTimeDataValidator()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoTimeDataValidationMode timeDataValidationMode;
//@}
@end


#pragma mark - GoTimeDataValidator implementation

@implementation GoTimeDataValidator

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed GoTimeDataValidator object that uses the
/// validation mode obtained from the user defaults.
// -----------------------------------------------------------------------------
+ (GoTimeDataValidator*) timeDataValidatorWithUserDefaultsMode
{
  enum GoTimeDataValidationMode timeDataValidationMode = [Registry sharedRegistry].modelProvider.timedPlayModel.timeDataValidationMode;
  return [[[GoTimeDataValidator alloc] initWithTimeDataValidationMode:timeDataValidationMode] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeDataValidator object.
///
/// @note This is the designated initializer of GoTimeDataValidator.
// -----------------------------------------------------------------------------
- (id) initWithTimeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode;
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.timeDataValidationMode = timeDataValidationMode;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoTimeDataValidator object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - GoTimeDataValidator implementation - Public API

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the entire game tree available from
/// @a game.
///
/// As a side effect, updates the properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode in all GoNode objects
/// that this function examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInGameTree:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInGameTree: failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  [self validateTimeDataInNodeTreeInternal:game.nodeModel.rootNode
                                      game:game];
}

// -----------------------------------------------------------------------------
/// @brief Validates the time data in @a node and the subtree descending from
/// @a node.
///
/// As a side effect, updates the properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode in all GoNode objects
/// that this function examines.
///
/// @exception NSInvalidArgumentException Is raised if @a node is @e nil, or if
/// @a game is @e nil.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInSubTree:(GoNode*)node
                              game:(GoGame*)game
{
  if (! node)
  {
    NSString* errorMessage = @"validateTimeDataInSubTree:game: failed, node argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInSubTree:game: failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  [self validateTimeDataInNodeTreeInternal:node
                                      game:game];

}

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the current game variation available from
/// @a game and returns the result. The validation examines the time data in
/// all nodes of the game variation.
///
/// As a side effect, updates the properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode in all GoNode objects
/// that this function examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInCurrentGameVariation:(GoGame*)game
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariation: failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  [self validateTimeDataInCurrentGameVariationInternal:game
                                             untilNode:game.nodeModel.leafNode];
}

// -----------------------------------------------------------------------------
/// @brief Validates the time data in the current game variation available from
/// @a game and returns the result. The validation examines the time data in
/// the nodes starting from the root node up until, and including,
/// @a lastNodeToValidate. @a lastNodeToValidate must be part of the current
/// game variation.
///
/// As a side effect, updates the properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode in all GoNode objects
/// that this function examines.
///
/// @exception NSInvalidArgumentException Is raised if @a game is @e nil, or if
/// @a lastNodeToValidate is @e nil, or if @a lastNodeToValidate is not part of
/// the current game variation.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInCurrentGameVariation:(GoGame*)game
                                      untilNode:(GoNode*)lastNodeToValidate
{
  if (! game)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariation:untilNode: failed, game argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  if (! lastNodeToValidate)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariation:untilNode: failed, lastNodeToValidate argument is nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  GoNodeModel* nodeModel = game.nodeModel;
  bool nodeIsInCurrentGameVariation = [nodeModel indexOfNode:lastNodeToValidate] >= 0;
  if (! nodeIsInCurrentGameVariation)
  {
    NSString* errorMessage = @"validateTimeDataInCurrentGameVariation:untilNode: failed, lastNodeToValidate is not in current game variation";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  [self validateTimeDataInCurrentGameVariationInternal:game
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

  return [self validationStateOfNode:game.nodeModel.leafNode];
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

  return [self validationStateOfNode:game.boardPosition.currentNode];
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

  if (node.timeDataValidationMode == GoTimeDataValidationModePedantic)
  {
    return GoTimeDataValidationResultMake(node.isTimeDataValid,
                                          node.timeDataInvalidReason,
                                          node.timeDataValidationMode);
  }

  // If a node with a move or time data exists we use the validation state of
  // that node.
  // - If the node contains only a move but no time data, or only time data but
  //   no move, then this is a structural problem that was detected in all
  //   validation modes => validation state is guaranteed to be invalid.
  // - If the node contains both a move and time data, then the validation
  //   state depends on the strictness of the validation mode that was used.
  //
  // If no node with a move or time data exists, the supplied node must be at
  // the beginning of the game. In that case we use the validation state of the
  // supplied node itself, which reflects the validation state of the game's
  // time settings.
  GoNode* nodeWithMoveOrTimeData = [GoUtilities nodeWithMostRecentMoveOrTimeData:node];
  GoNode* nodeWithValidationState = (nodeWithMoveOrTimeData
                                     ? nodeWithMoveOrTimeData
                                     : node);

  return GoTimeDataValidationResultMake(nodeWithValidationState.isTimeDataValid,
                                        nodeWithValidationState.timeDataInvalidReason,
                                        nodeWithValidationState.timeDataValidationMode);
}

#pragma mark - GoTimeDataValidator implementation - Internal backends

// -----------------------------------------------------------------------------
/// @brief Internal backend method. Performs no parameter validation, this is
/// the job of the public callers.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInNodeTreeInternal:(GoNode*)startingNode
                                       game:(GoGame*)game

{
  TimeDataValidationContext context;
  [self setupTimeDataValidationContext:&context withNode:startingNode game:game];

  NSMutableArray* stack = [NSMutableArray array];
  NSNull* nullValue = [NSNull null];

  context.currentNode = startingNode;

  while (true)
  {
    while (context.currentNode)
    {
      [self visitNode:&context];
      [self pushContextData:&context onStack:stack nullValue:nullValue];
      [self updatePredecessorNodeTimeData:&context];

      context.currentNode = context.currentNode.firstChild;
    }

    if (stack.count > 0)
    {
      [self popContextData:&context fromStack:stack nullValue:nullValue];

      // We may not be iterating the entire tree, so the starting node may not
      // be the root node and it may therefore have siblings => stop the
      // iteration when we are back on the starting node
      if (context.currentNode == startingNode)
        break;

      context.currentNode = context.currentNode.nextSibling;
    }
    else
    {
      // We're done
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal backend method. Performs no parameter validation, this is
/// the job of the public callers.
// -----------------------------------------------------------------------------
- (void) validateTimeDataInCurrentGameVariationInternal:(GoGame*)game
                                              untilNode:(GoNode*)lastNodeToValidate
{
  GoNodeModel* nodeModel = game.nodeModel;
  int numberOfNodes = nodeModel.numberOfNodes;

  TimeDataValidationContext context;
  [self setupTimeDataValidationContext:&context withNode:nodeModel.rootNode game:game];

  for (int nodeIndex = 0; nodeIndex < numberOfNodes; nodeIndex++)
  {
    context.currentNode = [nodeModel nodeAtIndex:nodeIndex];

    [self visitNode:&context];
    [self updatePredecessorNodeTimeData:&context];

    if (context.currentNode == lastNodeToValidate)
      break;
  }
}

#pragma mark - GoTimeDataValidator implementation - Validation logic

// -----------------------------------------------------------------------------
/// @brief Initializes @a context using time settings information obtained from
/// @a game. If @a node is not the root node, also gathers initialization data
/// from the predecessors of @a node.
// -----------------------------------------------------------------------------
- (void) setupTimeDataValidationContext:(TimeDataValidationContext*)context
                               withNode:(GoNode*)node
                                   game:(GoGame*)game
{
  GoTimeSettings* timeSettings = game.timeSettings;

  context->currentNode = nil;
  context->nodeTimeData = nil;
  context->absoluteTimeSystem = timeSettings.absoluteTimeSystem;
  context->absoluteTimeSystemIsPresent = (context->absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute);
  context->periodBasedTimeSystem = timeSettings.periodBasedTimeSystem;
  context->periodBasedTimeSystemIsPresent = (context->periodBasedTimeSystem.goTimeSystemType != GoTimeSystemTypeNone);
  context->absoluteNodeTimeDataValidator = [self getValidator:context->absoluteTimeSystem.goTimeSystemType];
  context->periodBasedNodeTimeDataValidator = [self getValidator:context->periodBasedTimeSystem.goTimeSystemType];
  context->didSwitchToPeriodBasedTimeSystemBlack = (context->absoluteTimeSystemIsPresent ? false : true);
  context->didSwitchToPeriodBasedTimeSystemWhite = context->didSwitchToPeriodBasedTimeSystemBlack;
  context->predecessorNodeTimeDataBlack = nil;
  context->predecessorNodeTimeDataWhite = nil;
  context->timeSettingsValidationResult = [self validateTimeSettings:timeSettings];
  context->nodeValidationResult = GoTimeDataValidationResultInvalid;

  if (node.isRoot)
  {
    context->previousNodeValidationResult = context->timeSettingsValidationResult;
  }
  else
  {
    // Used to abort the iteration early. Works only if we encounter
    // time data for BOTH players that indicates that the respective player
    // switched to the period time system. If not, the counter will remain at
    // 2 or 1.
    int numberOfMissingInformationPieces = 4;

    // The didSwitch... flags can be true already if no absolute time system
    // is present
    if (context->didSwitchToPeriodBasedTimeSystemBlack)
      numberOfMissingInformationPieces--;
    if (context->didSwitchToPeriodBasedTimeSystemWhite)
      numberOfMissingInformationPieces--;

    GoNode* parentNode = node.parent;
    GoNode* iterNode = parentNode;
    while (iterNode && numberOfMissingInformationPieces > 0)
    {
      GoNodeTimeData* nodeTimeData = iterNode.goNodeTimeData;
      if (nodeTimeData)
      {
        if (nodeTimeData.isTimeDataForBlackPlayer)
        {
          if (! context->predecessorNodeTimeDataBlack)
          {
            context->predecessorNodeTimeDataBlack = nodeTimeData;
            numberOfMissingInformationPieces--;
          }

          if (! nodeTimeData.isRemainingTimeAbsoluteTime && ! context->didSwitchToPeriodBasedTimeSystemBlack)
          {
            context->didSwitchToPeriodBasedTimeSystemBlack = true;
            numberOfMissingInformationPieces--;
          }
        }
        else
        {
          if (! context->predecessorNodeTimeDataWhite)
          {
            context->predecessorNodeTimeDataWhite = nodeTimeData;
            numberOfMissingInformationPieces--;
          }

          if (! nodeTimeData.isRemainingTimeAbsoluteTime && ! context->didSwitchToPeriodBasedTimeSystemWhite)
          {
            context->didSwitchToPeriodBasedTimeSystemWhite = true;
            numberOfMissingInformationPieces--;
          }
        }
      }

      iterNode = iterNode.parent;
    }

    context->previousNodeValidationResult = GoTimeDataValidationResultMake(parentNode.isTimeDataValid,
                                                                           parentNode.timeDataInvalidReason,
                                                                           parentNode.timeDataValidationMode);
  }
}

// -----------------------------------------------------------------------------
/// @brief Validates the content of @a timeSettings. Stores the result in
/// @a timeSettings, but also returns the result.
// -----------------------------------------------------------------------------
- (GoTimeDataValidationResult) validateTimeSettings:(GoTimeSettings*)timeSettings
{
  GoTimeDataValidationResult (^validateTimeSettings)(GoTimeSettings*) = ^ GoTimeDataValidationResult (GoTimeSettings* timeSettings)
  {
    if (timeSettings.hasNoTimeSystems)
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonGameDoesNotUseTimedPlay, self.timeDataValidationMode);
    }
    else if (timeSettings.periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeCustom)
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonCustomTimeSystem, self.timeDataValidationMode);
    }
    else if (timeSettings.absoluteTimeSystem.supportsTimedPlay &&
             timeSettings.absoluteTimeSystem.periodDurationInSeconds > gMaximumRemainingTimeInSeconds)
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeDurationExceedsMaximum, self.timeDataValidationMode);
    }
    else if (timeSettings.periodBasedTimeSystem.supportsTimedPlay)
    {
      if (timeSettings.periodBasedTimeSystem.periodDurationInSeconds > gMaximumRemainingTimeInSeconds)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonPeriodDurationExceedsMaximum, self.timeDataValidationMode);
      else if (timeSettings.periodBasedTimeSystem.extraTimeDurationInSeconds > gMaximumRemainingTimeInSeconds)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonExtraTimeDurationExceedsMaximum, self.timeDataValidationMode);
      else if (timeSettings.periodBasedTimeSystem.minimumNumberOfMovesPerPeriod > gMaximumRemainingNumberOfMovesOrPeriods)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMinimumNumberOfMovesPerPeriodExceedsMaximum, self.timeDataValidationMode);
      else if (timeSettings.periodBasedTimeSystem.numberOfPeriods > gMaximumRemainingNumberOfMovesOrPeriods)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonNumberOfPeriodsExceedsMaximum, self.timeDataValidationMode);
    }

    // No further time system consistency checks needed - initializers of
    // GoTimeSystem and GoTimeSettings prevent combinations that the app does not
    // support.

    return GoTimeDataValidationResultValid;
  };

  GoTimeDataValidationResult validationResult = validateTimeSettings(timeSettings);
  timeSettings.isTimeDataValid = validationResult.isTimeDataValid;
  timeSettings.timeDataInvalidReason = validationResult.timeDataInvalidReason;
  timeSettings.timeDataValidationMode = self.timeDataValidationMode;
  return validationResult;
}

// -----------------------------------------------------------------------------
/// @brief Validates the data found in the node whose reference is stored in
/// property @e currentNode in @a context. Invokes visitNodeTimeData:() if the
/// node contains a GoNodeTimeData object. Stores the validation result in the
/// visited node.
// -----------------------------------------------------------------------------
- (void) visitNode:(TimeDataValidationContext*)context
{
  context->nodeTimeData = context->currentNode.goNodeTimeData;

  // If the mode is not pedantic, the default is the time settings validation
  // result => if the time settings are not valid, then this is propagated
  // to all descendant nodes even though the mode is not pedantic.
  context->nodeValidationResult = (self.timeDataValidationMode == GoTimeDataValidationModePedantic
                                   ? context->previousNodeValidationResult
                                   : context->timeSettingsValidationResult);

  if (context->nodeValidationResult.isTimeDataValid)
  {
    GoMove* move = context->currentNode.goMove;
    GoNodeTimeData* nodeTimeData = context->nodeTimeData;

    bool hasMove = move;
    bool hasNodeTimeData = nodeTimeData;
    if (hasMove != hasNodeTimeData)
    {
      if (hasMove)
        context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMoveNodeHasNoTimeData, self.timeDataValidationMode);
      else
        context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonNonMoveNodeHasTimeData, self.timeDataValidationMode);
    }
    else if (hasMove) // implies that hasNodeTimeData is also true
    {
      if (move.player.black != nodeTimeData.isTimeDataForBlackPlayer)
        context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonMoveAndTimeDataPlayerMismatch, self.timeDataValidationMode);
    }
  }

  if (context->nodeTimeData)
  {
    [self visitNodeTimeData:context];
  }

  context->currentNode.isTimeDataValid = context->nodeValidationResult.isTimeDataValid;
  context->currentNode.timeDataInvalidReason = context->nodeValidationResult.timeDataInvalidReason;
  context->currentNode.timeDataValidationMode = self.timeDataValidationMode;

  if (self.timeDataValidationMode == GoTimeDataValidationModePedantic)
    context->previousNodeValidationResult = context->nodeValidationResult;
}

// -----------------------------------------------------------------------------
/// @brief Validates the data found in the GoNodeTimeData object whose reference
/// is stored in property @e nodeTimeData in @a context. Uses one of the
/// NodeTimeDataValidator objects found in @a context to perform most of the
/// validation logic. Which one is used depends on which time system is in use.
// -----------------------------------------------------------------------------
- (void) visitNodeTimeData:(TimeDataValidationContext*)context
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

  if (context->nodeValidationResult.isTimeDataValid)
  {
    // First perform general validations that don't depend on the time system
    // that is in effect
    if (context->nodeTimeData.remainingTimeInSeconds > gMaximumRemainingTimeInSeconds)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeExceedsMaximum, self.timeDataValidationMode);
    else if (context->nodeTimeData.remainingNumberOfMoves > gMaximumRemainingNumberOfMovesOrPeriods)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesExceedsMaximum, self.timeDataValidationMode);
    else if (context->nodeTimeData.remainingNumberOfPeriods > gMaximumRemainingNumberOfMovesOrPeriods)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsExceedsMaximum, self.timeDataValidationMode);
    else if (context->nodeTimeData.remainingTimeInSeconds < 0)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeNegative, self.timeDataValidationMode);
    else if (context->nodeTimeData.remainingNumberOfMoves < 0)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNegative, self.timeDataValidationMode);
    else if (context->nodeTimeData.remainingNumberOfPeriods < 0)
      context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsNegative, self.timeDataValidationMode);
    else if (context->nodeTimeData.isRemainingTimeAbsoluteTime)
    {
      if (! context->absoluteTimeSystemIsPresent)
        context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeDataFoundWithoutAbsoluteTimeSystem, self.timeDataValidationMode);
      else if (*didSwitchToPeriodBasedTimeSystem)
      {
        if (self.timeDataValidationMode >= GoTimeDataValidationModeStrict)
          context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonAbsoluteTimeSystemDataFoundAfterPeriodBasedTimeSystemData, self.timeDataValidationMode);
      }
    }
    else
    {
      if (! context->periodBasedTimeSystemIsPresent)
        context->nodeValidationResult = GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonPeriodBasedTimeDataFoundWithoutPeriodBasedTimeSystem, self.timeDataValidationMode);
    }

    // If data is still valid, perform validations that depend on the time
    // system that is in effect.
    //
    // Note: If the validation mode is not GoTimeDataValidationModePedantic
    // (where invalidation is propagated to successor nodes),
    // predecessorNodeTimeData could come from a node that does not contain
    // a move, i.e. that node would be marked as containing invalid time data.
    // For comparing GoNodeTimeData values this is not relevant, though. The
    // only thing that is absolutely needed to support timed play is that the
    // CURRENT node contains both a move and a GoNodeTimeData object.
    if (context->nodeValidationResult.isTimeDataValid)
    {
      if (context->nodeTimeData.isRemainingTimeAbsoluteTime)
      {
        context->nodeValidationResult = [context->absoluteNodeTimeDataValidator validateNodeTimeData:context->nodeTimeData
                                                                             predecessorNodeTimeData:predecessorNodeTimeData
                                                                                          timeSystem:context->absoluteTimeSystem
                                                                              timeDataValidationMode:self.timeDataValidationMode];
      }
      else
      {
        // The concrete validators will ignore predecessorNodeTimeData if its
        // property isRemainingTimeAbsoluteTime is true
        context->nodeValidationResult = [context->periodBasedNodeTimeDataValidator validateNodeTimeData:context->nodeTimeData
                                                                                predecessorNodeTimeData:predecessorNodeTimeData
                                                                                             timeSystem:context->periodBasedTimeSystem
                                                                                 timeDataValidationMode:self.timeDataValidationMode];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the appropriate predecessor GoNodeTimeData object in
/// @a context. This method is intended to be used before the validation
/// iteration proceeds to the next node.
// -----------------------------------------------------------------------------
- (void) updatePredecessorNodeTimeData:(TimeDataValidationContext*)context
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
- (void) pushContextData:(TimeDataValidationContext*)context
                 onStack:(NSMutableArray*)stack
               nullValue:(NSNull*)nullValue
{
  [stack addObject:@[context->currentNode,
                     context->predecessorNodeTimeDataBlack ? context->predecessorNodeTimeDataBlack : nullValue,
                     @(context->didSwitchToPeriodBasedTimeSystemBlack),
                     context->predecessorNodeTimeDataWhite ? context->predecessorNodeTimeDataWhite : nullValue,
                     @(context->didSwitchToPeriodBasedTimeSystemWhite),
                     [NSNumber numberWithBool:context->previousNodeValidationResult.isTimeDataValid],
                     @(context->previousNodeValidationResult.timeDataInvalidReason)]];
}

// -----------------------------------------------------------------------------
/// @brief Pops the last element in @a stack and populates @a context with the
/// data found in the element, replacing @a nullValue with @e nil. This is the
/// counterpart to pushContextData:onStack:nullValue:(). This method is intended
/// to be used when iterating over a node tree.
// -----------------------------------------------------------------------------
- (void) popContextData:(TimeDataValidationContext*)context
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
  context->previousNodeValidationResult.isTimeDataValid = [[tuple objectAtIndex:5] boolValue];
  context->previousNodeValidationResult.timeDataInvalidReason = [[tuple objectAtIndex:6] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns a NodeTimeDataValidator object that understands how to
/// validate the time data in a GoNodeTimeData object according to the rules of
/// time system @a timeSystemType. Returns @e nil if @a timeSystemType has an
/// unsupported value.
// -----------------------------------------------------------------------------
- (id<NodeTimeDataValidator>) getValidator:(enum GoTimeSystemType)timeSystemType
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal &&
      currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
  {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanAbsoluteTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      currentNodeTimeData.remainingTimeInSeconds > predecessorNodeTimeData.remainingTimeInSeconds)
  {
    return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingAbsoluteTimeIsIncreasing, timeDataValidationMode);
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows, timeDataValidationMode);

    if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (timeSystem.minimumNumberOfMovesPerPeriod > 1)
    {
      // Remaining number of moves should either decrease (before the period
      // reset), or increase (after the period reset)
      if (currentNodeTimeData.remainingNumberOfMoves == predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant, timeDataValidationMode);

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
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased, timeDataValidationMode);
      }
      else
      {
        if (currentNodeTimeData.remainingTimeInSeconds < predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased, timeDataValidationMode);
      }
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant, timeDataValidationMode);
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows, timeDataValidationMode);

    if (currentNodeTimeData.remainingNumberOfPeriods > timeSystem.numberOfPeriods)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsHigherThanPeriodBasedTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingNumberOfPeriods > predecessorNodeTimeData.remainingNumberOfPeriods)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfPeriodsIsIncreasing, timeDataValidationMode);
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal)
  {
    // periodDurationInSeconds should not be exceeded only on the very first
    // move for which Fischer Timing is in effect. On later moves it may
    // be exceeded when extra time is added.
    if ((! predecessorNodeTimeData || predecessorNodeTimeData.isRemainingTimeAbsoluteTime) &&
      currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows, timeDataValidationMode);
    }

    if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > (predecessorNodeTimeData.remainingTimeInSeconds
                                                      + timeSystem.extraTimeDurationInSeconds))
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows, timeDataValidationMode);
    }

    if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant, timeDataValidationMode);
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows, timeDataValidationMode);

    if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
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
          currentNodeTimeData.remainingNumberOfMoves > 0)
      {
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant, timeDataValidationMode);
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
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesDecreasedButRemainingTimeIncreased, timeDataValidationMode);
      }
      else
      {
        if (currentNodeTimeData.remainingTimeInSeconds < predecessorNodeTimeData.remainingTimeInSeconds)
          return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesIncreasedButRemainingTimeDecreased, timeDataValidationMode);
      }
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant, timeDataValidationMode);
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
                             timeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode
{
  if (timeDataValidationMode >= GoTimeDataValidationModeNormal)
  {
    // periodDurationInSeconds should not be exceeded only on the very first
    // move for which Total Average Timing is in effect. On later moves it may
    // be exceeded when extra time is added.
    if ((! predecessorNodeTimeData || predecessorNodeTimeData.isRemainingTimeAbsoluteTime) &&
      currentNodeTimeData.remainingTimeInSeconds > timeSystem.periodDurationInSeconds)
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanPeriodTimeSystemAllows, timeDataValidationMode);
    }

    if (currentNodeTimeData.remainingNumberOfMoves > timeSystem.minimumNumberOfMovesPerPeriod)
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesHigherThanPeriodBasedTimeSystemAllows, timeDataValidationMode);
  }

  if (timeDataValidationMode >= GoTimeDataValidationModeStrict &&
      predecessorNodeTimeData &&
      ! predecessorNodeTimeData.isRemainingTimeAbsoluteTime)
  {
    if (currentNodeTimeData.remainingTimeInSeconds > (predecessorNodeTimeData.remainingTimeInSeconds
                                                      + timeSystem.periodDurationInSeconds))
    {
      return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingTimeHigherThanExtraTimeAllows, timeDataValidationMode);
    }

    if (timeSystem.minimumNumberOfMovesPerPeriod > 1)
    {
      if (currentNodeTimeData.remainingNumberOfMoves == predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesConstant, timeDataValidationMode);
    }
    else
    {
      // If minimumNumberOfMovesPerPeriod is 1 then remainingNumberOfMoves
      // should always be the same
      if (currentNodeTimeData.remainingNumberOfMoves != predecessorNodeTimeData.remainingNumberOfMoves)
        return GoTimeDataValidationResultMake(false, GoTimeDataInvalidReasonRemainingNumberOfMovesNotConstant, timeDataValidationMode);
    }
  }

  return GoTimeDataValidationResultValid;
}

@end
