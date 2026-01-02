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
};
typedef struct GoTimeDataValidationResult GoTimeDataValidationResult;

// -----------------------------------------------------------------------------
/// @brief A GoTimeDataValidationResult constant with a value that indicates
/// that time data is valid. The properties @e isTimeDataValid and
/// @e timeDataInvalidReason hold the values @e true and -1, respectively.
// -----------------------------------------------------------------------------
extern const GoTimeDataValidationResult GoTimeDataValidationResultValid;

// -----------------------------------------------------------------------------
/// @brief A GoTimeDataValidationResult constant with a value that indicates
/// that time data is invalid. The properties @e isTimeDataValid and
/// @e timeDataInvalidReason hold the values @e false and -1, respectively.
// -----------------------------------------------------------------------------
extern const GoTimeDataValidationResult GoTimeDataValidationResultInvalid;

// -----------------------------------------------------------------------------
/// @brief Returns a GoTimeDataValidationResult with the specified values.
// -----------------------------------------------------------------------------
GoTimeDataValidationResult GoTimeDataValidationResultMake(bool isTimeDataValid,
                                                          enum GoTimeDataInvalidReason timeDataInvalidReason);

// -----------------------------------------------------------------------------
/// @brief The GoTimeDataValidator class performs time data validation.
///
/// @ingroup go
///
/// All functions in GoTimeDataValidator are class methods, so there is no need
/// to create an instance of GoTimeDataValidator.
// -----------------------------------------------------------------------------
@interface GoTimeDataValidator : NSObject
{
}

+ (GoTimeDataValidationResult) validateTimeDataInNodeTree:(GoGame*)game;
+ (GoTimeDataValidationResult) validateTimeDataInCurrentGameVariation:(GoGame*)game;
+ (GoTimeDataValidationResult) validateTimeDataInCurrentGameVariation:(GoGame*)game
                                                            untilNode:(GoNode*)lastNodeToValidate;
+ (GoTimeDataValidationResult) validationStateOfCurrentGameVariation:(GoGame*)game;
+ (GoTimeDataValidationResult) validationStateOfCurrentNode:(GoGame*)game;
+ (GoTimeDataValidationResult) validationStateOfNode:(GoNode*)node;

@end
