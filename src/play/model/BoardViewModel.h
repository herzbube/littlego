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


// -----------------------------------------------------------------------------
/// @brief The BoardViewModel class provides user defaults data to its clients
/// related to normal play.
// -----------------------------------------------------------------------------
@interface BoardViewModel : NSObject
{
}

- (id) init;

- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) bool markLastMove;
@property(nonatomic, assign) bool displayCoordinates;
@property(nonatomic, assign) bool displayPlayerInfluence;
@property(nonatomic, assign) float moveNumbersPercentage;
@property(nonatomic, assign) bool playSound;
@property(nonatomic, assign) bool vibrate;
/// @brief How far from the fingertip should the cross-hair point be displayed
/// when placing stones on the Go board.
///
/// This is a percentage that must be taken into account by whatever algorithm
/// is used to calculate the actual distance. The minimum value that this
/// property can have is 0: This indicates that the cross-hair point must be
/// placed directly under the fingertip. The maximum value of this property is
/// 1.0: This indicates that the algorithm should choose the maximum distance
/// that is appropriate under the circumstances.
@property(nonatomic, assign) float stoneDistanceFromFingertip;
/// @brief Type of information that was selected when the Info view was
/// displayed the last time.
@property(nonatomic, assign) enum InfoType infoTypeLastSelected;
/// @brief Is true if the cross-hair is currently visible on the board view.
///
/// This property does not store a user preference, it stores a part of the
/// current application state.
@property(nonatomic, assign) bool boardViewDisplaysCrossHair;

@end
