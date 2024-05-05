// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BaseTestCase.
// -----------------------------------------------------------------------------
@interface BaseTestCase()
@property(nonatomic, assign, readwrite) bool testSetupHasBeenDone;
@property(nonatomic, retain) NSMutableDictionary* notificationsReceivedDictionary;
@end


@implementation BaseTestCase

#pragma mark - Setup and teardown

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

  self.notificationsReceivedDictionary = nil;
  self.testSetupHasBeenDone = true;

  [pool drain];  // draining the pool also deallocates it
}

// -----------------------------------------------------------------------------
/// @brief Tears down the environment previously set up for a test case method.
// -----------------------------------------------------------------------------
- (void) tearDown
{
  // The test case may have invoked tearDown on its own => when the test exits
  // and XCTestCase invokes tearDown for the final time we don't have to do
  // anything anymore
  if (! self.testSetupHasBeenDone)
    return;

  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  DDLogInfo(@"Tearing down test environment for test %@", self);

  [m_delegate release];
  m_delegate = nil;
  m_game = nil;

  [self unregisterForAllNotifications];
  XCTAssertNil(self.notificationsReceivedDictionary, @"self.notificationsReceivedDictionary not released in tearDown()");

  self.testSetupHasBeenDone = false;
  
  [pool drain];  // draining the pool also deallocates it
  XCTAssertNil([ApplicationDelegate sharedDelegate], @"ApplicationDelegate object not released in tearDown()");
  XCTAssertNil([GoGame sharedGame], @"GoGame object not released in tearDown()");
}

#pragma mark - Notification handling

// -----------------------------------------------------------------------------
/// @brief Registers this test case object with the default global notification
/// center to receive notifications with name @a notificationName. From now on
/// notifications posted with name @a notificationName will increase a counter
/// that can be queried by invoking numberOfNotificationsReceived:().
// -----------------------------------------------------------------------------
- (void) registerForNotification:(NSString*)notificationName
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(notificationResponder:) name:notificationName object:nil];

  if (! self.notificationsReceivedDictionary)
    self.notificationsReceivedDictionary = [NSMutableDictionary dictionary];
  self.notificationsReceivedDictionary[notificationName] = @0;
}

// -----------------------------------------------------------------------------
/// @brief Unregisters this test case object from the default global
/// notification center to no longer receive notifications with name
/// @a notificationName. Also sets the notification counter for
/// @a notificationName to 0 (zero).
// -----------------------------------------------------------------------------
- (void) unregisterForNotification:(NSString*)notificationName
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self name:notificationName object:nil];

  [self.notificationsReceivedDictionary removeObjectForKey:notificationName];
  if (self.notificationsReceivedDictionary.count == 0)
    self.notificationsReceivedDictionary = nil;
}

// -----------------------------------------------------------------------------
/// @brief Unregisters this test case object from the default global
/// notification center to no longer receive any notifications. Also sets all
/// existing notification counters to 0 (zero).
// -----------------------------------------------------------------------------
- (void) unregisterForAllNotifications
{
  if (! self.notificationsReceivedDictionary)
    return;

  NSArray* notificationNames = self.notificationsReceivedDictionary.allKeys;
  for (NSString* notificationName in notificationNames)
    [self unregisterForNotification:notificationName];
}

// -----------------------------------------------------------------------------
/// @brief Returns the number of notifications with name @a notificationName
/// that have been received. The counter initially is 0 (zero). The counter
/// is increased only after registerForNotification:() has been invoked for
/// @a notificationName.
// -----------------------------------------------------------------------------
- (int) numberOfNotificationsReceived:(NSString*)notificationName
{
  if (! self.notificationsReceivedDictionary)
    return 0;

  NSNumber* number = self.notificationsReceivedDictionary[notificationName];
  return number ? number.intValue : 0;
}

// -----------------------------------------------------------------------------
/// @brief Responds to @a notification being posted to the default global
/// notification center.
///
/// This is a private helper method.
// -----------------------------------------------------------------------------
- (void) notificationResponder:(NSNotification*)notification
{
  self.notificationsReceivedDictionary[notification.name] = @([self numberOfNotificationsReceived:notification.name] + 1);
}

@end
