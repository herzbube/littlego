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
///   #GoTimeSystemTypeNone
/// - If @a periodDurationInSeconds is 0 (zero) or less and @a goTimeSystemType
///   is not #GoTimeSystemTypeNone
/// - If @a minimumNumberOfMovesPerPeriod is 0 (zero) although
///   @a hasMinimumNumberOfMovesPerPeriod is true.
/// - If @a minimumNumberOfMovesPerPeriod is not 0 (zero) although
///   @a hasMinimumNumberOfMovesPerPeriod is false.
/// - If @a extraTimeDurationInSeconds is 0 (zero) or less although
///   @a goUnusedTimeHandling is #GoUnusedTimeHandlingAddExtraTime.
///
/// @note This is the designated initializer of GoTimeSystem.
// -----------------------------------------------------------------------------
 - (id) initWithGoTimeSystemType:(enum GoTimeSystemType)goTimeSystemType
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

  if (goTimeSystemType != GoTimeSystemTypeNone)
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

  self.goTimeSystemType = goTimeSystemType;
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

  self.goTimeSystemType = [decoder decodeIntForKey:goTimeSystemGoTimeSystemType];
  self.numberOfPeriods = [decoder decodeIntForKey:goTimeSystemNumberOfPeriods];
  self.periodDurationInSeconds = [decoder decodeDoubleForKey:goTimeSystemPeriodDurationInSeconds];
  self.hasMinimumNumberOfMovesPerPeriod = [decoder decodeBoolForKey:goTimeSystemHasMinimumNumberOfMovesPerPeriod];
  self.minimumNumberOfMovesPerPeriod = [decoder decodeIntForKey:goTimeSystemMinimumNumberOfMovesPerPeriod];
  self.goUnusedTimeHandling = [decoder decodeIntForKey:goTimeSystemGoUnusedTimeHandling];
  self.extraTimeDurationInSeconds = [decoder decodeDoubleForKey:goTimeSystemExtraTimeDurationInSeconds];

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
  [encoder encodeInt:self.goTimeSystemType forKey:goTimeSystemGoTimeSystemType];
  [encoder encodeInt:self.numberOfPeriods forKey:goTimeSystemNumberOfPeriods];
  [encoder encodeDouble:self.periodDurationInSeconds forKey:goTimeSystemPeriodDurationInSeconds];
  [encoder encodeBool:self.hasMinimumNumberOfMovesPerPeriod forKey:goTimeSystemHasMinimumNumberOfMovesPerPeriod];
  [encoder encodeInt:self.minimumNumberOfMovesPerPeriod forKey:goTimeSystemMinimumNumberOfMovesPerPeriod];
  [encoder encodeInt:self.goUnusedTimeHandling forKey:goTimeSystemGoUnusedTimeHandling];
  [encoder encodeDouble:self.extraTimeDurationInSeconds forKey:goTimeSystemExtraTimeDurationInSeconds];
}

@end
