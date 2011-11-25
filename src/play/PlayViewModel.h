// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, assign) bool displayMoveNumbers;
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
@property(nonatomic, assign) int crossHairPointDistanceFromFinger;

@end
