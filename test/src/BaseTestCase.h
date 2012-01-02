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


// System includes
#import <SenTestingKit/SenTestingKit.h>

// Forward declarations
@class ApplicationDelegate;
@class GoGame;


// -----------------------------------------------------------------------------
/// @brief The BaseTestCase class implements setUp() and tearDown() to provide
/// subclasses with a useful default test environment.
///
/// The default test environment looks like this:
/// - An application delegate object is created. The object is available through
///   the instance variable m_delegate.
/// - The logging subsystem is initialized
/// - The user defaults system is initialized with the main application's
///   registration domain data
/// - In addition, user defaults are set up with a "new game" board size of
///   19x19 and two human players (regardless of what the registration domain
///   data contains)
/// - All of the main application's model objects are created and initialized
///   with user defaults data
/// - A new GoGame object is created by submitting a NewGameCommand instance.
///   The object is available through the instance variable m_game.
///
/// Also note that setUp() guarantees that there are no pending autorelease
/// messages when test execution commences. The reason: setUp() wraps an
/// NSAutoReleasePool around its initialization, then drains the pool after
/// initialization is complete.
// -----------------------------------------------------------------------------
@interface BaseTestCase : SenTestCase
{
@protected
  ApplicationDelegate* m_delegate;
  GoGame* m_game;
}

- (void) setUp;
- (void) tearDown;

@end
