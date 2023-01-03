// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewModel.
// -----------------------------------------------------------------------------
@interface NodeTreeViewModel()
@end


@implementation NodeTreeViewModel

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewModel object with user defaults data.
///
/// @note This is the designated initializer of NodeTreeViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.displayNodeTreeView = true;
  self.displayNodeNumbers = true;
  self.condenseMoveNodes = true;
  self.alignMoveNodes = true;
  self.branchingStyle = NodeTreeViewBranchingStyleRightAngle;

  // The number chosen here must fulfill the following criteria:
  // - The number must be greater than 1, so that condensed nodes (which are
  //   represented by a single standalone cell) are drawn smaller than
  //   uncondensed nodes (which are represented by multiple sub-cells that
  //   together make up a multipart cell).
  // - The number must be uneven, so that one of the sub-cells that make up a
  //   multipart cell is at the horizontal center of the multipart cell. This is
  //   important so that vertical lines drawn in the center of the central cell
  //   also appear to be in the center of the entire multipart cell.
  // - The number should be relatively small, because a node symbol is drawn
  //   once for each sub-cell. Many sub-cells would mean that many drawing
  //   operations are necessary to draw a node symbol.
  self.numberOfCellsOfMultipartCell = 3;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:nodeTreeViewKey];
  self.displayNodeTreeView = [[dictionary valueForKey:displayNodeTreeViewKey] boolValue];
  self.condenseMoveNodes = [[dictionary valueForKey:condenseMoveNodesKey] boolValue];
  self.alignMoveNodes = [[dictionary valueForKey:alignMoveNodesKey] boolValue];
  self.branchingStyle = [[dictionary valueForKey:branchingStyleKey] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:self.displayNodeTreeView] forKey:displayNodeTreeViewKey];
  [dictionary setValue:[NSNumber numberWithBool:self.condenseMoveNodes] forKey:condenseMoveNodesKey];
  [dictionary setValue:[NSNumber numberWithBool:self.alignMoveNodes] forKey:alignMoveNodesKey];
  [dictionary setValue:[NSNumber numberWithInt:self.branchingStyle] forKey:branchingStyleKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:nodeTreeViewKey];
}

@end
