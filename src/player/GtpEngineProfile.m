// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GtpEngineProfileModel.h"
#import "../go/GoBoard.h"
#import "../go/GoGame.h"
#import "../gtp/GtpCommand.h"
#import "../gtp/GtpUtilities.h"
#import "../main/ApplicationDelegate.h"
#import "../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GtpEngineProfile.
// -----------------------------------------------------------------------------
@interface GtpEngineProfile()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite, getter=isActiveProfile) bool activeProfile;
@property(nonatomic, assign, readwrite) bool hasUnappliedChanges;
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
  self.activeProfile = false;
  self.hasUnappliedChanges = false;
  if (! dictionary)
  {
    self.uuid = [NSString UUIDString];
    self.name = @"";
    self.profileDescription = @"";
    _fuegoResignThreshold = [[NSMutableArray arrayWithCapacity:arraySizeFuegoResignThresholdDefault] retain];
    self.autoSelectFuegoResignMinGames = autoSelectFuegoResignMinGamesDefault;
    if (! self.autoSelectFuegoResignMinGames)
      self.fuegoResignMinGames = fuegoResignMinGamesDefault;
    [self resetPlayingStrengthPropertiesToDefaultValues];
    [self resetResignBehaviourPropertiesToDefaultValues];
  }
  else
  {
    self.uuid = [dictionary valueForKey:gtpEngineProfileUUIDKey];
    self.name = [dictionary valueForKey:gtpEngineProfileNameKey];
    self.profileDescription = [dictionary valueForKey:gtpEngineProfileDescriptionKey];
    self.fuegoMaxMemory = [[dictionary valueForKey:fuegoMaxMemoryKey] intValue];
    self.fuegoThreadCount = [[dictionary valueForKey:fuegoThreadCountKey] intValue];
    self.fuegoPondering = [[dictionary valueForKey:fuegoPonderingKey] boolValue];
    self.fuegoMaxPonderTime = [[dictionary valueForKey:fuegoMaxPonderTimeKey] unsignedIntValue];
    self.fuegoReuseSubtree = [[dictionary valueForKey:fuegoReuseSubtreeKey] boolValue];
    self.fuegoMaxThinkingTime = [[dictionary valueForKey:fuegoMaxThinkingTimeKey] unsignedIntValue];
    self.fuegoMaxGames = [[dictionary valueForKey:fuegoMaxGamesKey] unsignedLongLongValue];
    self.autoSelectFuegoResignMinGames = [[dictionary valueForKey:autoSelectFuegoResignMinGamesKey] boolValue];
    self.fuegoResignMinGames = [[dictionary valueForKey:fuegoResignMinGamesKey] unsignedLongLongValue];
    _fuegoResignThreshold = [[NSMutableArray arrayWithArray:[dictionary valueForKey:fuegoResignThresholdKey]] retain];
  }
  assert([self.uuid length] > 0);
  if ([self.uuid length] <= 0)
    DDLogError(@"%@: UUID length <= 0", self);
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
  [_fuegoResignThreshold release];
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
  [dictionary setValue:[NSNumber numberWithBool:self.autoSelectFuegoResignMinGames] forKey:autoSelectFuegoResignMinGamesKey];
  [dictionary setValue:[NSNumber numberWithUnsignedLongLong:self.fuegoResignMinGames] forKey:fuegoResignMinGamesKey];
  [dictionary setValue:_fuegoResignThreshold forKey:fuegoResignThresholdKey];
  return dictionary;
}

