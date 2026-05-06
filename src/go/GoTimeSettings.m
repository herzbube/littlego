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
#import "GoTimeSettings.h"
#import "GoTimeDataValidator.h"
#import "GoTimeSystem.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoTimeSettings.
// -----------------------------------------------------------------------------
@interface GoTimeSettings()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) GoTimeSystem* absoluteTimeSystem;
@property(nonatomic, retain, readwrite) GoTimeSystem* periodBasedTimeSystem;
@property(nonatomic, assign, readwrite) bool hasNoTimeSystems;
@property(nonatomic, assign, readwrite) bool isGameUsingTimedPlay;
//@}
@end


@implementation GoTimeSettings

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSettings object with two GoTimeSystem objects
/// which both have the time system type #GoTimeSystemNone.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithAbsoluteTimeSystem:[[[GoTimeSystem alloc] init] autorelease]
                    periodBasedTimeSystem:[[[GoTimeSystem alloc] init] autorelease]];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSettings object with the supplied time systems.
/// Both time systems can have the time system type #GoTimeSystemNone to
/// indicate that the game does not use timed play.
///
/// The time system type of @a absoluteTimeSystem must be either
/// #GoTimeSystemNone or #GoTimeSystemTypeAbsolute.
/// The time system type of @a periodBasedTimeSystem must not be
/// #GoTimeSystemTypeAbsolute.
///
/// @exception NSInvalidArgumentException Is raised in the following cases:
/// - If either @a absoluteTimeSystem or @a periodBasedTimeSystem or both are
///   @e nil.
/// - If the time system type of @a absoluteTimeSystem is neither
///   #GoTimeSystemTypeNone nor #GoTimeSystemTypeAbsolute.
/// - If the time system type of @a periodBasedTimeSystem is
///   #GoTimeSystemTypeAbsolute.
///
/// @note This is the designated initializer of GoTimeSettings.
// -----------------------------------------------------------------------------
- (id) initWithAbsoluteTimeSystem:(GoTimeSystem*)absoluteTimeSystem
            periodBasedTimeSystem:(GoTimeSystem*)periodBasedTimeSystem
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  if (! absoluteTimeSystem || ! periodBasedTimeSystem)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, one or both time systems are nil";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  if (absoluteTimeSystem.goTimeSystemType != GoTimeSystemTypeNone &&
      absoluteTimeSystem.goTimeSystemType != GoTimeSystemTypeAbsolute)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, absoluteTimeSystem has unexpected time system type %ld";
    [ExceptionUtility throwInvalidArgumentExceptionWithFormat:errorMessage
                                                argumentValue:absoluteTimeSystem.goTimeSystemType];
  }

  if (periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, periodBasedTimeSystem has unexpected time system type GoTimeSystemTypeAbsolute";
    [ExceptionUtility throwInvalidArgumentExceptionWithErrorMessage:errorMessage];
  }

  self.absoluteTimeSystem = absoluteTimeSystem;
  self.periodBasedTimeSystem = periodBasedTimeSystem;

  self.isTimeDataValid = GoTimeDataValidationResultInvalid.isTimeDataValid;
  self.timeDataInvalidReason = GoTimeDataValidationResultInvalid.timeDataInvalidReason;
  self.timeDataValidationMode = GoTimeDataValidationResultInvalid.timeDataValidationMode;

  [self updateCalculatedProperties];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  self.absoluteTimeSystem = [decoder decodeObjectOfClass:[GoTimeSystem class] forKey:goTimeSettingsAbsoluteTimeSystemKey];
  self.periodBasedTimeSystem = [decoder decodeObjectOfClass:[GoTimeSystem class] forKey:goTimeSettingsPeriodBasedTimeSystemKey];

  // Time validity properties were not archived. Whoever is unarchiving this
  // GoTimeSettings is responsible for re-calculating the properties.
  self.isTimeDataValid = GoTimeDataValidationResultInvalid.isTimeDataValid;
  self.timeDataInvalidReason = GoTimeDataValidationResultInvalid.timeDataInvalidReason;
  self.timeDataValidationMode = GoTimeDataValidationResultInvalid.timeDataValidationMode;

  [self updateCalculatedProperties];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoTimeSettings object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.absoluteTimeSystem = nil;
  self.periodBasedTimeSystem = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.absoluteTimeSystem forKey:goTimeSettingsAbsoluteTimeSystemKey];
  [encoder encodeObject:self.periodBasedTimeSystem forKey:goTimeSettingsPeriodBasedTimeSystemKey];

  // No need to encode hasNoTimeSystems and isGameUsingTimedPlay, property
  // values are calculated by the initializers

  // Time validity property values are not archived to reduce the size of the
  // archive. The property values can be recalculated upon unarchiving.
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Updates the calculated properties @e hasNoTimeSystems and
/// @e isGameUsingTimedPlay based on the values of the other properties.
// -----------------------------------------------------------------------------
- (void) updateCalculatedProperties
{
  self.hasNoTimeSystems = (self.absoluteTimeSystem.goTimeSystemType == GoTimeSystemTypeNone &&
                           self.periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeNone);
  self.isGameUsingTimedPlay = [self doTimeSystemsSupportTimedPlay];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if @e periodBasedTimeSystem is not a custom time system,
/// and either @e absoluteTimeSystem or @e periodBasedTimeSystem or both have a
/// time system for which the app supports timed play.
// -----------------------------------------------------------------------------
- (bool) doTimeSystemsSupportTimedPlay
{
  if (self.periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeCustom)
    return false;
  else
    return (self.absoluteTimeSystem.supportsTimedPlay || self.periodBasedTimeSystem.supportsTimedPlay);
}

@end
