// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeCreationOptions.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeCreationOptions.
// -----------------------------------------------------------------------------
@interface GoNodeCreationOptions()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoNewNodeInsertPosition newNodeInsertPosition;
@property(nonatomic, assign, readwrite) enum GoNewNodePostInsertAction newNodePostInsertAction;
//@}
@end


@implementation GoNodeCreationOptions

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoNodeCreationOptions instance
/// with insert position
/// #GoNewNodeInsertPositionNewVariationAfterCurrentVariation and post-insert
/// action #GoNewNodePostInsertActionDiscardAndChangeCurrentGameVariation.
///
/// The effect of this combination is that the new game variation started by the
/// new node will replace the current game variation.
// -----------------------------------------------------------------------------
+ (GoNodeCreationOptions*) nodeCreationOptions
{
  GoNodeCreationOptions* nodeCreationOptions = [[GoNodeCreationOptions alloc] init];
  if (nodeCreationOptions)
    [nodeCreationOptions autorelease];

  return nodeCreationOptions;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GoNodeCreationOptions instance
/// with the specified insert position @a newNodeInsertPosition and the
/// specified post-insert action @a newNodePostInsertAction.
///
/// @exception NSInvalidArgumentException is raised if @a newNodeInsertPosition
/// is #GoNewNodeInsertPositionNextBoardPosition and @a newNodePostInsertAction
/// is #GoNewNodePostInsertActionDiscardAndChangeCurrentGameVariation, because
/// this combination would mean that the new node is being discarded, which
/// does not make sense. In addition, the new node would thus become an invalid
/// argument when specified to changeToVariationContainingNode:().
// -----------------------------------------------------------------------------
+ (GoNodeCreationOptions*) nodeCreationOptionsWithInsertPosition:(enum GoNewNodeInsertPosition)newNodeInsertPosition
                                                postInsertAction:(enum GoNewNodePostInsertAction)newNodePostInsertAction
{
  if (newNodeInsertPosition == GoNewNodeInsertPositionNextBoardPosition &&
      newNodePostInsertAction == GoNewNodePostInsertActionDiscardAndChangeCurrentGameVariation)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"nodeCreationOptionsWithInsertPosition:postInsertAction: failed: newNodeInsertPosition = %d, newNodePostInsertAction = %d", newNodeInsertPosition, newNodePostInsertAction];
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  GoNodeCreationOptions* nodeCreationOptions = [[GoNodeCreationOptions alloc] init];
  if (nodeCreationOptions)
  {
    nodeCreationOptions.newNodeInsertPosition = newNodeInsertPosition;
    nodeCreationOptions.newNodePostInsertAction = newNodePostInsertAction;

    [nodeCreationOptions autorelease];
  }

  return nodeCreationOptions;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeCreationOptions object with insert position
/// #GoNewNodeInsertPositionNewVariationAfterCurrentVariation and post-insert
/// action #GoNewNodePostInsertActionDiscardAndChangeCurrentGameVariation.
///
/// The effect of this combination is that the new game variation started by the
/// new node will replace the current game variation.
///
/// @note This is the designated initializer of GoNodeCreationOptions.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.newNodeInsertPosition = GoNewNodeInsertPositionNewVariationAfterCurrentVariation;
  self.newNodePostInsertAction = GoNewNodePostInsertActionDiscardAndChangeCurrentGameVariation;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeCreationOptions object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoNodeCreationOptions object.
///
/// This method is invoked when GoNodeCreationOptions needs to be represented as
/// a string, i.e. by NSLog, or when the debugger command "po" is used on the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"newNodeInsertPosition = %d, newNodePostInsertAction = %d", _newNodeInsertPosition, _newNodePostInsertAction];
}

@end
