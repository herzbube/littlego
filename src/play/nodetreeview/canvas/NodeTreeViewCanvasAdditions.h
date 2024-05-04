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
#import "NodeTreeViewCanvas.h"


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCanvasAdditions category enhances NodeTreeViewCanvas
/// by adding methods for unit testing support.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface NodeTreeViewCanvas(NodeTreeViewCanvasAdditions)

/// @name Unit testing
//@{
// -----------------------------------------------------------------------------
/// @brief Returns the dictionary that contains the data that is consumed by the
/// node tree view's drawing routines. Key type = NodeTreeViewCellPosition,
/// value type = NSArray with two objects, object 1 type = NodeTreeViewCell,
/// object 2 type = NodeTreeViewBranchTuple.
// -----------------------------------------------------------------------------
- (NSDictionary*) getCellsDictionary;

// -----------------------------------------------------------------------------
/// @brief Returns the dictionary that contains the data that is consumed by the
/// node numbers view's drawing routines. Key type = NodeTreeViewCellPosition,
/// value type = NodeNumbersViewCell.
// -----------------------------------------------------------------------------
- (NSDictionary*) getNodeNumbersViewCellsDictionary;
//@}

@end
