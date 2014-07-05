// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewLayerDelegate.h"

// Forward declarations
@class BoardViewMetrics;


// -----------------------------------------------------------------------------
/// @brief The BoardViewLayerDelegateBase class is the base class for all layer
/// delegates that manage one of the layers that make up the board view.
///
/// BoardViewLayerDelegateBase conveniently defines a property that stores a
/// reference to a metrics object that will probably be used by all concrete
/// delegate subclasses. BoardViewLayerDelegateBase also disables implicit
/// animations that normally occur when a delegate draws into a CALayer.
///
/// In addition, BoardViewLayerDelegateBase provides the following simple
/// implementation of the BoardViewLayerDelegate protocol:
/// - Synthesizes the properties @e layer and @e tile (because properties
///   declared in protocols are not auto-synthesized)
/// - In its initializer, creates a new CALayer object and configures that
///   object to use the BoardViewLayerDelegateBase as its delegate.
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
@interface BoardViewLayerDelegateBase : NSObject <BoardViewLayerDelegate>
{
}

- (id) initWithTile:(id<Tile>)tile metrics:(BoardViewMetrics*)metrics;

/// @name BoardViewLayerDelegate methods
//@{
- (void) drawLayer;
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo;
//@}

/// @brief Object that provides the metrics for drawing elements on the Play
/// view.
@property(nonatomic, retain) BoardViewMetrics* boardViewMetrics;
/// @brief Concrete subclasses may set this flag to true if they wish for the
/// layer to be redrawn during the next drawing cycle.
///
/// @see BoardViewLayerDelegateBase class documentation for details.
@property(nonatomic, assign) bool dirty;

@end
