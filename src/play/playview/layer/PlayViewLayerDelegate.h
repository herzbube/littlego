// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief Enumerates all events that are relevant for Play view layer
/// delegates.
// -----------------------------------------------------------------------------
enum PlayViewLayerDelegateEvent
{
  /// @brief Occurs when the Play view is initialized, and when the interface
  /// orientation changes.
  PVLDEventRectangleChanged,
  PVLDEventGoGameStarted,
  /// @brief Occurs when a move is played or undone.
  PVLDEventBoardPositionChanged,
  PVLDEventMarkLastMoveChanged,
  /// @brief This event can be treated the same as PVLDEventRectangleChanged
  /// because it fundamentally changes the board geometry.
  PVLDEventDisplayCoordinatesChanged = PVLDEventRectangleChanged,
  PVLDEventMoveNumbersPercentageChanged = PVLDEventMarkLastMoveChanged + 1,
  PVLDEventInconsistentTerritoryMarkupTypeChanged,
  /// @brief The event info object that accompanies this event type is a GoPoint
  /// object that identifies the location of the cross-hair center.
  PVLDEventCrossHairChanged,
  PVLDEventScoringModeEnabled,
  PVLDEventScoringModeDisabled,
  PVLDEventScoreCalculationEnds
};


// -----------------------------------------------------------------------------
/// @brief The PlayViewLayerDelegate protocol defines the interface that all
/// Play view layer delegates must implement.
// -----------------------------------------------------------------------------
@protocol PlayViewLayerDelegate <NSObject>

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
/// each #PlayViewLayerDelegateEvent enumeration value for details about the
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
- (void) notify:(enum PlayViewLayerDelegateEvent)event eventInfo:(id)eventInfo;

/// @brief The layer managed by the delegate.
@property(nonatomic, retain) CALayer* layer;

/// @brief The main view that the layer belongs to.
@property(nonatomic, assign) UIView* mainView;

@end

