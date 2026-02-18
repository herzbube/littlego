// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
@class GoTimeSettings;


// -----------------------------------------------------------------------------
/// @brief The TimeSettingsModel class is a container for properties that
/// describe the time settings of a game.
///
/// TimeSettingsModel can read the values of its properties from a dictionary,
/// or write them to a dictionary, in order to support reading from/writing to
/// user defaults.
///
/// TimeSettingsModel also can convert its data into a GoTimeSettings object,
/// or populate its data with the values it receives from a GoTimeSettings
/// object.
///
/// @note The property @e customTimeSystemDescription only participates in the
/// conversion to/from GoTimeSettings, its value is never read from / written to
/// the user defaults. The reason is that user defaults need to be stored only
/// for values that the user selects when they start an entirely new game, but
/// in that scenario they cannot select to use a custom time system. Custom time
/// systems only come into play when loading a game from an .sgf file.
// -----------------------------------------------------------------------------
@interface TimeSettingsModel : NSObject
{
}

- (id) init;

- (void) readFromDictionary:(NSDictionary*)dictionary;
- (void) writeToDictionary:(NSMutableDictionary*)dictionary;

- (void) updateWithGoTimeSettings:(GoTimeSettings*)goTimeSettings;
- (GoTimeSettings*) goTimeSettingsRepresentation;

@property(nonatomic, assign) bool timedPlayEnabled;
@property(nonatomic, assign) bool absoluteTimingEnabled;
@property(nonatomic, assign) double absoluteTimingDurationInSeconds;
@property(nonatomic, assign) bool periodBasedTimeSystemEnabled;
@property(nonatomic, assign) enum GoTimeSystemType periodBasedTimeSystemType;
@property(nonatomic, assign) double canadianTimingPeriodDurationInSeconds;
@property(nonatomic, assign) unsigned long canadianTimingNumberOfMoves;
@property(nonatomic, assign) double japaneseTimingPeriodDurationInSeconds;
@property(nonatomic, assign) unsigned long japaneseTimingNumberOfPeriods;
@property(nonatomic, assign) double fischerTimingInitialTimeDurationInSeconds;
@property(nonatomic, assign) double fischerTimingExtraTimeDurationInSeconds;
@property(nonatomic, assign) double steadyAverageTimingPeriodDurationInSeconds;
@property(nonatomic, assign) unsigned long steadyAverageTimingNumberOfMoves;
@property(nonatomic, assign) double totalAverageTimingPeriodDurationInSeconds;
@property(nonatomic, assign) unsigned long totalAverageTimingNumberOfMoves;
@property(nonatomic, retain) NSString* customTimeSystemDescription;

@end