// -----------------------------------------------------------------------------
/// @brief Applies the settings in this profile to the GTP engine and activates
/// this profile if it is not yet active. Also clears the hasUnappliedChanges
/// property.
///
/// If a different profile is active when this method is invoked, that profile
/// is deactivated first.
///
/// This method returns control to the caller before all GTP commands have been
/// processed.
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
  commandString = [NSString stringWithFormat:@"uct_param_player resign_min_games %llu", self.fuegoResignMinGames];
  command = [GtpCommand command:commandString];
  [command submit];
  int resignThreshold = [self resignThresholdForBoardSize:[GoGame sharedGame].board.size];
  commandString = [NSString stringWithFormat:@"uct_param_player resign_threshold %f", resignThreshold / 100.0];
  command = [GtpCommand command:commandString];
  [command submit];

  self.hasUnappliedChanges = false;
  if (! self.isActiveProfile)
  {
    GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
    GtpEngineProfile* activeProfile = [model activeProfile];
    if (activeProfile)
    {
      assert(activeProfile != self);
      if (activeProfile == self)
        DDLogError(@"%@: GtpEngineProfileModel thinks this is the active profile, but the isActiveProfile flag is false", [self description]);
      activeProfile.activeProfile = false;
    }
    self.activeProfile = true;
  }
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

  [self resetPlayingStrengthPropertiesToDefaultValues];

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
      NSString* errorMessage = [NSString stringWithFormat:@"Playing strength %d is invalid", playingStrength];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Resets those properties to their default values that are related to
