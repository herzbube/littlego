// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
  XCTAssertNotNil(m_delegate, @"Unable to create ApplicationDelegate object in setUp()");

  XCTAssertEqual(m_delegate.applicationLaunchMode, ApplicationLaunchModeNormal, @"Application launch mode is not ApplicationLaunchModeNormal");

  // The log file for unit tests run in the simulator environment is located in
  // ~/Library/Application Support/iPhone Simulator/Library/Caches/Logs
  [m_delegate setupLogging];
  DDLogInfo(@"Setting up test environment for test %@", self);

  @try
  {
    m_delegate.resourceBundle = [NSBundle bundleForClass:[self class]];
    XCTAssertNotNil(m_delegate.resourceBundle, @"Unable to determine unit test bundle in setUp()");

    [m_delegate setupRegistrationDomain];
    // Tests are expecting a human vs. human game and a 19x19 board
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary* newGameDictionary = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:newGameKey]];
    [newGameDictionary setValue:[NSNumber numberWithInt:GoGameTypeHumanVsHuman] forKey:gameTypeKey];
    [newGameDictionary setValue:[NSNumber numberWithInt:GoBoardSize19] forKey:boardSizeKey];
    [userDefaults setObject:newGameDictionary forKey:newGameKey];
    // Initialize models after we have fiddled with the user defaults data.
    [m_delegate setupUserDefaults];
    // If user defaults were written to disk during unit tests, they would go
    // into the file
    ///   ~/Library/Application Support/iPhone Simulator/Library/Preferences/otest.plist
    XCTAssertFalse(m_delegate.writeUserDefaultsEnabled, @"User defaults must not be written in unit testing environment");

    [[[[NewGameCommand alloc] init] autorelease] submit];
    m_game = m_delegate.game;
    XCTAssertNotNil(m_game, @"Unable to create GoGame object in setUp()");
  }
  @catch (NSException* exception)
  {
    DDLogError(@"Exception caught in BaseTestCase::setup(). Exception reason = %@, exception stack trace = %@", exception, [NSThread callStackSymbols]);
    @throw;
  }

  [pool drain];  // draining the pool also deallocates it
}

// -----------------------------------------------------------------------------
/// @brief Tears down the environment previously set up for a test case method.
// -----------------------------------------------------------------------------
- (void) tearDown
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DDLogInfo(@"Tearing down test environment for test %@", self);
  [m_delegate release];
  [pool drain];  // draining the pool also deallocates it
  XCTAssertNil([ApplicationDelegate sharedDelegate], @"ApplicationDelegate object not released in tearDown()");
  XCTAssertNil([GoGame sharedGame], @"GoGame object not released in tearDown()");
}

@end
