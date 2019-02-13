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


// Project includes
#import "UiTestDeviceInfo.h"
#import "../src/shared/LayoutManager.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for UiTestDeviceInfo.
// -----------------------------------------------------------------------------
@interface UiTestDeviceInfo()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum UIType uiType;
@property(nonatomic, assign, readwrite) UIInterfaceOrientationMask supportedInterfaceOrientations;
//@}
@end


@implementation UiTestDeviceInfo

// -----------------------------------------------------------------------------
/// @brief Initializes a UiTestDeviceInfo object.
///
/// @note This is the designated initializer of UiTestDeviceInfo.
// -----------------------------------------------------------------------------
- (id) initWithUiApplication:(XCUIApplication*)app
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  // The order in which methods are called is important
  [self setupUITypeWithUiApplication:app];
  [self setupSupportedInterfaceOrientations];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupUITypeWithUiApplication:(XCUIApplication*)app
{
  UIUserInterfaceIdiom userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom;

  CGSize windowSize = app.windows.allElementsBoundByIndex[0].frame.size;

  self.uiType = [LayoutManager uiTypeForUserInterfaceIdiom:userInterfaceIdiom
                                                screenSize:windowSize];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupSupportedInterfaceOrientations
{
  self.supportedInterfaceOrientations = [LayoutManager supportedInterfaceOrientationsForUiType:self.uiType];
}

@end
