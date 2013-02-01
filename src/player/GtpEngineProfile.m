// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpEngineProfile.h"
#import "../utility/NSStringAdditions.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpEngineProfile.
// -----------------------------------------------------------------------------
@interface GtpEngineProfile()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (NSString*) description;
- (int) playingStrength;
- (void) setPlayingStrength:(int)playingStrength;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* uuid;
//@}
@end


@implementation GtpEngineProfile

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngineProfile object with its attributes set to
/// sensible default values.
// -----------------------------------------------------------------------------
- (id) init
{
  // Invoke designated initializer
  return [self initWithDictionary:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngineProfile object with user defaults data stored
/// inside @a dictionary.
///
/// If @a dictionary is @e nil, the GtpEngineProfile object has its attributes
/// set to sensible default values. The UUID is randomly generated, while name
/// and description are empty strings.
///
/// Invoke the asDictionary() method to convert a GtpEngineProfile object's
/// user defaults attributes back into an NSDictionary suitable for storage in
/// the user defaults system.
///
/// @note This is the designated initializer of GtpEngineProfile.
// -----------------------------------------------------------------------------
- (id) initWithDictionary:(NSDictionary*)dictionary
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! dictionary)
  {
    self.uuid = [NSString UUIDString];
    self.name = @"";
    self.profileDescription = @"";
    [self resetToDefaultValues];
  }
  else
  {
    self.uuid = (NSString*)[dictionary valueForKey:gtpEngineProfileUUIDKey];
    self.name = (NSString*)[dictionary valueForKey:gtpEngineProfileNameKey];
    self.profileDescription = (NSString*)[dictionary valueForKey:gtpEngineProfileDescriptionKey];
    self.fuegoMaxMemory = [[dictionary valueForKey:fuegoMaxMemoryKey] intValue];
    self.fuegoThreadCount = [[dictionary valueForKey:fuegoThreadCountKey] intValue];
    self.fuegoPondering = [[dictionary valueForKey:fuegoPonderingKey] boolValue];
    self.fuegoMaxPonderTime = [[dictionary valueForKey:fuegoMaxPonderTimeKey] unsignedIntValue];
    self.fuegoReuseSubtree = [[dictionary valueForKey:fuegoReuseSubtreeKey] boolValue];
    self.fuegoMaxThinkingTime = [[dictionary valueForKey:fuegoMaxThinkingTimeKey] unsignedIntValue];
    self.fuegoMaxGames = [[dictionary valueForKey:fuegoMaxGamesKey] unsignedLongLongValue];
  }
  assert([self.uuid length] > 0);

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpEngineProfile object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.uuid = nil;
  self.name = nil;
  self.profileDescription = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GtpEngineProfile object.
///
/// This method is invoked when GtpEngineProfile needs to be represented as a
/// string, i.e. by NSLog, or when the debugger command "po" is used on the
/// object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GtpEngineProfile(%p): name = %@, uuid = %@", self, _name, _uuid];
}


// -----------------------------------------------------------------------------
/// @brief Returns this GtpEngineProfile object's user defaults attributes as a
/// dictionary suitable for storage in the user defaults system.
// -----------------------------------------------------------------------------
- (NSDictionary*) asDictionary
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:self.uuid forKey:gtpEngineProfileUUIDKey];
  [dictionary setValue:self.name forKey:gtpEngineProfileNameKey];
  [dictionary setValue:self.profileDescription forKey:gtpEngineProfileDescriptionKey];
  [dictionary setValue:[NSNumber numberWithInt:self.fuegoMaxMemory] forKey:fuegoMaxMemoryKey];
  [dictionary setValue:[NSNumber numberWithInt:self.fuegoThreadCount] forKey:fuegoThreadCountKey];
  [dictionary setValue:[NSNumber numberWithBool:self.fuegoPondering] forKey:fuegoPonderingKey];
  [dictionary setValue:[NSNumber numberWithUnsignedInt:self.fuegoMaxPonderTime] forKey:fuegoMaxPonderTimeKey];
  [dictionary setValue:[NSNumber numberWithBool:self.fuegoReuseSubtree] forKey:fuegoReuseSubtreeKey];
  [dictionary setValue:[NSNumber numberWithUnsignedInt:self.fuegoMaxThinkingTime] forKey:fuegoMaxThinkingTimeKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLongLong:self.fuegoMaxGames] forKey:fuegoMaxGamesKey];
  return dictionary;
}

// -----------------------------------------------------------------------------
/// @brief Applies the settings in this profile to the GTP engine.
// -----------------------------------------------------------------------------
- (void) applyProfile
{
  DDLogInfo(@"Applying GTP profile settings: %@", [self description]);

  NSString* commandString;
  GtpCommand* command;

  long long fuegoMaxMemoryInBytes = self.fuegoMaxMemory * 1000000;
  commandString = [NSString stringWithFormat:@"uct_max_memory %lld", fuegoMaxMemoryInBytes];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_search number_threads %d", self.fuegoThreadCount];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_player reuse_subtree %d", (self.fuegoReuseSubtree ? 1 : 0)];
  command = [GtpCommand command:commandString];
  [command submit];
  if (self.fuegoPondering)
    [GtpUtilities startPondering];
  else
    [GtpUtilities stopPondering];
  commandString = [NSString stringWithFormat:@"uct_param_player max_ponder_time %u", self.fuegoMaxPonderTime];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"go_param timelimit %u", self.fuegoMaxThinkingTime];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_player max_games %llu", self.fuegoMaxGames];
  command = [GtpCommand command:commandString];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if this GtpEngineProfile object is the default profile.
