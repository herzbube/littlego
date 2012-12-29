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
#import "UserDefaultsUpdater.h"
#import "UIDeviceAdditions.h"
#import "../go/GoUtilities.h"


// -----------------------------------------------------------------------------
/// @brief User defaults keys and values that are no longer active but that
/// are still used to perform upgrades.
// -----------------------------------------------------------------------------
//@{
NSString* boardInnerMarginPercentageKey = @"BoardInnerMarginPercentage";
NSString* crossHairPointDistanceFromFingerKey = @"CrossHairPointDistanceFromFinger";
//@}

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for UserDefaultsUpdater.
// -----------------------------------------------------------------------------
@interface UserDefaultsUpdater()
/// @name Upgrade methods
//@{
+ (void) upgradeToVersion1:(NSDictionary*)registrationDomainDefaults;
+ (void) upgradeToVersion2:(NSDictionary*)registrationDomainDefaults;
+ (void) upgradeToVersion3:(NSDictionary*)registrationDomainDefaults;
+ (void) upgradeToVersion4:(NSDictionary*)registrationDomainDefaults;
+ (void) upgradeToVersion5:(NSDictionary*)registrationDomainDefaults;
//@}
/// @name Internal helpers
//@{
+ (void) upgradeDictionary:(NSMutableDictionary*)dictionary forKey:(NSString*)key upgradeDeviceSuffix:(NSString*)upgradeDeviceSuffix registrationDomainDefaults:(NSDictionary*)registrationDomainDefaults;
//@}
@end


@implementation UserDefaultsUpdater


