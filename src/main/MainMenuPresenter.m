// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "MainMenuPresenter.h"


@implementation MainMenuPresenter

#pragma mark - Shared object handling

// -----------------------------------------------------------------------------
/// @brief Shared instance of MainMenuPresenter.
// -----------------------------------------------------------------------------
static MainMenuPresenter* sharedPresenter = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared MainMenuPresenter object.
// -----------------------------------------------------------------------------
+ (MainMenuPresenter*) sharedPresenter
{
  @synchronized(self)
  {
    if (! sharedPresenter)
      sharedPresenter = [[MainMenuPresenter alloc] init];
    return sharedPresenter;
  }
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared MainMenuPresenter object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedPresenter
{
  @synchronized(self)
  {
    if (sharedPresenter)
    {
      [sharedPresenter release];
      sharedPresenter = nil;
    }
  }
}

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an MainMenuPresenter object.
///
/// @note This is the designated initializer of MainMenuPresenter.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.mainMenuPresenterDelegate = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MainMenuPresenter object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.mainMenuPresenterDelegate = nil;
  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Presents the main menu.
///
/// The implementation forwards the call to the delegate.
// -----------------------------------------------------------------------------
- (void) presentMainMenu:(id)sender
{
  [self.mainMenuPresenterDelegate presentMainMenu];
}

@end
