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


// Project includes
#import "GoTimeSettings.h"
#import "GoTimeSystem.h"
#import "../utility/ExceptionUtility.h"

// TODO xxx Add unit tests


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoTimeSettings.
// -----------------------------------------------------------------------------
@interface GoTimeSettings()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) GoTimeSystem* absoluteTimeSystem;
@property(nonatomic, retain, readwrite) GoTimeSystem* periodBasedTimeSystem;
//@}
@end


@implementation GoTimeSettings

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSettings object with the supplied time systems.
/// At least one time system must be supplied. If @a absoluteTimeSystem is
/// supplied, it must have time system type #GoTimeSystemTypeAbsolute. If
/// @a periodBasedTimeSystem is supplied, it must @b not have time system type
/// #GoTimeSystemTypeAbsolute.
///
/// Raises an @e NSInternalInconsistencyException in the following cases:
/// - If both @a absoluteTimeSystem and @a periodBasedTimeSystem are @e nil.
/// - If @a absoluteTimeSystem is not @e nil and has a time system type that
///   is not #GoTimeSystemTypeAbsolute.
/// - If @a periodBasedTimeSystem is not @e nil and has the time system type
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

  if (! absoluteTimeSystem && ! periodBasedTimeSystem)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, both time systems are nil";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  if (absoluteTimeSystem && absoluteTimeSystem.goTimeSystemType != GoTimeSystemTypeAbsolute)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, absoluteTimeSystem has unexpected time system type %ld";
    [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:errorMessage
                                                      argumentValue:absoluteTimeSystem.goTimeSystemType];
  }

  if (periodBasedTimeSystem && periodBasedTimeSystem.goTimeSystemType == GoTimeSystemTypeAbsolute)
  {
    NSString* errorMessage = @"Failed to initialize GoTimeSettings object, periodBasedTimeSystem has unexpected time system type GoTimeSystemTypeAbsolute";
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  self.absoluteTimeSystem = absoluteTimeSystem;
  self.periodBasedTimeSystem = periodBasedTimeSystem;

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

  self.absoluteTimeSystem = [decoder decodeObjectOfClass:[NSDate class] forKey:goTimeSettingsAbsoluteTimeSystem];
  self.periodBasedTimeSystem = [decoder decodeObjectOfClass:[NSDate class] forKey:goTimeSettingsPeriodBasedTimeSystem];

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
  [encoder encodeObject:self.absoluteTimeSystem forKey:goTimeSettingsAbsoluteTimeSystem];
  [encoder encodeObject:self.periodBasedTimeSystem forKey:goTimeSettingsPeriodBasedTimeSystem];
}

@end
