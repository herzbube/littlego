// -----------------------------------------------------------------------------
// Copyright 2019 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BoardSetupModel class provides user defaults data to its clients
/// that is related to the board setup prior to the first move.
// -----------------------------------------------------------------------------
@interface BoardSetupModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) enum GoColor boardSetupStoneColor;
@property(nonatomic, assign) bool doubleTapToZoom;
@property(nonatomic, assign) bool autoEnableBoardSetupMode;
@property(nonatomic, assign) bool changeHandicapAlert;
@property(nonatomic, assign) bool tryNotToPlaceIllegalStones;

@end
