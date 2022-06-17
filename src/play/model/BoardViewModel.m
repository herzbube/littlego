// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewModel.h"
#import "../../utility/NSStringAdditions.h"


@implementation BoardViewModel

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewModel object with user defaults data.
///
/// @note This is the designated initializer of BoardViewModel.
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
  self.infoTypeLastSelected = ScoreInfoType;
  self.computerAssistanceType = ComputerAssistanceTypeNone;
  self.selectedSymbolMarkupStyle = SelectedSymbolMarkupStyleDotSymbol;
  self.markupPrecedence = MarkupPrecedenceSymbols;
  self.boardViewPanningGestureIsInProgress = false;
  self.boardViewDisplaysAnimation = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:boardViewKey];
  self.markLastMove = [[dictionary valueForKey:markLastMoveKey] boolValue];
  self.displayCoordinates = [[dictionary valueForKey:displayCoordinatesKey] boolValue];
  self.displayPlayerInfluence = [[dictionary valueForKey:displayPlayerInfluenceKey] boolValue];
  self.moveNumbersPercentage = [[dictionary valueForKey:moveNumbersPercentageKey] floatValue];
  self.playSound = [[dictionary valueForKey:playSoundKey] boolValue];
  self.vibrate = [[dictionary valueForKey:vibrateKey] boolValue];
  self.infoTypeLastSelected = [[dictionary valueForKey:infoTypeLastSelectedKey] intValue];
  self.computerAssistanceType = [[dictionary valueForKey:computerAssistanceTypeKey] intValue];
  self.selectedSymbolMarkupStyle = [[dictionary valueForKey:selectedSymbolMarkupStyleKey] intValue];
  self.markupPrecedence = [[dictionary valueForKey:markupPrecedenceKey] intValue];
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
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:boardViewKey]];
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
  [dictionary setValue:[NSNumber numberWithInt:self.infoTypeLastSelected] forKey:infoTypeLastSelectedKey];
  [dictionary setValue:[NSNumber numberWithInt:self.computerAssistanceType] forKey:computerAssistanceTypeKey];
  [dictionary setValue:[NSNumber numberWithInt:self.selectedSymbolMarkupStyle] forKey:selectedSymbolMarkupStyleKey];
  [dictionary setValue:[NSNumber numberWithInt:self.markupPrecedence] forKey:markupPrecedenceKey];
  // Note: NSUserDefaults takes care entirely by itself of writing only changed
  // values.
  [userDefaults setObject:dictionary forKey:boardViewKey];
}

@end
