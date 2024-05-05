// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewBranchTuple.h"

@implementation NodeTreeViewBranchTuple

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewBranchTuple object.
///
/// @note This is the designated initializer of NodeTreeViewBranchTuple.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // Only initialize the one member variable that needs to be retained, so that
  // we can keep memory management inside this class. Whoever is creating the
  // NodeTreeViewBranchTuple object is responsible for initializing the other
  // member variables.
  self->childBranches = [NSMutableArray array];
  [self->childBranches retain];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewBranchTuple object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (self->childBranches)
  {
    [self->childBranches release];
    self->childBranches = nil;
  }

  [super dealloc];
}

@end
