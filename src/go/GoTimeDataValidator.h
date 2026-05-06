// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoGame;
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The GoTimeDataValidationResult struct holds the data that describes
/// the result of a time data validation operation.
///
/// @ingroup go
// -----------------------------------------------------------------------------
struct GoTimeDataValidationResult
{
  /// @brief True if the time data is valid, false if it is not. In the latter
  /// case, the value of property @e timeDataInvalidReason indicates the reason
  /// for the validation failure.
  ///
  /// See the class documentation of GoNode for details about time (in)validity.
  bool isTimeDataValid;

  /// @brief If property @e isTimeDataValid is true, this property has value -1.
  /// If property @e isTimeDataValid is false, this property usually indicates
  /// the reason why the time data is not valid, but it may also have value -1
  /// if no particular reason for the invalidity is known.
  enum GoTimeDataInvalidReason timeDataInvalidReason;

  /// @brief The mode that was used during the time data validation operation.
  enum GoTimeDataValidationMode timeDataValidationMode;

};
typedef struct GoTimeDataValidationResult GoTimeDataValidationResult;

// -----------------------------------------------------------------------------
/// @brief A GoTimeDataValidationResult constant with a value that indicates
/// that time data is valid. The properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode hold the values
/// @e true, -1 and -1, respectively.
// -----------------------------------------------------------------------------
extern const GoTimeDataValidationResult GoTimeDataValidationResultValid;

// -----------------------------------------------------------------------------
/// @brief A GoTimeDataValidationResult constant with a value that indicates
/// that time data is invalid. The properties @e isTimeDataValid,
/// @e timeDataInvalidReason and @e timeDataValidationMode hold the values
/// @e false, -1 and -1, respectively.
// -----------------------------------------------------------------------------
extern const GoTimeDataValidationResult GoTimeDataValidationResultInvalid;

// -----------------------------------------------------------------------------
/// @brief Returns a GoTimeDataValidationResult with the specified values.
// -----------------------------------------------------------------------------
GoTimeDataValidationResult GoTimeDataValidationResultMake(bool isTimeDataValid,
                                                          enum GoTimeDataInvalidReason timeDataInvalidReason,
                                                          enum GoTimeDataValidationMode timeDataValidationMode);

// -----------------------------------------------------------------------------
/// @brief The GoTimeDataValidator class performs time data validation.
///
/// @ingroup go
///
/// When GoTimeDataValidator performs time data validation, it examines either
/// the entire node tree, an entire game variation, or a part of a game
/// variation up until a given node. In all cases, GoTimeDataValidator visits
/// nodes starting from the root node and stores the result of the validation
/// in each visited node's properties @e isTimeDataValid and
/// @e timeDataInvalidReason.
///
/// At the very beginning, GoTimeDataValidator examines the validity of the
/// game's time settings. It stores the result of the time settings validation
/// in the game's root node. GoTimeDataValidator considers time settings valid
/// only if the app is capable of conducting timed play with those settings.
/// This means that if the user starts a game without timed play, the root node
/// will indicate that it has invalid time data. Much the same, if an .sgf file
/// is loaded from the archive with time settings that the app does not
/// understand/support, the root node will indicate that it has invalid time
/// data, and GoTimeDataValidator will propgate that invalidity to the entire
/// node tree.
///
/// Actual time data is allowed to occur only in nodes that contain a move, and
/// vice versa in a game with timed play every move must be accompanied by time
/// data. Based on this, the following scenarios can be distinguished:
/// - When GoTimeDataValidator finds a node that contains a move but no time
///   data, or time data but no move, then that node is considered to contain
///   invalid time data.
/// - When GoTimeDataValidator finds a node that contains neither a move nor
///   time data, then that node is considered to contain valid time data. This
///   may seem unexpected at first glance, since the node does not actually
///   contain time data, but it is necessary to support
///   #GoTimeDataValidationModePedantic where successor nodes inherit the
///   validation state of their predecessor node.
/// - When GoTimeDataValidator finds a node that contains both a move and time
///   data, it validates that time data first on its own, and then in relation
///   to the move in the same node, in relation to the game's time settings, and
///   in relation to the preceding time data.
///
/// As a result of a validation operation, all examined nodes contain a
/// validation state which can be used to determine whether or not to start
/// a player's clock when the currently selected node changes.
///
/// When a new node is created, it inherits the valid state of its parent node.
/// - If the parent node has invalid time data, then the app cannot suddenly
///   create valid time data, therefore the new node must be marked to also have
///   invalid time data.
/// - If the parent node has valid time data, it is assumed that the app will
///   continue to create valid time data, therefore the new node can also be
///   marked as having valid time data.
// -----------------------------------------------------------------------------
@interface GoTimeDataValidator : NSObject
{
}

+ (GoTimeDataValidator*) timeDataValidatorWithUserDefaultsMode;

- (id) initWithTimeDataValidationMode:(enum GoTimeDataValidationMode)timeDataValidationMode;

- (void) validateTimeDataInGameTree:(GoGame*)game;
- (void) validateTimeDataInSubTree:(GoNode*)node
                              game:(GoGame*)game;
- (void) validateTimeDataInCurrentGameVariation:(GoGame*)game;
- (void) validateTimeDataInCurrentGameVariation:(GoGame*)game
                                      untilNode:(GoNode*)lastNodeToValidate;
+ (GoTimeDataValidationResult) validationStateOfCurrentGameVariation:(GoGame*)game;
+ (GoTimeDataValidationResult) validationStateOfCurrentNode:(GoGame*)game;
+ (GoTimeDataValidationResult) validationStateOfNode:(GoNode*)node;

@property(nonatomic, assign, readonly) enum GoTimeDataValidationMode timeDataValidationMode;

@end
