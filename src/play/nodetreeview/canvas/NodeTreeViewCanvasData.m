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
#import "NodeTreeViewCanvasData.h"


@implementation NodeTreeViewCanvasData

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewCanvasData object.
///
/// @note This is the designated initializer of NodeTreeViewCanvasData.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeMap = [NSMutableDictionary dictionary];
  self.branches = [NSMutableArray array];
  self.branchTuplesForMoveNumbers = [NSMutableArray array];
  self.highestMoveNumberThatAppearsInAtLeastTwoBranches = -1;
  self.currentBoardPositionNode = nil;
  self.cellsDictionary = [NSMutableDictionary dictionary];
  self.highestXPosition = -1;
  self.highestXPositionNode = nil;
  self.highestYPosition = -1;
  self.nodeNumbersViewCellsDictionary = [NSMutableDictionary dictionary];
  self.nodeNumberingTuples = [NSMutableArray array];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewCanvasData object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeMap = nil;
  self.branches = nil;
  self.branchTuplesForMoveNumbers = nil;
  self.currentBoardPositionNode = nil;
  self.cellsDictionary = nil;
  self.highestXPositionNode = nil;
  self.nodeNumbersViewCellsDictionary = nil;
  self.nodeNumberingTuples = nil;
  
  [super dealloc];
}

@end