// -----------------------------------------------------------------------------
- (bool) isDefaultProfile
{
  return [self.uuid isEqualToString:defaultGtpEngineProfileUUID];
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (int) playingStrength
{
  int playingStrength = customPlayingStrength;

  if (fuegoMaxMemoryDefault == self.fuegoMaxMemory
      && fuegoThreadCountDefault == self.fuegoThreadCount
      && fuegoMaxPonderTimeDefault == self.fuegoMaxPonderTime
      && fuegoMaxThinkingTimeDefault == self.fuegoMaxThinkingTime)
  {
    if (fuegoMaxGamesPlayingStrength1 == self.fuegoMaxGames)
      playingStrength = 1;
    else if (fuegoMaxGamesPlayingStrength2 == self.fuegoMaxGames)
      playingStrength = 2;
    else if (fuegoMaxGamesPlayingStrength3 == self.fuegoMaxGames)
      playingStrength = 3;
    else if (fuegoMaxGamesMaximum == self.fuegoMaxGames)
    {
      if (self.fuegoReuseSubtree && self.fuegoPondering)
        playingStrength = 5;
      else if (self.fuegoReuseSubtree)
        playingStrength = 4;
    }
  }

  return playingStrength;
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (void) setPlayingStrength:(int)playingStrength
{
  // Thoughts behind the following pre-defined playing strengths
  // - Setting fuegoMaxGames to very low values is guaranteed to cripple Fuego,
  //   regardless of the device CPU's number crunching power. This is therefore
  //   the best way to limit playing strength at the low end of the scale.
  // - Raising the value of fuegoMaxGames should increase Fuego's playing
  //   strength
  // - At a certain point, fuegoMaxThinkingTime will become the limiting factor
  //   because the CPU will not be able to calculate all of the playouts
  //   allowed by fuegoMaxGames in the allotted time.
  // - At this point, we need to switch to some other limiting factor besides
  //   fuegoMaxGames and fuegoMaxThinkingTime. We cannot just raise
  //   fuegoMaxThinkingTime because for a good user experience, the computer
  //   player should not take too long for its turns.
  // - fuegoMaxMemory and fuegoThreadCount cannot be safely used because on
  //   older devices not much memory is available, or the CPU has only 1 core
  // - The best two settings that further increase playing strength therefore
  //   are "reuse subtree" and pondering. These possibly have a huge impact,
  //   so they are only turned on at the upper end of the scale. At the same
  //   time, any limitation on fuegoMaxGames is removed to make sure that the
  //   full time limit can be used if necessary.
  // - For an additional challenge, fuegoMaxThinkingTime could be increased,
  //   but since this affects the user experience the user has to do this
  //   herself
  //
  // Crucial points for a balanced scale are:
  // - What steps should be used to increase fuegoMaxGames from one level of
  //   playing strength to the next? The steps should be balanced so that the
  //   increase in playing strength becomes noticable.
  // - The balance may become disrupted on slower devices because there
  //   fuegoMaxThinkingTime will become the limiting factor much faster than
  //   on fast devices with more number crunching power

  [self resetToDefaultValues];

  // Don't rely on defaults for those parameters that make up playing strength,
  // because defaults might change. Instead, explicitly set those values that
  // have been pre-defined.
  self.fuegoPondering = false;
  self.fuegoReuseSubtree = false;
  self.fuegoMaxGames = fuegoMaxGamesMaximum;

  switch (playingStrength)
  {
    case 1:
      self.fuegoMaxGames = fuegoMaxGamesPlayingStrength1;
      break;
    case 2:
      self.fuegoMaxGames = fuegoMaxGamesPlayingStrength2;
      break;
    case 3:
      self.fuegoMaxGames = fuegoMaxGamesPlayingStrength3;
      break;
    case 4:
      self.fuegoReuseSubtree = true;
      break;
    case 5:
      self.fuegoPondering = true;
      self.fuegoReuseSubtree = true;
      break;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Playing strength %d is invalid", playingStrength]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Resets the profile's GTP settings to their default values. Does not
/// modify the profile's UUID, name and description.
// -----------------------------------------------------------------------------
- (void) resetToDefaultValues
{
  self.fuegoMaxMemory = fuegoMaxMemoryDefault;
  self.fuegoThreadCount = fuegoThreadCountDefault;
  self.fuegoPondering = fuegoPonderingDefault;
  self.fuegoMaxPonderTime = fuegoMaxPonderTimeDefault;
  self.fuegoReuseSubtree = fuegoReuseSubtreeDefault;
  self.fuegoMaxThinkingTime = fuegoMaxThinkingTimeDefault;
  self.fuegoMaxGames = fuegoMaxGamesDefault;
}

@end
