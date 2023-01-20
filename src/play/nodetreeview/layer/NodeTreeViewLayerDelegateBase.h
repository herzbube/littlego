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
#import "NodeTreeViewLayerDelegate.h"

// Forward declarations
@class NodeTreeViewMetrics;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewLayerDelegateBase class is the base class for all
/// layer delegates that manage one of the layers that make up the node tree
/// view.
///
/// NodeTreeViewLayerDelegateBase conveniently defines a property that stores a
/// reference to a metrics object that will probably be used by all concrete
/// delegate subclasses. NodeTreeViewLayerDelegateBase also disables implicit
/// animations that normally occur when a delegate draws into a CALayer.
///
/// In addition, NodeTreeViewLayerDelegateBase provides the following simple
/// implementation of the NodeTreeViewLayerDelegate protocol:
/// - Synthesizes the properties @e layer and @e tile (because properties
///   declared in protocols are not auto-synthesized)
/// - In its initializer, creates a new CALayer object and configures that
///   object to use the NodeTreeViewLayerDelegateBase as its delegate. Because
///   of this NodeTreeViewLayerDelegateBase declares itself to adopt the
///   protocol CALayerDelegate, but effectively does not implement any of the
///   methods in that protocol (which is legal since they are all optional).
///   It's the job of the concrete delegate subclass to implement any such
///   methods.
/// - Provides an empty "do-nothing" implementation of notify:eventInfo:().
///   A concrete delegate subclass must override notify:eventInfo:(), otherwise
///   an instance of the concrete delegate class won't react to any events.
/// - Provides an implementation of drawLayer() that invokes the layer's
///   setNeedsDisplay() method if the flag stored in property @e dirty is true.
///   A concrete delegate subclass that does not want to implement its own
///   drawLayer() may therefore simply set the flag to true during
///   notify:eventInfo:() if it wants the layer to be redrawn during the next
///   drawing cycle.
// -----------------------------------------------------------------------------
@interface NodeTreeViewLayerDelegateBase : NSObject <NodeTreeViewLayerDelegate, CALayerDelegate>
{
}

- (id) initWithTile:(id<Tile>)tile metrics:(NodeTreeViewMetrics*)metrics;

/// @name NodeTreeViewLayerDelegate methods
//@{
- (void) drawLayer;
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
//@}

/// @name Helper methods for subclasses
//@{
- (NSArray*) calculateDrawingCellsOnTile;
//@}

/// @brief Object that provides the metrics for drawing elements on the tree
/// node view.
@property(nonatomic, assign) NodeTreeViewMetrics* nodeTreeViewMetrics;

/// @brief Concrete subclasses may set this flag to true if they wish for the
/// layer to be redrawn during the next drawing cycle.
///
/// @see NodeTreeViewLayerDelegateBase class documentation for details.
@property(nonatomic, assign) bool dirty;

@end
