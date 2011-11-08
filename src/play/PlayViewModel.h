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

@property bool markLastMove;
@property bool displayCoordinates;
@property bool displayMoveNumbers;
@property bool playSound;
@property bool vibrate;
@property(retain) UIColor* backgroundColor;
@property(retain) UIColor* boardColor;
@property float boardOuterMarginPercentage;
@property float boardInnerMarginPercentage;
@property(retain) UIColor* lineColor;
@property int boundingLineWidth;
@property int normalLineWidth;
@property(retain) UIColor* starPointColor;
@property int starPointRadius;
@property float stoneRadiusPercentage;
@property(retain) UIColor* crossHairColor;
@property int crossHairPointDistanceFromFinger;

@end
