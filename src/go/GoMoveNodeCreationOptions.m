// -----------------------------------------------------------------------------
// Copyright 2023-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoMoveNodeCreationOptions.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// GoMoveNodeCreationOptions.
// -----------------------------------------------------------------------------
@interface GoMoveNodeCreationOptions()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoNewMoveInsertPolicy newMoveInsertPolicy;
@property(nonatomic, assign, readwrite) enum GoNewMoveInsertPosition newMoveInsertPosition;
//@}
@end


@implementation GoMoveNodeCreationOptions

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoMoveNodeCreationOptions instance
/// with default values. The default insert policy is
/// #GoNewMoveInsertPolicyRetainFutureBoardPositions and the default insert
/// position is #GoNewMoveInsertPositionNewVariationAfterCurrentVariation.
// -----------------------------------------------------------------------------
+ (GoMoveNodeCreationOptions*) moveNodeCreationOptions
{
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [[GoMoveNodeCreationOptions alloc] init];
  if (moveNodeCreationOptions)
    [moveNodeCreationOptions autorelease];

  return moveNodeCreationOptions;
}


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoMoveNodeCreationOptions instance
/// with insert policy #GoNewMoveInsertPolicyReplaceFutureBoardPositions and
/// insert position #GoNewMoveInsertPositionNextBoardPosition.
// -----------------------------------------------------------------------------
+ (GoMoveNodeCreationOptions*) moveNodeCreationOptionsWithInsertPolicyReplaceFutureBoardPositions
{
  GoMoveNodeCreationOptions* moveNodeCreationOptions = [[GoMoveNodeCreationOptions alloc] init];
  if (moveNodeCreationOptions)
  {
    moveNodeCreationOptions.newMoveInsertPolicy = GoNewMoveInsertPolicyReplaceFutureBoardPositions;
    moveNodeCreationOptions.newMoveInsertPosition = GoNewMoveInsertPositionNextBoardPosition;

    [moveNodeCreationOptions autorelease];
  }

  return moveNodeCreationOptions;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoMoveNodeCreationOptions instance
/// with insert policy #GoNewMoveInsertPolicyRetainFutureBoardPositions and the
/// specified insert position @a newMoveInsertPosition. The insert position must
/// not be #GoNewMoveInsertPositionNextBoardPosition.
///
/// @exception NSInvalidArgumentException is raised if @a newMoveInsertPosition
/// is #GoNewMoveInsertPositionNextBoardPosition.
// -----------------------------------------------------------------------------
+ (GoMoveNodeCreationOptions*) moveNodeCreationOptionsWithInsertPolicyRetainFutureBoardPositionsAndInsertPosition:(enum GoNewMoveInsertPosition)newMoveInsertPosition;
{
  if (newMoveInsertPosition == GoNewMoveInsertPositionNextBoardPosition)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"moveNodeCreationOptionsWithInsertPolicyRetainFutureBoardPositionsAndInsertPosition: failed: newMoveInsertPosition = %d", newMoveInsertPosition];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  GoMoveNodeCreationOptions* moveNodeCreationOptions = [[GoMoveNodeCreationOptions alloc] init];
  if (moveNodeCreationOptions)
  {
    moveNodeCreationOptions.newMoveInsertPolicy = GoNewMoveInsertPolicyRetainFutureBoardPositions;
    moveNodeCreationOptions.newMoveInsertPosition = newMoveInsertPosition;

    [moveNodeCreationOptions autorelease];
  }

  return moveNodeCreationOptions;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoMoveNodeCreationOptions object with insert policy
/// #GoNewMoveInsertPolicyRetainFutureBoardPositions and insert position
/// #GoNewMoveInsertPositionNewVariationAfterCurrentVariation.
///
/// @note This is the designated initializer of GoMoveNodeCreationOptions.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.newMoveInsertPolicy = GoNewMoveInsertPolicyRetainFutureBoardPositions;
  self.newMoveInsertPosition = GoNewMoveInsertPositionNewVariationAfterCurrentVariation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoMoveNodeCreationOptions object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoMoveNodeCreationOptions object.
///
/// This method is invoked when GoMoveNodeCreationOptions needs to be
/// represented as a string, i.e. by NSLog, or when the debugger command "po"
/// is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"newMoveInsertPolicy = %d, newMoveInsertPosition = %d", _newMoveInsertPolicy, _newMoveInsertPosition];
}

@end
