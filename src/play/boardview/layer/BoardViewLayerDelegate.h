// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates all events that are relevant for board view layer
/// delegates.
// -----------------------------------------------------------------------------
enum BoardViewLayerDelegateEvent
{
  /// @brief Occurs when the Board view is initialized, when the zoom level
  /// changes, and when the interface orientation changes.
  BVLDEventBoardGeometryChanged,
  BVLDEventGoGameStarted,
  /// @brief Occurs if a new game is started with a different board size.
  BVLDEventBoardSizeChanged,
  /// @brief Is sent whenever the layer needs a full redraw although the board
  /// geometry did not change. One typical use of this event is when the tiling
  /// mechanism reuses a tile to display content at a different position on the
  /// canvas.
  BVLDEventInvalidateContent,
  /// @brief Is sent whenever the board position changes. In some scenarios,
  /// multiple board position changes are coalesced into a single event.
  BVLDEventBoardPositionChanged,
  BVLDEventNumberOfBoardPositionsChanged,
  BVLDEventMarkLastMoveChanged,
  /// @brief This event can be treated the same as BVLDEventBoardGeometryChanged
  /// because it fundamentally changes the board geometry.
  BVLDEventDisplayCoordinatesChanged = BVLDEventBoardGeometryChanged,
  BVLDEventMoveNumbersPercentageChanged = BVLDEventMarkLastMoveChanged + 1,
  BVLDEventInconsistentTerritoryMarkupTypeChanged,
  /// @brief The event info object that accompanies this event type is a GoPoint
  /// object that identifies the location of the cross-hair center. This event
  /// is sent continuously with updated information while a pan gesture is
  /// ongoing. When the gesture ends the event is sent a final time with an
  /// event info object that is @e nil, to indicate that the cross-hair is no
  /// longer visible.
  BVLDEventCrossHairChanged,
  /// @brief The event info object that accompanies this event type is a GoPoint
  /// object that identifies the location of the stone being played. This event
  /// is sent continuously with updated information while a pan gesture is
  /// ongoing.
  BVLDEventPlayStoneDidChange,
  BVLDEventUIAreaPlayModeChanged,
  BVLDEventScoreCalculationEnds,
  BVLDEventMarkNextMoveChanged,
  BVLDEventTerritoryStatisticsChanged,
  /// @brief The event info object that accompanies this event type is a GoPoint
  /// object that identifies the intersection that changed.
  BVLDEventHandicapPointChanged,
  /// @brief The event info object that accompanies this event type is a GoPoint
  /// object that identifies the intersection that changed.
  BVLDEventSetupPointChanged,
  BVLDEventAllSetupStonesDiscarded,
  BVLDEventSelectedSymbolMarkupStyleChanged,
  BVLDEventMarkupPrecedenceChanged,
  /// @brief The event info object that accompanies this event type is an
  /// NSArray that contains 0-3 objects. See the documentation of the
  /// notification #markupOnPointsDidChange for the specification of the
  /// NSArray contents.
  BVLDEventMarkupOnPointsDidChange,
  BVLDEventAllMarkupDiscarded,
  /// @brief The event info object that accompanies this event type is an
  /// NSArray that contains 1) an NSNumber object that holds an @e int value
  /// that is actually a value from the enumeration #GoMarkupSymbol, identifying
  /// the type of the symbol markup element being moved; and 2) a GoPoint object
  /// that identifies the new location of the symbol markup element. This event
  /// is sent continuously with updated information while a pan gesture is
  /// ongoing. When the gesture ends the event is sent a final time with an
  /// event info object that is @e nil, to indicate that the temporarily drawn
  /// symbol is no longer visible.
  BVLDEventMarkupSymbolDidMove,
  /// @brief The event info object that accompanies this event type is an
  /// NSArray that contains 1) an NSNumber object that holds an @e int value
  /// that is actually a value from the enumeration #GoMarkupConnection,
  /// identifying  the type of the connection markup element being moved;
  /// and 2) two GoPoint objects that identify the intersections to connect.
  /// The first GoPoint object is the starting intersection, the second GoPoint
  /// object is the end intersection. This event is sent continuously with
  /// updated information while a pan gesture is ongoing. When the gesture ends
  /// the event is sent a final time with an event info object that is @e nil,
  /// to indicate that the temporarily drawn connection is no longer visible.
  BVLDEventMarkupConnectionDidMove,
  /// @brief The event info object that accompanies this event type is an
  /// NSArray that contains 1) an NSNumber object that holds an @e int value
  /// that is actually a value from the enumeration #GoMarkupLabel, identifying
  /// the type of the label markup element being moved; 2) an NSString object
  /// with the label text being moved; 3) a GoPoint object that identifies
  /// the new location of the label markup element; and 4) an unordered NSArray
  /// with all GoPoint objects in the same row as the GoPoint object at index
  /// position 3 (including that object). This event is sent continuously with
  /// updated information while a pan gesture is ongoing.
  BVLDEventMarkupMarkerDidMove,
  /// @brief The event info object that accompanies this event type has the
  /// same structure as the event info object that accompanies
  /// #BVLDEventMarkupMarkerDidMove.
  BVLDEventMarkupLabelDidMove,
  /// @brief The event info object that accompanies this event type is an
  /// NSArray that contains two GoPoint objects that identify the intersections
  /// that define the selection rectangle (the intersections are located at
  /// diagonally opposite corners of the selection rectangle), and an unordered
  /// NSArray with GoPoint objects that are within the selection rectangle. This
  /// event is sent continuously with updated information while the pan gesture
  /// is ongoing.
  BVLDEventSelectionRectangleDidChange,
};


// -----------------------------------------------------------------------------
/// @brief The BoardViewLayerDelegate protocol defines the interface that all
/// board view layer delegates must implement.
// -----------------------------------------------------------------------------
@protocol BoardViewLayerDelegate <NSObject>

@required

/// @brief This method is invoked to notify the delegate that the layer should
/// draw itself now.
///
/// For performance reasons, and for optimizing battery life, the delegate
/// should strive to reduce the layer's drawing to a minimum. For instance,
/// the board's grid lines do not need to be redrawn if only a Go stone is
/// placed.
- (void) drawLayer;

/// @brief This method is invoked to notify the delegate that the specified
/// event has occurred.
///
/// @a eventInfo contains an object whose type is specific to the event type
/// and provides further information about the event. See the documentation of
/// each #BoardViewLayerDelegateEvent enumeration value for details about the
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
- (void) notify:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo;

/// @brief The layer managed by the delegate.
@property(nonatomic, retain) CALayer* layer;

/// @brief The tile that the layer is drawing.
@property(nonatomic, assign) id<Tile> tile;

@end
