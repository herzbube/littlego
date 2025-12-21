// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class GoTimeSystem;


// -----------------------------------------------------------------------------
/// @brief The GoTimeSettings class defines which time systems are in effect
/// for a game that uses timed play.
///
/// @ingroup go
// -----------------------------------------------------------------------------
@interface GoTimeSettings : NSObject <NSSecureCoding>
{
}

- (id) init;
- (id) initWithAbsoluteTimeSystem:(GoTimeSystem*)absoluteTimeSystem
            periodBasedTimeSystem:(GoTimeSystem*)periodBasedTimeSystem;

/// @brief The absolute time system that is in effect. The GoTimeSystem object
/// has #GoTimeSystemNone if no absolute time system is in effect.
@property(nonatomic, retain, readonly) GoTimeSystem* absoluteTimeSystem;
/// @brief The period-based time system that is in effect. The GoTimeSystem object
/// has #GoTimeSystemNone if no period-based time system is in effect.
@property(nonatomic, retain, readonly) GoTimeSystem* periodBasedTimeSystem;
/// @brief True if either @e absoluteTimeSystem or @e periodBasedTimeSystem or
/// both have a time system for which the app supports timed play.
@property(nonatomic, assign, readonly) bool isGameUsingTimedPlay;

@end
