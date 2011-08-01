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


// Project includes
#import "PlayViewModel.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewModel.
// -----------------------------------------------------------------------------
@interface PlayViewModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation PlayViewModel

@synthesize markLastMove;
@synthesize displayCoordinates;
@synthesize displayMoveNumbers;
@synthesize playSound;
@synthesize vibrate;
@synthesize backgroundColor;
@synthesize boardColor;
@synthesize boardOuterMarginPercentage;
@synthesize boardInnerMarginPercentage;
@synthesize lineColor;
@synthesize boundingLineWidth;
@synthesize normalLineWidth;
@synthesize starPointColor;
@synthesize starPointRadius;
@synthesize stoneRadiusPercentage;
@synthesize crossHairColor;
@synthesize crossHairPointDistanceFromFinger;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewModel object with user defaults data.
///
/// @note This is the designated initializer of PlayViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.markLastMove = false;
  self.displayCoordinates = false;
  self.displayMoveNumbers = false;
  self.playSound = false;
  self.vibrate = false;
  self.backgroundColor = [UIColor whiteColor];
  self.boardColor = [UIColor orangeColor];
  self.boardOuterMarginPercentage = 0.0;
  self.boardInnerMarginPercentage = 0.0;
  self.lineColor = [UIColor blackColor];
  self.boundingLineWidth = 2;
  self.normalLineWidth = 1;
  self.starPointColor = [UIColor blackColor];
  self.starPointRadius = 3;
  self.stoneRadiusPercentage = 1.0;
  self.crossHairColor = [UIColor greenColor];
  self.crossHairPointDistanceFromFinger = 2;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:playViewKey];
  self.markLastMove = [[dictionary valueForKey:markLastMoveKey] boolValue];
  self.displayCoordinates = [[dictionary valueForKey:displayCoordinatesKey] boolValue];
  self.displayMoveNumbers = [[dictionary valueForKey:displayMoveNumbersKey] boolValue];
  self.playSound = [[dictionary valueForKey:playSoundKey] boolValue];
  self.vibrate = [[dictionary valueForKey:vibrateKey] boolValue];
  self.backgroundColor = [UIColor colorFromHexString:[dictionary valueForKey:backgroundColorKey]];
  self.boardColor = [UIColor colorFromHexString:[dictionary valueForKey:boardColorKey]];
  self.boardOuterMarginPercentage = [[dictionary valueForKey:boardOuterMarginPercentageKey] floatValue];
  self.boardInnerMarginPercentage = [[dictionary valueForKey:boardInnerMarginPercentageKey] floatValue];
  self.lineColor = [UIColor colorFromHexString:[dictionary valueForKey:lineColorKey]];
  self.boundingLineWidth = [[dictionary valueForKey:boundingLineWidthKey] intValue];
  self.normalLineWidth = [[dictionary valueForKey:normalLineWidthKey] intValue];
  self.starPointColor = [UIColor colorFromHexString:[dictionary valueForKey:starPointColorKey]];
  self.starPointRadius = [[dictionary valueForKey:starPointRadiusKey] intValue];
  self.stoneRadiusPercentage = [[dictionary valueForKey:stoneRadiusPercentageKey] floatValue];
  self.crossHairColor = [UIColor colorFromHexString:[dictionary valueForKey:crossHairColorKey]];
  self.crossHairPointDistanceFromFinger = [[dictionary valueForKey:crossHairPointDistanceFromFingerKey] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithBool:self.markLastMove] forKey:markLastMoveKey];
  [dictionary setValue:[NSNumber numberWithBool:self.displayCoordinates] forKey:displayCoordinatesKey];
  [dictionary setValue:[NSNumber numberWithBool:self.displayMoveNumbers] forKey:displayMoveNumbersKey];
  [dictionary setValue:[NSNumber numberWithBool:self.playSound] forKey:playSoundKey];
  [dictionary setValue:[NSNumber numberWithBool:self.vibrate] forKey:vibrateKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.backgroundColor] forKey:backgroundColorKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.boardColor] forKey:boardColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.boardOuterMarginPercentage] forKey:boardOuterMarginPercentageKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.boardInnerMarginPercentage] forKey:boardInnerMarginPercentageKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.lineColor] forKey:lineColorKey];
  [dictionary setValue:[NSNumber numberWithInt:self.boundingLineWidth] forKey:boundingLineWidthKey];
  [dictionary setValue:[NSNumber numberWithInt:self.normalLineWidth] forKey:normalLineWidthKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.starPointColor] forKey:starPointColorKey];
  [dictionary setValue:[NSNumber numberWithInt:self.starPointRadius] forKey:starPointRadiusKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.stoneRadiusPercentage] forKey:stoneRadiusPercentageKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.crossHairColor] forKey:crossHairColorKey];
  [dictionary setValue:[NSNumber numberWithInt:self.crossHairPointDistanceFromFinger] forKey:crossHairPointDistanceFromFingerKey];
  // Note: NSUserDefaults takes care entirely by itself of writing only changed
  // values.
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:playViewKey];
}

@end
