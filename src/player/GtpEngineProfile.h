// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The GtpEngineProfile class collects settings that define the
/// behaviour of the GTP engine.
///
/// There is always one GtpEngineProfile object that is used for human vs. human
/// games. This profile is the fallback profile if no other profile is
/// available or appropriate. The user cannot delete the human vs. human games
/// profile.
///
/// Circumstances where the human vs. human games profile is used:
/// - If a game is started where both players are human
/// - If a profile is deleted that is still associated with a Player object,
///   then that Player object is re-associated with another profile. If the only
///   profile that still exists is the human vs. human games profile, then that
///   profile is used as the fallback.
///
///
/// @par Active profile
///
/// The active GTP engine profile is the one with whose settings the GTP is
/// currently configured.
///
/// A profile becomes active when its applyProfile() method is invoked. If
/// another profile is already active, applyProfile() deactivates that profile.
/// Only one profile at a time can be active.
///
/// When the application launches there is a brief span of time during which
/// the GTP engine is not yet configured, and during which there is no active
/// profile.
///
///
/// @par Playing strength
///
/// The value of the @e playingStrength property of a GtpEngineProfile denotes
/// the relative playing strength of a computer player that uses the profile.
/// A lower value indicates a weaker player, while a higher value indicates a
/// stronger player.
///
/// Each playing strength value represents a certain pre-defined (i.e.
/// hardcoded) combination of GTP engine settings. Changing a GtpEngineProfile's
/// playing strength will result in the profile's settings being updated to the
/// combination of values that represent the new playing strength. Only playing
/// strengths in the range between #minimumPlayingStrength and
/// #maximumPlayingStrength can be assigned. An exception is raised if you try
/// to assign any other value.
///
/// When querying the property, the value #customPlayingStrength indicates an
/// unknown (i.e. not pre-defined) combination of profile settings.
///
///
/// @par Resign behaviour
///
/// The value of the @e resignBehaviour property of a GtpEngineProfile denotes
/// how quickly a computer player that uses the profile will resign. Higher
/// values indicate that the computer player will play more stubborn, i.e. it
/// is less likely that the computer player will resign. The highest value
/// (#maximumResignBehaviour) indicates that the computer player will never
/// resign.
///
/// Each resign behaviour represents a bias used to modify the default resign
/// threshold values for each board size. The bias is a simple multiplier.
/// Resign behaviours do not modify @e fuegoResignMinGames, they let this
/// property be auto-managed by setting autoSelectFuegoResignMinGames to true.
///
/// When querying the property, the value #customResignBehaviour indicates an
/// unknown (i.e. not pre-defined) resign behaviour.
// -----------------------------------------------------------------------------
@interface GtpEngineProfile : NSObject
{
}

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;
- (void) applyProfile;
- (bool) isFallbackProfile;
- (void) resetPlayingStrengthPropertiesToDefaultValues;
- (void) resetResignBehaviourPropertiesToDefaultValues;
- (int) resignThresholdForBoardSize:(enum GoBoardSize)boardSize;
- (void) setResignThreshold:(int)threshold forBoardSize:(enum GoBoardSize)boardSize;

+ (unsigned long long) fuegoResignMinGamesForMaxGames:(unsigned long long)maxGames;


