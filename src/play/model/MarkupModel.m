// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "MarkupModel.h"
#import "../../utility/MarkupUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MarkupModel.
// -----------------------------------------------------------------------------
@interface MarkupModel()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum MarkupTool markupTool;
//@}
@end


@implementation MarkupModel

// -----------------------------------------------------------------------------
/// @brief Initializes a MarkupModel object with user defaults data.
///
/// @note This is the designated initializer of MarkupModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.markupType = MarkupTypeSymbolCircle;
  // Explicitly initialize markupTool property because the markupType property
  // setter may have returned early
  [self updateMarkupTool];

  self.selectedSymbolMarkupStyle = SelectedSymbolMarkupStyleDotSymbol;
  self.markupPrecedence = MarkupPrecedenceSymbols;
  self.uniqueSymbols = false;
  self.connectionToolAllowsDelete = true;
  self.fillMarkerGaps = true;

  return self;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setMarkupType:(enum MarkupType)markupType
{
  if (_markupType == markupType)
    return;

  // Order in which the two properties are set is documented in the public API
  _markupType = markupType;
  [self updateMarkupTool];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for updating the value of the @e markupTool property
/// based on the current value of the @e markupType property.
// -----------------------------------------------------------------------------
- (void) updateMarkupTool
{
  self.markupTool = [MarkupUtilities markupToolForMarkupType:self.markupType];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:markupKey];
  self.markupType = [[dictionary valueForKey:markupTypeKey] intValue];
  self.selectedSymbolMarkupStyle = [[dictionary valueForKey:selectedSymbolMarkupStyleKey] intValue];
  self.markupPrecedence = [[dictionary valueForKey:markupPrecedenceKey] intValue];
  self.uniqueSymbols = [[dictionary valueForKey:uniqueSymbolsKey] boolValue];
  self.connectionToolAllowsDelete = [[dictionary valueForKey:connectionToolAllowsDeleteKey] boolValue];
  self.fillMarkerGaps = [[dictionary valueForKey:fillMarkerGapsKey] boolValue];

  // Explicitly initialize markupTool property because the markupType property
  // setter may have returned early
  [self updateMarkupTool];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.markupType] forKey:markupTypeKey];
  [dictionary setValue:[NSNumber numberWithInt:self.selectedSymbolMarkupStyle] forKey:selectedSymbolMarkupStyleKey];
  [dictionary setValue:[NSNumber numberWithInt:self.markupPrecedence] forKey:markupPrecedenceKey];
  [dictionary setValue:[NSNumber numberWithBool:self.uniqueSymbols] forKey:uniqueSymbolsKey];
  [dictionary setValue:[NSNumber numberWithBool:self.connectionToolAllowsDelete] forKey:connectionToolAllowsDeleteKey];
  [dictionary setValue:[NSNumber numberWithBool:self.fillMarkerGaps] forKey:fillMarkerGapsKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:markupKey];
}

@end
