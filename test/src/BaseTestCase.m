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
#import <main/ApplicationDelegate.h>
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

  // Xcode 4: The log file for unit tests run in the simulator environment is
  // located in ~/Library/Application Support/iPhone Simulator/Documents/Logs
  [m_delegate setupLogging];

  m_delegate.resourceBundle = [NSBundle bundleForClass:[self class]];
  STAssertNotNil(m_delegate.resourceBundle, @"Unable to determine unit test bundle in setUp()");

  [m_delegate setupRegistrationDomain];
  // Tests are expecting a 19x19 board, so make sure that this board size is
  // used regardless of what the values in the registration domain say
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSMutableDictionary* newGameDictionary = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:newGameKey]];
  [newGameDictionary setValue:[NSNumber numberWithInt:GoBoardSize19] forKey:boardSizeKey];
  // Tests are expecting a human vs. human game. Assuming that the registration
  // domain sets up the black player to be human, we make sure that the white
  // player is also human.
  [newGameDictionary setValue:[newGameDictionary valueForKey:blackPlayerKey] forKey:whitePlayerKey];
  [userDefaults setObject:newGameDictionary forKey:newGameKey];
  // Initialize models after we have fiddled with the user defaults data
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