// -----------------------------------------------------------------------------
/// @brief Performs all the required upgrades to the user defaults data to reach
/// the data format that matches the one present in the registration domain
/// defaults dictionary @a registrationDomainDefaults.
///
/// Returns the number of upgrades performed. Probably the most interesting
/// thing about this number is whether it is zero (no upgrades were performed)
/// or non-zero (some upgrades were performed). The actual numeric value
/// probably has a low information value.
///
/// @note Since it is possible to have gaps in the version numbering scheme
/// (see class documentation for details), it is not possible to infer from the
/// number of upgrades that is returned which format the user defaults were in
/// when the upgrade process started its work.
///
/// @retval 0 No upgrades were performed.
/// @retval >0 The number of upgrades that were performed.
/// @retval -1 A downgrade was performed.
///
/// Raises an @e NSInternalInconsistencyException if it is found that
/// @a registrationDomainDefaults have already been registered in the user
/// defaults system.
// -----------------------------------------------------------------------------
+ (int) upgradeToRegistrationDomainDefaults:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Perform the check whether registration domain defaults are already
  // registered only once. The reason for this is that during unit tests this
  // method may be invoked multiple times, but from the 2nd time onwards the
  // registration domain defaults will always be present.
  static int numberOfTimesThisMethodHasBeenInvoked = 0;
  ++numberOfTimesThisMethodHasBeenInvoked;
  if (1 == numberOfTimesThisMethodHasBeenInvoked)
  {
    id registrationDomainVersionInUserDefaults = [userDefaults objectForKey:userDefaultsVersionRegistrationDomainKey];
    if (registrationDomainVersionInUserDefaults)
    {
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:@"UserDefaultsUpdater: Aborting upgrade, registration domain defaults are already registered"
                                                     userInfo:nil];
      @throw exception;
    }
  }

  int registrationDomainVersion = [[registrationDomainDefaults valueForKey:userDefaultsVersionRegistrationDomainKey] intValue];
  int applicationDomainVersion = [[userDefaults valueForKey:userDefaultsVersionApplicationDomainKey] intValue];
  int numberOfUpgradesPerformed = 0;  // aka the return value :-)
  if (applicationDomainVersion == registrationDomainVersion)
  {
    // nothing to do
  }
  else if (applicationDomainVersion > registrationDomainVersion)
  {
    DDLogWarn(@"UserDefaultsUpdater performs DOWNGRADE operation. Downgrade to target version = %d, current version = %d",
              registrationDomainVersion,
              applicationDomainVersion);
    // TODO perform downgrade
    numberOfUpgradesPerformed = -1;
  }
  else
  {
    while (applicationDomainVersion < registrationDomainVersion)
    {
      // Incrementally perform upgrades. We allow for gaps in the user defaults
      // versioning scheme.
      ++applicationDomainVersion;
      NSString* upgradeMethodName = [NSString stringWithFormat:@"upgradeToVersion%d:", applicationDomainVersion];
      SEL upgradeSelector = NSSelectorFromString(upgradeMethodName);
      if ([[UserDefaultsUpdater class] respondsToSelector:upgradeSelector])
      {
        DDLogInfo(@"UserDefaultsUpdater performs incremental upgrade to version = %d. Final target version = %d",
                  applicationDomainVersion,
                  registrationDomainVersion);
        // TODO How do we learn of success/failure of upgradeSelector, and how
        // do we react to failure?
        [[UserDefaultsUpdater class] performSelector:upgradeSelector withObject:registrationDomainDefaults];
        ++numberOfUpgradesPerformed;
        // Update the application domain version number
        [userDefaults setValue:[NSNumber numberWithInt:applicationDomainVersion]
                        forKey:userDefaultsVersionApplicationDomainKey];
      }
    }
  }
  [userDefaults synchronize];

  // Perform final check if the cumulative effect of all upgrades had the
  // desired effect.
  int realApplicationDomainVersion = [[userDefaults valueForKey:userDefaultsVersionApplicationDomainKey] intValue];
  if (realApplicationDomainVersion != registrationDomainVersion)
  {
    DDLogError(@"UserDefaultsUpdater failed! Current version after upgrades = %d, but should be %d",
              realApplicationDomainVersion,
              registrationDomainVersion);
    // TODO: Display an alert that notifies the user of the problem. The alert
    // should probably recommend a re-install. Also decide whether to allow the
    // user to continue, or to gracefully shutdown the application.
  }

  return numberOfUpgradesPerformed;
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 1.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion1:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    // No longer used, inner margin is now calculated depending on the board size
    [playViewDictionaryUpgrade removeObjectForKey:boardInnerMarginPercentageKey];
    // No longer used, distance is now calculated dynamically by PlayView
    [playViewDictionaryUpgrade removeObjectForKey:crossHairPointDistanceFromFingerKey];
    // New user preference
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithBool:NO] forKey:placeStoneUnderFingerKey];
    [userDefaults setObject:playViewDictionaryUpgrade forKey:playViewKey];
  }

  // Remove all user-defined players. The registration domain defaults nicely
  // demonstrate how players and GTP engine profiles can be combined, and it's
  // too complicated to upgrade user-defined players and still show useful
  // combinations.
  [userDefaults removeObjectForKey:playerListKey];

  // Remove all scoring user defaults. Too many changes in this dictionary,
  // and only 2 beta-testers are affected by the loss of 2 keys.
  [userDefaults removeObjectForKey:scoringKey];
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 2.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion2:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // The previous app version had a bug that might have allowed the user to
  // select a handicap for new games that was greater than the maximum handicap
  // allowed by certain small board sizes. If the illegal value managed to get
  // into the user defaults sysem we need to fix it here.
  id newGameDictionary = [userDefaults objectForKey:newGameKey];
  if (newGameDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* newGameDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:newGameDictionary];
    // This user defaults format still uses an index-based board size
    // -> convert to natural board size just for executing code, but DON'T
    //    convert value in the user defaults: this is done by the next
    //    incremental upgrade
    int indexBasedBoardSize = [[newGameDictionaryUpgrade valueForKey:boardSizeKey] intValue];
    enum GoBoardSize naturalBoardSize = GoBoardSizeMin + indexBasedBoardSize * 2;
    int handicap = [[newGameDictionaryUpgrade valueForKey:handicapKey] intValue];
    int maximumHandicap = [GoUtilities maximumHandicapForBoardSize:naturalBoardSize];
    if (handicap > maximumHandicap)
    {
      [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:maximumHandicap] forKey:handicapKey];
      [userDefaults setObject:newGameDictionaryUpgrade forKey:newGameKey];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 3.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion3:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Numeric values for enumerated board sizes now correspond to natural board
  // sizes (e.g. the numeric value for BoardSize9 is now 9), whereas previously
  // numeric values for enumerated board sizes simply started with 0 and
  // monotonically increased by 1 per board size (e.g. the numeric value for
  // BoardSize7 was 0, for BoardSize9 it was 1, and so on). Here we need to
  // convert from the old-style to the new-style board size.
  id newGameDictionary = [userDefaults objectForKey:newGameKey];
  if (newGameDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* newGameDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:newGameDictionary];
    int indexBasedBoardSize = [[newGameDictionaryUpgrade valueForKey:boardSizeKey] intValue];
    int naturalBoardSize = GoBoardSizeMin + indexBasedBoardSize * 2;
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:naturalBoardSize] forKey:boardSizeKey];
    [userDefaults setObject:newGameDictionaryUpgrade forKey:newGameKey];
  }

  // A number of keys now exist only as device-specific variants so that we can
  // have different factory settings for different devices. We need to add
  // those device-specific keys to the PlayView dictionary, while retaining
  // the values that were previously stored under the key's base name.
  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    NSMutableDictionary* playViewDictionaryRegistrationDomain = [registrationDomainDefaults objectForKey:playViewKey];

    NSArray* keysWithoutDeviceSuffix = [NSArray arrayWithObjects:boundingLineWidthKey, starPointRadiusKey, placeStoneUnderFingerKey, nil];
    for (NSString* keyWithoutDeviceSuffix in keysWithoutDeviceSuffix)
    {
      NSString* upgradeDeviceSuffix;
      if ([keyWithoutDeviceSuffix isEqualToString:placeStoneUnderFingerKey])
      {
        // This user default can be changed by the user, so we preserve the
        // current value for the current device.
        upgradeDeviceSuffix = [UIDevice currentDeviceSuffix];
      }
      else
      {
        // These user defaults cannot be changed by the user, so we discard
        // their current values and instead take the values from the
        // registration domain defaults. For iPad users this will result in a
        // change because we are introducing new iPad-specific values in this
        // release.
        upgradeDeviceSuffix = nil;
      }
      [UserDefaultsUpdater upgradeDictionary:playViewDictionaryUpgrade
                                      forKey:keyWithoutDeviceSuffix
                         upgradeDeviceSuffix:upgradeDeviceSuffix
                  registrationDomainDefaults:playViewDictionaryRegistrationDomain];
    }

    [userDefaults setObject:playViewDictionaryUpgrade forKey:playViewKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 4.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion4:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Every GTP engine profile now has a number of additional keys
  id profileListArray = [userDefaults objectForKey:gtpEngineProfileListKey];
  if (profileListArray)  // is nil if the key is not present
  {
    NSMutableArray* profileListArrayUpgrade = [NSMutableArray array];
    for (NSDictionary* profileDictionary in profileListArray)
    {
      NSMutableDictionary* profileDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:profileDictionary];
      [profileDictionaryUpgrade setValue:[NSNumber numberWithUnsignedInt:fuegoMaxPonderTimeDefault] forKey:fuegoMaxPonderTimeKey];
      [profileDictionaryUpgrade setValue:[NSNumber numberWithUnsignedInt:fuegoMaxThinkingTimeDefault] forKey:fuegoMaxThinkingTimeKey];
      [profileDictionaryUpgrade setValue:[NSNumber numberWithUnsignedLongLong:fuegoMaxGamesDefault] forKey:fuegoMaxGamesKey];
      [profileListArrayUpgrade addObject:profileDictionaryUpgrade];
    }
    [userDefaults setObject:profileListArrayUpgrade forKey:gtpEngineProfileListKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 5.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion5:(NSDictionary*)registrationDomainDefaults
{
  // Add new dictionary with board position settings.
  //
  // Note: Although it would be much easier to do nothing in this upgrade and
  // simply let the application pick up the settings from the registration
  // domain defaults, doing so has the potential to make future upgrades more
  // complicated (e.g. a future upgrade inserting a new board position settings
  // key would first have to check if the dictionary is present). It is
  // therefore better not to postpone this work and just do what we need to do
  // right here where it belongs to the correct format version.
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithBool:discardFutureMovesAlertDefault] forKey:discardFutureMovesAlertKey];
  [dictionary setValue:[NSNumber numberWithBool:playOnComputersTurnAlertDefault] forKey:playOnComputersTurnAlertKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:boardPositionKey];
}

