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
#import "GoTimeSystem.h"
#import "../utility/ExceptionUtility.h"

// TODO xxx Add unit tests


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoTimeSystem.
// -----------------------------------------------------------------------------
@interface GoTimeSystem()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum GoTimeSystemType goTimeSystemType;
@property(nonatomic, assign, readwrite) NSString* customTimeSystemDescription;
@property(nonatomic, assign, readwrite) unsigned int numberOfPeriods;
@property(nonatomic, assign, readwrite) double periodDurationInSeconds;
@property(nonatomic, assign, readwrite) bool hasMinimumNumberOfMovesPerPeriod;
@property(nonatomic, assign, readwrite) unsigned int minimumNumberOfMovesPerPeriod;
@property(nonatomic, assign, readwrite) enum GoUnusedTimeHandling goUnusedTimeHandling;
@property(nonatomic, assign, readwrite) double extraTimeDurationInSeconds;
//@}
@end


@implementation GoTimeSystem

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with #GoTimeSystemTypeNone and
/// default values for the remaining time system parameters.
// -----------------------------------------------------------------------------
- (id) init
{
  return [self initWithGoTimeSystemType:GoTimeSystemTypeNone
            customTimeSystemDescription:nil
                        numberOfPeriods:0
                periodDurationInSeconds:0.0
       hasMinimumNumberOfMovesPerPeriod:false
          minimumNumberOfMovesPerPeriod:0
                   goUnusedTimeHandling:GoUnusedTimeHandlingNone
             extraTimeDurationInSeconds:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with #GoTimeSystemTypeCustom,
/// the time system's string description @a customTimeSystemDescription and
/// default values for the remaining time system parameters.
// -----------------------------------------------------------------------------
- (id) initWithCustomTimeSystemDescription:(NSString*)customTimeSystemDescription
{
  return [self initWithGoTimeSystemType:GoTimeSystemTypeCustom
            customTimeSystemDescription:customTimeSystemDescription
                        numberOfPeriods:0
                periodDurationInSeconds:0.0
       hasMinimumNumberOfMovesPerPeriod:false
          minimumNumberOfMovesPerPeriod:0
                   goUnusedTimeHandling:GoUnusedTimeHandlingNone
             extraTimeDurationInSeconds:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with #GoTimeSystemTypeAbsolute and
/// @a absoluteTimeDurationInSeconds.
// -----------------------------------------------------------------------------
- (id) initWithAbsoluteTimeDurationInSeconds:(double)absoluteTimeDurationInSeconds
{
  return [self initWithGoTimeSystemType:GoTimeSystemTypeAbsolute
            customTimeSystemDescription:nil
                        numberOfPeriods:1
                periodDurationInSeconds:absoluteTimeDurationInSeconds
       hasMinimumNumberOfMovesPerPeriod:false
          minimumNumberOfMovesPerPeriod:0
                   goUnusedTimeHandling:GoUnusedTimeHandlingNone
             extraTimeDurationInSeconds:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with the time system
/// @a goTimeSystemType, which has a single time period with duration
/// @a periodDurationInSeconds and @a minimumNumberOfMovesPerPeriod. The time
/// system handles unused time with @a goUnusedTimeHandling.
///
/// Raises an @e NSInternalInconsistencyException if @a goTimeSystemType is not
/// one of #GoTimeSystemTypeCanadian, #GoTimeSystemTypeSteadyAverage or
/// #GoTimeSystemTypeTotalAverage.
// -----------------------------------------------------------------------------
- (id) initWithGoTimeSystemType:(enum GoTimeSystemType)goTimeSystemType
        periodDurationInSeconds:(double)periodDurationInSeconds
  minimumNumberOfMovesPerPeriod:(unsigned int)minimumNumberOfMovesPerPeriod
           goUnusedTimeHandling:(enum GoUnusedTimeHandling)goUnusedTimeHandling
{
  if (goTimeSystemType != GoTimeSystemTypeCanadian &&
      goTimeSystemType != GoTimeSystemTypeSteadyAverage &&
      goTimeSystemType != GoTimeSystemTypeTotalAverage)
  {
    [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"Failed to initialize GoTimeSystem object, invalid time system %ld"
                                                      argumentValue:goTimeSystemType];
  }

  return [self initWithGoTimeSystemType:goTimeSystemType
            customTimeSystemDescription:nil
                        numberOfPeriods:1
                periodDurationInSeconds:periodDurationInSeconds
       hasMinimumNumberOfMovesPerPeriod:true
          minimumNumberOfMovesPerPeriod:minimumNumberOfMovesPerPeriod
                   goUnusedTimeHandling:goUnusedTimeHandling
             extraTimeDurationInSeconds:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with #GoTimeSystemTypeJapanese,
/// which has the number of periods @a numberOfPeriods with duration
/// @a periodDurationInSeconds.
// -----------------------------------------------------------------------------
- (id) initWithJapaneseTimeNumberOfPeriods:(unsigned int)numberOfPeriods
                   periodDurationInSeconds:(double)periodDurationInSeconds
{
  return [self initWithGoTimeSystemType:GoTimeSystemTypeJapanese
            customTimeSystemDescription:nil
                        numberOfPeriods:numberOfPeriods
                periodDurationInSeconds:periodDurationInSeconds
       hasMinimumNumberOfMovesPerPeriod:true
          minimumNumberOfMovesPerPeriod:1
                   goUnusedTimeHandling:GoUnusedTimeHandlingNone
             extraTimeDurationInSeconds:0.0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with #GoTimeSystemTypeFischer,
/// which has an initial period duration @a initialDurationInSeconds and extra
/// time duration @a extraTimeDurationInSeconds.
// -----------------------------------------------------------------------------
- (id) initWithFischerTimeInitialDurationInSeconds:(double)initialDurationInSeconds
                        extraTimeDurationInSeconds:(double)extraTimeDurationInSeconds
{
  return [self initWithGoTimeSystemType:GoTimeSystemTypeFischer
            customTimeSystemDescription:nil
                        numberOfPeriods:1
                periodDurationInSeconds:initialDurationInSeconds
       hasMinimumNumberOfMovesPerPeriod:true
          minimumNumberOfMovesPerPeriod:1
                   goUnusedTimeHandling:GoUnusedTimeHandlingAddExtraTime
             extraTimeDurationInSeconds:extraTimeDurationInSeconds];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GoTimeSystem object with the provided time system
/// parameters.
///
/// Raises an @e NSInternalInconsistencyException in the following cases:
/// - If @a numberOfPeriods is 0 (zero) and @a goTimeSystemType is not
///   #GoTimeSystemTypeNone or #GoTimeSystemTypeCustom
/// - If @a periodDurationInSeconds is 0 (zero) or less and @a goTimeSystemType
///   is not #GoTimeSystemTypeNone or #GoTimeSystemTypeCustom
/// - If @a minimumNumberOfMovesPerPeriod is 0 (zero) although
///   @a hasMinimumNumberOfMovesPerPeriod is true.
/// - If @a minimumNumberOfMovesPerPeriod is not 0 (zero) although
///   @a hasMinimumNumberOfMovesPerPeriod is false.
/// - If @a extraTimeDurationInSeconds is 0 (zero) or less although
///   @a goUnusedTimeHandling is #GoUnusedTimeHandlingAddExtraTime.
/// - If @a goTimeSystemType is #GoTimeSystemTypeCustom but
///   @a customTimeSystemDescription is @e nil.
/// - If @a goTimeSystemType is not #GoTimeSystemTypeCustom but
///   @a customTimeSystemDescription is not @e nil.
///
/// @note This is the designated initializer of GoTimeSystem.
// -----------------------------------------------------------------------------
 - (id) initWithGoTimeSystemType:(enum GoTimeSystemType)goTimeSystemType
     customTimeSystemDescription:(NSString*)customTimeSystemDescription
                 numberOfPeriods:(unsigned int)numberOfPeriods
         periodDurationInSeconds:(double)periodDurationInSeconds
hasMinimumNumberOfMovesPerPeriod:(bool)hasMinimumNumberOfMovesPerPeriod
   minimumNumberOfMovesPerPeriod:(unsigned int)minimumNumberOfMovesPerPeriod
            goUnusedTimeHandling:(enum GoUnusedTimeHandling)goUnusedTimeHandling
      extraTimeDurationInSeconds:(double)extraTimeDurationInSeconds
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  if (goTimeSystemType != GoTimeSystemTypeNone && goTimeSystemType != GoTimeSystemTypeCustom)
  {
    if (numberOfPeriods == 0)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, invalid number of periods %d for time system %u", numberOfPeriods, goTimeSystemType];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }

    if (periodDurationInSeconds <= 0)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, invalid period duration %f for time system %u", periodDurationInSeconds, goTimeSystemType];
      [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
    }
  }

  if ((hasMinimumNumberOfMovesPerPeriod && minimumNumberOfMovesPerPeriod == 0) ||
      (! hasMinimumNumberOfMovesPerPeriod && minimumNumberOfMovesPerPeriod != 0))
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, invalid minimum number of moves per period %d for time system %u", minimumNumberOfMovesPerPeriod, goTimeSystemType];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  if (goUnusedTimeHandling == GoUnusedTimeHandlingAddExtraTime && extraTimeDurationInSeconds <= 0)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, invalid extra time duration %f for time system %u", extraTimeDurationInSeconds, goTimeSystemType];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  if (goTimeSystemType == GoTimeSystemTypeCustom && ! customTimeSystemDescription)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, custom time system description is missing"];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }
  else if (goTimeSystemType != GoTimeSystemTypeCustom && customTimeSystemDescription != nil)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"Failed to initialize GoTimeSystem object, custom time system description is present although time system %u is not GoTimeSystemTypeCustom", goTimeSystemType];
    [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
  }

  self.goTimeSystemType = goTimeSystemType;
  self.customTimeSystemDescription = customTimeSystemDescription;
  self.numberOfPeriods = numberOfPeriods;
  self.periodDurationInSeconds = periodDurationInSeconds;
  self.hasMinimumNumberOfMovesPerPeriod = hasMinimumNumberOfMovesPerPeriod;
  self.minimumNumberOfMovesPerPeriod = minimumNumberOfMovesPerPeriod;
  self.goUnusedTimeHandling = goUnusedTimeHandling;
  self.extraTimeDurationInSeconds = extraTimeDurationInSeconds;

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

  self.goTimeSystemType = [decoder decodeIntForKey:goTimeSystemGoTimeSystemTypeKey];
  self.customTimeSystemDescription = [decoder decodeObjectOfClass:[NSString class] forKey:goTimeSystemCustomTimeSystemDescriptionKey];
  self.numberOfPeriods = [decoder decodeIntForKey:goTimeSystemNumberOfPeriodsKey];
  self.periodDurationInSeconds = [decoder decodeDoubleForKey:goTimeSystemPeriodDurationInSecondsKey];
  self.hasMinimumNumberOfMovesPerPeriod = [decoder decodeBoolForKey:goTimeSystemHasMinimumNumberOfMovesPerPeriodKey];
  self.minimumNumberOfMovesPerPeriod = [decoder decodeIntForKey:goTimeSystemMinimumNumberOfMovesPerPeriodKey];
  self.goUnusedTimeHandling = [decoder decodeIntForKey:goTimeSystemGoUnusedTimeHandlingKey];
  self.extraTimeDurationInSeconds = [decoder decodeDoubleForKey:goTimeSystemExtraTimeDurationInSecondsKey];

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
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
  [encoder encodeObject:self.customTimeSystemDescription forKey:goTimeSystemCustomTimeSystemDescriptionKey];
  [encoder encodeInt:self.goTimeSystemType forKey:goTimeSystemGoTimeSystemTypeKey];
  [encoder encodeInt:self.numberOfPeriods forKey:goTimeSystemNumberOfPeriodsKey];
  [encoder encodeDouble:self.periodDurationInSeconds forKey:goTimeSystemPeriodDurationInSecondsKey];
  [encoder encodeBool:self.hasMinimumNumberOfMovesPerPeriod forKey:goTimeSystemHasMinimumNumberOfMovesPerPeriodKey];
  [encoder encodeInt:self.minimumNumberOfMovesPerPeriod forKey:goTimeSystemMinimumNumberOfMovesPerPeriodKey];
  [encoder encodeInt:self.goUnusedTimeHandling forKey:goTimeSystemGoUnusedTimeHandlingKey];
  [encoder encodeDouble:self.extraTimeDurationInSeconds forKey:goTimeSystemExtraTimeDurationInSecondsKey];
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoTimeSystem object.
///
/// This method is invoked when GoTimeSystem needs to be represented as a
/// string, i.e. by NSLog, or when the debugger command "po" is used on the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  switch (_goTimeSystemType)
  {
    case GoTimeSystemTypeAbsolute:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Absolute Timing, duration = %f", self, _periodDurationInSeconds];
    case GoTimeSystemTypeCanadian:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Canadian Timing, duration = %f, moves = %d", self, _periodDurationInSeconds, _minimumNumberOfMovesPerPeriod];
    case GoTimeSystemTypeJapanese:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Japanese Timing, duration = %f, periods = %d", self, _periodDurationInSeconds, _numberOfPeriods];
    case GoTimeSystemTypeFischer:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Fischer Timing, initial duration = %f, extra time = %f", self, _periodDurationInSeconds, _extraTimeDurationInSeconds];
    case GoTimeSystemTypeSteadyAverage:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Steady Average Timing, duration = %f, moves = %d", self, _periodDurationInSeconds, _minimumNumberOfMovesPerPeriod];
    case GoTimeSystemTypeTotalAverage:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Total Average Timing, duration = %f, moves = %d", self, _periodDurationInSeconds, _minimumNumberOfMovesPerPeriod];
    case GoTimeSystemTypeCustom:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Custom time system, description = %@", self, self.customTimeSystemDescription];
    case GoTimeSystemTypeNone:
      return [NSString stringWithFormat:@"GoTimeSystem(%p): No time system", self];
    default:
      assert(0);
      return [NSString stringWithFormat:@"GoTimeSystem(%p): Unhandled time system type %d", self, _goTimeSystemType];
  }
}

@end
