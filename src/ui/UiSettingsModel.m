// -----------------------------------------------------------------------------
// Copyright 2013-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiSettingsModel.h"


@implementation UiSettingsModel

// -----------------------------------------------------------------------------
/// @brief Initializes a UiSettingsModel object with default values.
///
/// @note This is the designated initializer of UiSettingsModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.visibleUIArea = UIAreaDefault;
  _tabOrder = [[NSMutableArray arrayWithCapacity:arraySizeDefaultTabOrder] retain];
  for (int arrayIndex = 0; arrayIndex < arraySizeDefaultTabOrder; ++arrayIndex)
    [(NSMutableArray*)_tabOrder addObject:[NSNumber numberWithInt:defaultTabOrder[arrayIndex]]];
  _uiAreaPlayMode = UIAreaPlayModeDefault;
  self.visibleAnnotationViewPage = AnnotationViewPageValuation;

  CGFloat resizablePane1Size = 1.0f - uiAreaPlayResizablePaneMinimumSize;
  NSNumber* resizablePane1SizeAsNumber = [NSNumber numberWithDouble:resizablePane1Size];
  NSNumber* resizablePane2SizeAsNumber = [NSNumber numberWithDouble:uiAreaPlayResizablePaneMinimumSize];
  self.resizableStackViewControllerInitialSizesUiAreaPlayPortrait = @[resizablePane1SizeAsNumber, resizablePane2SizeAsNumber];
  self.resizableStackViewControllerInitialSizesUiAreaPlayLandscape = self.resizableStackViewControllerInitialSizesUiAreaPlayPortrait;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UiSettingsModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.tabOrder = nil;
  self.resizableStackViewControllerInitialSizesUiAreaPlayPortrait = nil;
  self.resizableStackViewControllerInitialSizesUiAreaPlayLandscape = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:uiSettingsKey];

  self.visibleUIArea = (enum UIArea)[[dictionary valueForKey:visibleUIAreaKey] intValue];
  self.tabOrder = [dictionary valueForKey:tabOrderKey];
  self.uiAreaPlayMode = (enum UIAreaPlayMode)[[dictionary valueForKey:uiAreaPlayModeKey] intValue];
  self.visibleAnnotationViewPage = (enum AnnotationViewPage)[[dictionary valueForKey:visibleAnnotationViewPageKey] intValue];
  self.resizableStackViewControllerInitialSizesUiAreaPlayPortrait = [dictionary valueForKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsPortraitSuffix]];
  self.resizableStackViewControllerInitialSizesUiAreaPlayLandscape = [dictionary valueForKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsLandscapeSuffix]];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.visibleUIArea] forKey:visibleUIAreaKey];
  [dictionary setValue:self.tabOrder forKey:tabOrderKey];
  [dictionary setValue:[NSNumber numberWithInt:self.uiAreaPlayMode] forKey:uiAreaPlayModeKey];
  [dictionary setValue:[NSNumber numberWithInt:self.visibleAnnotationViewPage] forKey:visibleAnnotationViewPageKey];
  [dictionary setValue:self.resizableStackViewControllerInitialSizesUiAreaPlayPortrait forKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsPortraitSuffix]];
  [dictionary setValue:self.resizableStackViewControllerInitialSizesUiAreaPlayLandscape forKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsLandscapeSuffix]];

  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:uiSettingsKey];
}

@end