// -----------------------------------------------------------------------------
/// @brief Upgrades @a dictionary so that after the upgrade it contains
/// device-specific keys that match the device-agnostic @a key for all
/// supported devices.
///
/// If @a dictionary contains a value for the device-agnostic @a key, that value
/// will be preserved under a new device-specific key that is formed by tacking
/// @a upgradeDeviceSuffix on to @a key. If @a upgradeDeviceSuffix is nil, the
/// device-agnostic value will be discarded.
///
/// The values for the other device-specific keys are taken from
/// @a registrationDomainDefaults, unless @a dictionary already contains a value
/// for a device-specific key, in which case that value is preserved.
///
/// @note @a registrationDomainDefaults must be a sub-dictionary that
/// corresponds to @a dictionary, @e not the entire registration domain defaults
/// dictionary.
///
/// @note This method was implemented with the goal in mind that it can be
/// reused if 1) in the future more keys become device-specific, and 2) more
/// devices become supported.
// -----------------------------------------------------------------------------
+ (void) upgradeDictionary:(NSMutableDictionary*)dictionary forKey:(NSString*)key upgradeDeviceSuffix:(NSString*)upgradeDeviceSuffix registrationDomainDefaults:(NSDictionary*)registrationDomainDefaults
{
  id valueForKeyWithoutDeviceSuffix = [dictionary objectForKey:key];
  if (valueForKeyWithoutDeviceSuffix)
  {
    [dictionary removeObjectForKey:key];
    if (nil != upgradeDeviceSuffix)
    {
      NSString* keyWithUpgradeDeviceSuffix = [key stringByAppendingString:upgradeDeviceSuffix];
      [dictionary setValue:valueForKeyWithoutDeviceSuffix forKey:keyWithUpgradeDeviceSuffix];
    }
  }

  for (NSString* deviceSuffix in [UIDevice deviceSuffixes])
  {
    NSString* keyWithDeviceSuffix = [key stringByAppendingString:deviceSuffix];
    id valueForKeyWithDeviceSuffix = [dictionary objectForKey:keyWithDeviceSuffix];
    if (! valueForKeyWithDeviceSuffix)
    {
      id valueFromRegistrationDomainDefaults = [registrationDomainDefaults valueForKey:keyWithDeviceSuffix];
      [dictionary setValue:valueFromRegistrationDomainDefaults forKey:keyWithDeviceSuffix];
    }
  }
}

@end
