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


// Forward declarations
@protocol Tile;


// -----------------------------------------------------------------------------
/// @brief Enumerates all events that are relevant for node tree view layer
/// delegates.
// -----------------------------------------------------------------------------
enum NodeTreeViewLayerDelegateEvent
{
  /// @brief Is sent whenever there is a change to the size of the elements
  /// that are used to draw the node tree. One typical use of this event is when
  /// the node tree view's zoom level changes.
  NTVLDEventNodeTreeGeometryChanged,
  /// @brief Is sent whenever the layer needs a full redraw although the node
  /// tree geometry did not change. One typical use of this event is when the
  /// tiling mechanism reuses a tile to display content at a different position
  /// on the canvas.
  NTVLDEventInvalidateContent,
  /// @brief Is sent whenever the abstract canvas size changed. The layer's
  /// drawing cells may have changed, and because of that also the content
  /// drawn by the layer. The event is sent only after NodeTreeViewCanvas and
  /// NodeTreeViewMetrics have updated their data.
  NTVLDEventAbstractCanvasSizeChanged,
  /// @brief Is sent whenever the content of the node tree changed. The layer's
  /// drawing cells did not change (or if they did a separate event
  /// #NTVLDEventAbstractCanvasSizeChanged is sent), but the content drawn by
  /// the layer may have changed (the nature of the node tree content change is
  /// not known.
  NTVLDEventNodeTreeContentChanged,
};


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewLayerDelegate protocol defines the interface that all
/// node tree view layer delegates must implement.
// -----------------------------------------------------------------------------
@protocol NodeTreeViewLayerDelegate <NSObject>

@required

/// @brief This method is invoked to notify the delegate that the layer should
/// draw itself now.
///
/// For performance reasons, and for optimizing battery life, the delegate
/// should strive to reduce the layer's drawing to a minimum. For instance,
/// the node connection lines do not need to be redrawn if a new node is created
/// on a different tile.
- (void) drawLayer;

/// @brief This method is invoked to notify the delegate that the specified
/// event has occurred.
///
/// @a eventInfo contains an object whose type is specific to the event type
/// and provides further information about the event. See the documentation of
/// each #NodeTreeViewLayerDelegateEvent enumeration value for details about the
/// type and meaning of @a eventInfo.
///
/// It is the delegate's responsibility to decide whether the event is relevant
/// for the layer it manages, and if it is, to take the appropriate steps so
/// that the layer is properly drawn when the next drawing cycle occurs.
///
/// This method may be invoked several times with different events between two
/// calls to drawLayer(). The delegate must make sure that all relevant updates
/// are coalesced into a single drawing operation when drawLayer() is invoked
/// the next time.
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo;

/// @brief The layer managed by the delegate.
@property(nonatomic, retain) CALayer* layer;

/// @brief The tile that the layer is drawing.
@property(nonatomic, assign) id<Tile> tile;

@end
