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
/// @brief The PlayViewModel class provides user defaults data to its clients
/// that describes the UI characteristics of the Play view.
// -----------------------------------------------------------------------------
@interface PlayViewModel : NSObject
{
}

- (id) init;
- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) bool markLastMove;
@property(nonatomic, assign) bool displayCoordinates;
@property(nonatomic, assign) float moveNumbersPercentage;
@property(nonatomic, assign) bool playSound;
@property(nonatomic, assign) bool vibrate;
@property(nonatomic, retain) UIColor* backgroundColor;
@property(nonatomic, retain) UIColor* boardColor;
@property(nonatomic, assign) float boardOuterMarginPercentage;
@property(nonatomic, retain) UIColor* lineColor;
@property(nonatomic, assign) int boundingLineWidth;
@property(nonatomic, assign) int normalLineWidth;
@property(nonatomic, retain) UIColor* starPointColor;
@property(nonatomic, assign) int starPointRadius;
@property(nonatomic, assign) float stoneRadiusPercentage;
@property(nonatomic, retain) UIColor* crossHairColor;
@property(nonatomic, assign) float maximumZoomScale;
/// @brief How far from the fingertip should the cross-hair point be displayed
/// when placing stones on the Play tab. The unit used by this constant is
/// "distances between two adjacent intersections".
@property(nonatomic, assign) float stoneDistanceFromFingertip;
/// @brief Type of information that was selected when the Info view was
/// displayed the last time.
@property(nonatomic, assign) enum InfoType infoTypeLastSelected;

@end
