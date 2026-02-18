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

/// @name Time systems
//@{
/// @brief The absolute time system that is in effect. The GoTimeSystem object
/// has #GoTimeSystemNone if no absolute time system is in effect.
@property(nonatomic, retain, readonly) GoTimeSystem* absoluteTimeSystem;
/// @brief The period-based time system that is in effect. The GoTimeSystem object
/// has #GoTimeSystemNone if no period-based time system is in effect.
@property(nonatomic, retain, readonly) GoTimeSystem* periodBasedTimeSystem;
//@}

/// @name Calculated properties
//@{
/// @brief @e true if both @e absoluteTimeSystem and @e periodBasedTimeSystem
/// have #GoTimeSystemTypeNone. @e false if either @e absoluteTimeSystem or
/// @e periodBasedTimeSystem, or both, have a time system type that is not
/// #GoTimeSystemTypeNone.
@property(nonatomic, assign, readonly) bool hasNoTimeSystems;
/// @brief @e true if @e periodBasedTimeSystem is not a custom time system,
/// and either @e absoluteTimeSystem or @e periodBasedTimeSystem or both have a
/// time system for which the app supports timed play. Note that
/// @e isTimeDataValid could still be @e false if the time validation routine
/// found a problem with some other data of one of the time systems.
@property(nonatomic, assign, readonly) bool isGameUsingTimedPlay;
//@}

/// @name Time data validity
//@{
/// @brief @e true if time data validation did run and did not find any problem
/// with the time data in this GoTimeSettings object. @e false if time data
/// validation did not run, or did run but found a problem with the time data in
/// this GoTimeSettings object. In the latter case, the value of property
/// @e timeDataInvalidReason indicates the reason why the time data is not
/// valid.
///
/// The default value after initialization is false.
@property(nonatomic, assign) bool isTimeDataValid;
/// @brief If property @e isTimeDataValid is @e false, indicates the reason
/// why the time data is not valid. If property @e isTimeDataValid is @e true,
/// this property has value -1.
///
/// The default value after initialization is -1.
@property(nonatomic, assign) enum GoTimeDataInvalidReason timeDataInvalidReason;
/// @brief The mode that was used when this GoTimeSettings object's time data
/// was validated the last time.
///
/// The default value after initialization is -1.
@property(nonatomic, assign) enum GoTimeDataValidationMode timeDataValidationMode;
//@}

@end