/// playing strength.
// -----------------------------------------------------------------------------
- (void) resetPlayingStrengthPropertiesToDefaultValues
{
  self.fuegoMaxMemory = fuegoMaxMemoryDefault;
  self.fuegoThreadCount = fuegoThreadCountDefault;
  self.fuegoPondering = fuegoPonderingDefault;
  self.fuegoMaxPonderTime = fuegoMaxPonderTimeDefault;
  self.fuegoReuseSubtree = fuegoReuseSubtreeDefault;
  self.fuegoMaxThinkingTime = fuegoMaxThinkingTimeDefault;
  self.fuegoMaxGames = fuegoMaxGamesDefault;
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (int) resignBehaviour
{
  int resignBehaviour = customResignBehaviour;
  for (int resignBehaviourLoop = minimumResignBehaviour; resignBehaviourLoop <= maximumResignBehaviour; ++resignBehaviourLoop)
  {
    float resignThresholdBias = [self resignThresholdBiasForResignBehaviour:resignBehaviourLoop];
    bool resignBehaviourFound = true;
    for (int arrayIndex = 0; arrayIndex < arraySizeFuegoResignThresholdDefault; ++arrayIndex)
    {
      int resignThresholdDefault = fuegoResignThresholdDefault[arrayIndex];
      int resignThresholdBiased = resignThresholdDefault * resignThresholdBias;
      enum GoBoardSize boardSize = [self boardSizeForResignThresholdIndex:arrayIndex];
      int resignThreshold = [self resignThresholdForBoardSize:boardSize];
      if (resignThreshold != resignThresholdBiased)
      {
        resignBehaviourFound = false;
        break;
      }
    }
    if (resignBehaviourFound)
    {
      resignBehaviour = resignBehaviourLoop;
      break;
    }
  }
  return resignBehaviour;
}

// -----------------------------------------------------------------------------
// See property documentation. This property is not synthesized.
// -----------------------------------------------------------------------------
- (void) setResignBehaviour:(int)resignBehaviour
{
  float resignThresholdBias = [self resignThresholdBiasForResignBehaviour:resignBehaviour];
  [self resetResignBehaviourPropertiesToDefaultValues];
  for (int arrayIndex = 0; arrayIndex < arraySizeFuegoResignThresholdDefault; ++arrayIndex)
  {
    int resignThresholdDefault = fuegoResignThresholdDefault[arrayIndex];
    int resignThresholdBiased = resignThresholdDefault * resignThresholdBias;
    enum GoBoardSize boardSize = [self boardSizeForResignThresholdIndex:arrayIndex];
    [self setResignThreshold:resignThresholdBiased forBoardSize:boardSize];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (float) resignThresholdBiasForResignBehaviour:(int)resignBehaviour
{
  switch (resignBehaviour)
  {
    case 1:
      return 2.0;
    case 2:
      return 1.5;
    case 3:
      return 1.0;
    case 4:
      return 0.5;
    case 5:
      return 0.0;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Resign behaviour %d is invalid", resignBehaviour];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Resets those properties to their default values that are related to
/// the computer player's resign behaviour.
// -----------------------------------------------------------------------------
- (void) resetResignBehaviourPropertiesToDefaultValues
{
  for (int arrayIndex = 0; arrayIndex < arraySizeFuegoResignThresholdDefault; ++arrayIndex)
  {
    int resignThresholdDefault = fuegoResignThresholdDefault[arrayIndex];
    enum GoBoardSize boardSize = [self boardSizeForResignThresholdIndex:arrayIndex];
    [self setResignThreshold:resignThresholdDefault forBoardSize:boardSize];
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoMaxMemory:(int)newValue
{
  if (_fuegoMaxMemory == newValue)
    return;
  _fuegoMaxMemory = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoThreadCount:(int)newValue
{
  if (_fuegoThreadCount == newValue)
    return;
  _fuegoThreadCount = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoPondering:(bool)newValue
{
  if (_fuegoPondering == newValue)
    return;
  _fuegoPondering = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoMaxPonderTime:(unsigned int)newValue
{
  if (_fuegoMaxPonderTime == newValue)
    return;
  _fuegoMaxPonderTime = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoReuseSubtree:(bool)newValue
{
  if (_fuegoReuseSubtree == newValue)
    return;
  _fuegoReuseSubtree = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoMaxThinkingTime:(unsigned int)newValue
{
  if (_fuegoMaxThinkingTime == newValue)
    return;
  _fuegoMaxThinkingTime = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoMaxGames:(unsigned long long)newValue
{
  if (_fuegoMaxGames == newValue)
    return;
  _fuegoMaxGames = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
  if (self.autoSelectFuegoResignMinGames)
    self.fuegoResignMinGames = [GtpEngineProfile fuegoResignMinGamesForMaxGames:_fuegoMaxGames];
}

// -----------------------------------------------------------------------------
/// @brief Returns a @e fuegoResignMinGames property value that is appropriate
/// for @a maxGames according to the @e fuegoResignMinGames auto-selection
/// rules.
///
/// @see Property @e autoSelectFuegoResignMinGames.
// -----------------------------------------------------------------------------
+ (unsigned long long) fuegoResignMinGamesForMaxGames:(unsigned long long)maxGames
{
  if (maxGames > fuegoResignMinGamesDefault)
    return fuegoResignMinGamesDefault;
  else if (maxGames > 100)
    return (maxGames - 50);
  else
    return (maxGames - 1);
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setAutoSelectFuegoResignMinGames:(bool)newValue
{
  if (_autoSelectFuegoResignMinGames == newValue)
    return;
  _autoSelectFuegoResignMinGames = newValue;
  if (_autoSelectFuegoResignMinGames)
    self.fuegoResignMinGames = [GtpEngineProfile fuegoResignMinGamesForMaxGames:_fuegoMaxGames];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setFuegoResignMinGames:(unsigned long long)newValue
{
  if (_fuegoResignMinGames == newValue)
    return;
  _fuegoResignMinGames = newValue;
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
/// @brief Convenience accessor to read values from the property
/// @e fuegoResignThreshold.
// -----------------------------------------------------------------------------
- (int) resignThresholdForBoardSize:(enum GoBoardSize)boardSize
{
  int arrayIndex = [self resignThresholdIndexForBoardSize:boardSize];
  NSNumber* resignThreshold = [_fuegoResignThreshold objectAtIndex:arrayIndex];
  return [resignThreshold intValue];
}

// -----------------------------------------------------------------------------
/// @brief Convenience accessor to write values to the property
/// @e fuegoResignThreshold.
// -----------------------------------------------------------------------------
- (void) setResignThreshold:(int)newValue forBoardSize:(enum GoBoardSize)boardSize
{
  int oldValue = [self resignThresholdForBoardSize:boardSize];
  if (oldValue == newValue)
    return;
  int arrayIndex = [self resignThresholdIndexForBoardSize:boardSize];
  [(NSMutableArray*)_fuegoResignThreshold replaceObjectAtIndex:arrayIndex
                                                    withObject:[NSNumber numberWithInt:newValue]];
  if (self.isActiveProfile)
    self.hasUnappliedChanges = true;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (int) resignThresholdIndexForBoardSize:(enum GoBoardSize)boardSize
{
  return (boardSize - GoBoardSizeMin) / 2;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (enum GoBoardSize) boardSizeForResignThresholdIndex:(int)index
{
  return (GoBoardSizeMin + 2 * index);
}

@end