// -----------------------------------------------------------------------------
/// @name Properties that are not user defaults
// -----------------------------------------------------------------------------
//@{
/// @brief Is true if this is the active profile. See class documentation for
/// details.
@property(nonatomic, assign, readonly, getter=isActiveProfile) bool activeProfile;
/// @brief Is true if this is the active profile and one or more of this
/// profile's GTP properties were changed since the last time that applyProfile
/// was invoked.
///
/// This flag is always false if this is not the active profile.
@property(nonatomic, assign, readonly) bool hasUnappliedChanges;
/// @brief The playing strength of this profile. See class documentation for
/// details. Assigning a value outside the range of pre-defined playing
/// strengths results in an exception being raised.
@property(nonatomic, assign) int playingStrength;
/// @brief The resign behaviour of this profile. See class documentation for
/// details. Assigning a value outside the range of pre-defined resign
/// behaviours results in an exception being raised.
@property(nonatomic, assign) int resignBehaviour;
//@}
// -----------------------------------------------------------------------------
/// @name Simple user defaults properties
// -----------------------------------------------------------------------------
//@{
/// @brief The profile's UUID. This is a technical identifier guaranteed to be
/// unique. This identifier is never displayed in the GUI.
@property(nonatomic, retain, readonly) NSString* uuid;
/// @brief The profile's name. A short string that uniquely identifies the
/// profile and is displayed in the GUI in places where only short strings are
/// appropriate.
@property(nonatomic, retain) NSString* name;
/// @brief The profile's description. A longer string that describes the
/// profile's purpose and characteristics in human-readable terms. This property
/// is displayed in the GUI only in places where a long string is appropriate.
///
/// This property is named "profileDescription" instead of just "description"
/// to prevent a conflict with the description() debugging aid.
@property(nonatomic, retain) NSString* profileDescription;
/// @brief The value of this flag decides whether @e fuegoResignMinGames is
/// automatically calculated (flag is true), or must be manually selected by
/// the user (flag is false).
///
/// This flag is true by default. Automatic calculation of
/// @e fuegoResignMinGames ensures that @e fuegoResignMinGames is never >=
/// @e fuegoMaxGames, i.e. it ensures that Fuego will always be able to resign.
@property(nonatomic, assign) bool autoSelectFuegoResignMinGames;
//@}
// -----------------------------------------------------------------------------
/// @name User defaults properties applicable to the GTP engine
// -----------------------------------------------------------------------------
//@{
/// @brief The maximum amount of memory in MB that the Fuego GTP engine is
/// allowed to consume.
@property(nonatomic, assign) int fuegoMaxMemory;
/// @brief The number of threads that the Fuego GTP engine should use for its
/// calculations.
@property(nonatomic, assign) int fuegoThreadCount;
/// @brief True if Fuego should play with pondering on.
@property(nonatomic, assign) bool fuegoPondering;
/// @brief Maximum time in seconds that Fuego is allowed to ponder (i.e. think
/// while it is the opponent's turn).
@property(nonatomic, assign) unsigned int fuegoMaxPonderTime;
/// @brief True if Fuego should reuse the subtree from the previous search.
@property(nonatomic, assign) bool fuegoReuseSubtree;
/// @brief Maximum time in seconds that Fuego is allowed to think on its own
/// turn.
@property(nonatomic, assign) unsigned int fuegoMaxThinkingTime;
/// @brief Maximum number of games that Fuego is allowed to play before it must
/// decide on a best move.
@property(nonatomic, assign) unsigned long long fuegoMaxGames;
/// @brief Minimum number of games that Fuego must play before it is allowed to
/// make a decision about resigning.
///
/// Fuego will never resign if this is >= @e fuegoMaxGames, because in that
/// case it will never calculate more than @e fuegoResignMinGames games. If
/// @e autoSelectFuegoResignMinGames is true, this scenario will never occur
/// because @e fuegoResignMinGames is automatically calculated to ensure that
/// it will stay below @e fuegoMaxGames.
@property(nonatomic, assign) unsigned long long fuegoResignMinGames;
/// @brief Fuego resigns if the quality of the best move it could find is below
/// this threshold. The condition for fuegoResignMinGames must also be met.
///
/// This property stores separate thresholds for each possible board size.
/// The array contains NSNumber objects with integer values inside. Each integer
/// is in the range between 0 and 100 and represents a percentage. The object
/// at index position 0 represents the threshold for the smallest board
/// (#GoBoardSize7).
///
/// Use the convenience accessor methods resignThresholdForBoardSize:() and
/// setResignThreshold:forBoardSize:() instead of accessing this property
/// directly.
@property(nonatomic, retain, readonly) NSArray* fuegoResignThreshold;
//@}

@end
