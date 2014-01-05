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


// Project includes
#import "PlayViewModel.h"
#import "../../utility/NSStringAdditions.h"
#import "../../utility/UIColorAdditions.h"


@implementation PlayViewModel

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
  self.displayPlayerInfluence = displayPlayerInfluenceDefault;
  self.moveNumbersPercentage = 0.0;
  self.playSound = false;
  self.vibrate = false;
  self.backgroundColor = [UIColor whiteColor];
  self.boardColor = [UIColor orangeColor];
  self.lineColor = [UIColor blackColor];
  self.boundingLineWidth = 2;
  self.normalLineWidth = 1;
  self.starPointColor = [UIColor blackColor];
  self.starPointRadius = 3;
  self.stoneRadiusPercentage = 1.0;
  self.crossHairColor = [UIColor greenColor];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.maximumZoomScale = iPhoneMaximumZoomScaleMaximum;
  else
    self.maximumZoomScale = iPadMaximumZoomScaleMaximum;
  self.stoneDistanceFromFingertip = stoneDistanceFromFingertipDefault;
  self.infoTypeLastSelected = ScoreInfoType;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.backgroundColor = nil;
  self.boardColor = nil;
  self.lineColor = nil;
  self.starPointColor = nil;
  self.crossHairColor = nil;
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
  self.displayPlayerInfluence = [[dictionary valueForKey:displayPlayerInfluenceKey] boolValue];
  self.moveNumbersPercentage = [[dictionary valueForKey:moveNumbersPercentageKey] floatValue];
  self.playSound = [[dictionary valueForKey:playSoundKey] boolValue];
  self.vibrate = [[dictionary valueForKey:vibrateKey] boolValue];
  self.backgroundColor = [UIColor colorFromHexString:[dictionary valueForKey:backgroundColorKey]];
  self.boardColor = [UIColor colorFromHexString:[dictionary valueForKey:boardColorKey]];
  self.lineColor = [UIColor colorFromHexString:[dictionary valueForKey:lineColorKey]];
  self.boundingLineWidth = [[dictionary valueForKey:[boundingLineWidthKey stringByAppendingDeviceSuffix]] intValue];
  self.normalLineWidth = [[dictionary valueForKey:normalLineWidthKey] intValue];
  self.starPointColor = [UIColor colorFromHexString:[dictionary valueForKey:starPointColorKey]];
  self.starPointRadius = [[dictionary valueForKey:[starPointRadiusKey stringByAppendingDeviceSuffix]] intValue];
  self.stoneRadiusPercentage = [[dictionary valueForKey:stoneRadiusPercentageKey] floatValue];
  self.crossHairColor = [UIColor colorFromHexString:[dictionary valueForKey:crossHairColorKey]];
  self.maximumZoomScale = [[dictionary valueForKey:[maximumZoomScaleKey stringByAppendingDeviceSuffix]] floatValue];
  self.stoneDistanceFromFingertip = [[dictionary valueForKey:[stoneDistanceFromFingertipKey stringByAppendingDeviceSuffix]] floatValue];
  self.infoTypeLastSelected = [[dictionary valueForKey:infoTypeLastSelectedKey] intValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  // Obtain a dictionary with all keys, even device-specific ones, so that we
  // can simply overwrite the old with the new values and don't have to care
  // about creating device-specific keys that we don't use on this device.
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:playViewKey]];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:[NSNumber numberWithBool:self.markLastMove] forKey:markLastMoveKey];
  [dictionary setValue:[NSNumber numberWithBool:self.displayCoordinates] forKey:displayCoordinatesKey];
  [dictionary setValue:[NSNumber numberWithBool:self.displayPlayerInfluence] forKey:displayPlayerInfluenceKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.moveNumbersPercentage] forKey:moveNumbersPercentageKey];
  [dictionary setValue:[NSNumber numberWithBool:self.playSound] forKey:playSoundKey];
  [dictionary setValue:[NSNumber numberWithBool:self.vibrate] forKey:vibrateKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.backgroundColor] forKey:backgroundColorKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.boardColor] forKey:boardColorKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.lineColor] forKey:lineColorKey];
  [dictionary setValue:[NSNumber numberWithInt:self.boundingLineWidth] forKey:[boundingLineWidthKey stringByAppendingDeviceSuffix]];
  [dictionary setValue:[NSNumber numberWithInt:self.normalLineWidth] forKey:normalLineWidthKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.starPointColor] forKey:starPointColorKey];
  [dictionary setValue:[NSNumber numberWithInt:self.starPointRadius] forKey:[starPointRadiusKey stringByAppendingDeviceSuffix]];
  [dictionary setValue:[NSNumber numberWithFloat:self.stoneRadiusPercentage] forKey:stoneRadiusPercentageKey];
  [dictionary setValue:[UIColor hexStringFromUIColor:self.crossHairColor] forKey:crossHairColorKey];
  [dictionary setValue:[NSNumber numberWithFloat:self.maximumZoomScale] forKey:[maximumZoomScaleKey stringByAppendingDeviceSuffix]];
  [dictionary setValue:[NSNumber numberWithFloat:self.stoneDistanceFromFingertip] forKey:[stoneDistanceFromFingertipKey stringByAppendingDeviceSuffix]];
  [dictionary setValue:[NSNumber numberWithInt:self.infoTypeLastSelected] forKey:infoTypeLastSelectedKey];
  // Note: NSUserDefaults takes care entirely by itself of writing only changed
  // values.
  [userDefaults setObject:dictionary forKey:playViewKey];
}

@end
