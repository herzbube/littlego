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
#import "NodeTreeView.h"
#import "NodeTreeTileView.h"
#import "NodeTreeViewMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeView.
// -----------------------------------------------------------------------------
@interface NodeTreeView()
@property(nonatomic, assign) NodeTreeViewMetrics* nodeTreeViewMetrics;
@end


@implementation NodeTreeView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeView object with frame rectangle @a rect and
/// metrics object @a nodeTreeViewMetrics.
///
/// @note This is the designated initializer of NodeTreeView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect nodeTreeViewMetrics:(NodeTreeViewMetrics*)nodeTreeViewMetrics
{
  // Call designated initializer of superclass (TiledScrollView)
  self = [super initWithFrame:rect tileViewClass:[NodeTreeTileView class]];
  if (! self)
    return nil;

  self.nodeTreeViewMetrics = nodeTreeViewMetrics;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.nodeTreeViewMetrics = nil;

  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object that is represented by the cell closest to
/// the view coordinates @a coordinates. Returns @e nil if there is no "closest"
/// cell, or if the closest cell does not represent a GoNode.
///
/// @see NodeTreeViewMetrics::nodeNear:() for details.
// -----------------------------------------------------------------------------
- (GoNode*) nodeNear:(CGPoint)coordinates;
{
  return [self.nodeTreeViewMetrics nodeNear:coordinates];
}

@end
