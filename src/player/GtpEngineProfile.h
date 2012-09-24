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



// -----------------------------------------------------------------------------
/// @brief The GtpEngineProfile class collects settings that define the
/// behaviour of the GTP engine.
///
/// There is always one GtpEngineProfile object that is the default GTP engine
/// profile. This profile is the fallback profile if no other profile is
/// available or appropriate. The user cannot delete the default profile.
///
/// Circumstances where the default profile is used:
/// - If a game is started where both players are human
/// - If a profile is deleted that is still associated with a Player object,
///   then that Player object is re-associated with the default profile
// -----------------------------------------------------------------------------
@interface GtpEngineProfile : NSObject
{
}

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;
- (void) applyProfile;
- (bool) isDefaultProfile;

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

@end
