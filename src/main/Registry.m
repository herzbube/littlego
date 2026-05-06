// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "Registry.h"


@implementation Registry

#pragma mark - Singleton handling

// -----------------------------------------------------------------------------
/// @brief Shared instance of Registry.
// -----------------------------------------------------------------------------
static Registry* sharedRegistry = nil;


// -----------------------------------------------------------------------------
/// @brief Returns the shared Registry object.
// -----------------------------------------------------------------------------
+ (Registry*) sharedRegistry
{
  if (! sharedRegistry)
    sharedRegistry = [[Registry alloc] init];
  return sharedRegistry;
}

// -----------------------------------------------------------------------------
/// @brief Releases the shared Registry object.
// -----------------------------------------------------------------------------
+ (void) releaseSharedRegistry
{
  if (sharedRegistry)
  {
    [sharedRegistry release];
    sharedRegistry = nil;
  }
}

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a Registry object.
///
/// @note This is the designated initializer of Registry.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.applicationDelegate = nil;
  self.sceneDelegate = nil;
  self.modelProvider = nil;
  self.magnifyingGlassOwner = nil;
  self.windowProvider = nil;
  self.playerClockService = nil;

  return self;
}

@end
