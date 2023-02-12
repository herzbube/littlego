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
#import "NodeTreeViewLayerDelegateBase.h"

// Forward declarations
@class NodeTreeViewCanvas;
@class NodeTreeViewModel;


// -----------------------------------------------------------------------------
/// @brief The NodeNumbersLayerDelegate class is responsible for drawing the
/// node numbers in a strip along the horizontal edge of the node tree view.
// -----------------------------------------------------------------------------
@interface NodeNumbersLayerDelegate : NodeTreeViewLayerDelegateBase
{
}

- (id) initWithTile:(id<Tile>)tile
            metrics:(NodeTreeViewMetrics*)metrics
             canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
              model:(NodeTreeViewModel*)nodeTreeViewModel;

@end
