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
#import "UiElementFinder.h"


// -----------------------------------------------------------------------------
/// @brief The UiAreaPortraitTest class tests the #UIAreaPlay when the user
/// interface is in portrait mode.
// -----------------------------------------------------------------------------
@interface UiAreaPortraitTest : XCTestCase
@property(nonatomic, strong) UiElementFinder* uiElementFinder;
@end


@implementation UiAreaPortraitTest

#pragma mark - setUp and tearDown

// -----------------------------------------------------------------------------
/// @brief Sets the environment up for a test.
// -----------------------------------------------------------------------------
- (void) setUp
{
  self.continueAfterFailure = NO;

  [[[XCUIApplication alloc] init] launch];

  self.uiElementFinder = [[UiElementFinder alloc] init];
}

// -----------------------------------------------------------------------------
/// @brief Tears the environment down after a test.
// -----------------------------------------------------------------------------
- (void) tearDown
{
  self.uiElementFinder = nil;
}

#pragma mark - Tests

@end
