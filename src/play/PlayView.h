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


// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class GoPoint;


// TODO things to document:
// - calculate only with integer types, use half pixel "translation"; do not
//   turn off anti-aliasing
//   http://stackoverflow.com/questions/2488115/how-to-set-up-a-user-quartz2d-coordinate-system-with-scaling-that-avoids-fuzzy-dr
// - all calculations rely on the fact the coordinate system origin is in the
//   top-left corner
@interface PlayView : UIView
{
}

- (GoPoint*) crossHairPointAt:(CGPoint)coordinates;
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove;

@property(retain) UIColor* viewBackgroundColor;
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

@property CGRect previousDrawRect;
@property bool portrait;
@property int boardSize;
@property int boardOuterMargin;  // distance to view edge
@property int boardInnerMargin;  // distance to grid
@property int topLeftBoardCornerX;
@property int topLeftBoardCornerY;
@property int topLeftPointX;
@property int topLeftPointY;
@property int pointDistance;
@property int lineLength;

@property(retain) GoPoint* crossHairPoint;
@property bool crossHairPointIsLegalMove;

@property(nonatomic, retain) IBOutlet UILabel* statusLine;

@end
