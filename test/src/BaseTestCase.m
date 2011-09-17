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


// Test includes
#import "BaseTestCase.h"

// Application includes
#import <ApplicationDelegate.h>
#import <go/GoGame.h>
#import <command/game/NewGameCommand.h>


@implementation BaseTestCase

// -----------------------------------------------------------------------------
/// @brief Sets up the environment for a test case method.
// -----------------------------------------------------------------------------
- (void) setUp
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

  m_delegate = [[ApplicationDelegate newDelegate] retain];
  STAssertNotNil(m_delegate, @"Unable to create ApplicationDelegate object in setUp()");

  m_delegate.resourceBundle = [NSBundle bundleForClass:[self class]];
  STAssertNotNil(m_delegate.resourceBundle, @"Unable to determine unit test bundle in setUp()");
  [m_delegate setupUserDefaults];

  [[[NewGameCommand alloc] init] submit];
  m_game = m_delegate.game;
  STAssertNotNil(m_game, @"Unable to create GoGame object in setUp()");

  [pool drain];
}

// -----------------------------------------------------------------------------
/// @brief Tears down the environment previously set up for a test case method.
// -----------------------------------------------------------------------------
- (void) tearDown
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  [m_delegate release];
  [pool drain];
  STAssertNil([ApplicationDelegate sharedDelegate], @"ApplicationDelegate object not released in tearDown()");
  STAssertNil([GoGame sharedGame], @"GoGame object not released in tearDown()");
}

@end
