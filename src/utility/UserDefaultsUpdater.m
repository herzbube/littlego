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


// Project includes
#import "UserDefaultsUpdater.h"


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
+ (void) upgradeToVersion1;
@end


@implementation UserDefaultsUpdater


// -----------------------------------------------------------------------------
/// @brief Performs all the required upgrades. Returns the number of upgrades
/// performed.
///
/// @retval 0 No upgrades were performed.
/// @retval >0 The number of upgrades that were performed.
/// @retval -1 A downgrade was performed.
// -----------------------------------------------------------------------------
+ (int) upgrade
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  int applicationDomainVersion = [[userDefaults valueForKey:userDefaultsVersionApplicationDomainKey] intValue];
  int registrationDomainVersion = [[userDefaults valueForKey:userDefaultsVersionRegistrationDomainKey] intValue];


  int numberOfUpgradesPerformed = 0;  // aka the return value :-)
  if (applicationDomainVersion == registrationDomainVersion)
  {
    // nothing to do
  }
  else if (applicationDomainVersion > registrationDomainVersion)
  {
    DDLogWarn(@"UserDefaultsUpdater performs DOWNGRADE operation. Downgrade target version = %d, current version = %d",
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
      // versioning scheme, e.g. a new application version may go from user
      // defaults
      ++applicationDomainVersion;
      NSString* upgradeMethodName = [NSString stringWithFormat:@"upgradeToVersion%d", applicationDomainVersion];
      SEL upgradeSelector = NSSelectorFromString(upgradeMethodName);
      if ([[UserDefaultsUpdater class] respondsToSelector:upgradeSelector])
      {
        DDLogInfo(@"UserDefaultsUpdater performs incremental upgrade to version = %d. Final target version = %d",
                  applicationDomainVersion,
                  registrationDomainVersion);
        // TODO How do we learn of success/failure of upgradeSelector, and how
        // do we react to failure?
        [[UserDefaultsUpdater class] performSelector:upgradeSelector];
        ++numberOfUpgradesPerformed;
      }
    }
  }

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
+ (void) upgradeToVersion1
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  NSMutableDictionary* playViewDictionary = [NSMutableDictionary dictionaryWithDictionary:[userDefaults dictionaryForKey:playViewKey]];
  // No longer used, inner margin is now calculated depending on the board size
  [playViewDictionary removeObjectForKey:boardInnerMarginPercentageKey];
  // No longer used, distance is now calculated dynamically by PlayView
  [playViewDictionary removeObjectForKey:crossHairPointDistanceFromFingerKey];
  // New user preference
  [playViewDictionary setValue:[NSNumber numberWithBool:NO] forKey:placeStoneUnderFingerKey];
  [userDefaults setObject:playViewDictionary forKey:playViewKey];
  
  // Remove all user-defined players. The registration domain defaults nicely
  // demonstrate how players and GTP engine profiles can be combined, and it's
  // too complicated to upgrade user-defined players and still show useful
  // combinations.
  [userDefaults removeObjectForKey:playerListKey];

  // Remove all scoring user defaults. Too many changes in this dictionary,
  // and only 2 beta-testers are affected by the loss of 2 keys.
  [userDefaults removeObjectForKey:scoringKey];

  // Update the application domain version number
  const int newApplicationDomainVersion = 1;
  [userDefaults setValue:[NSNumber numberWithInt:newApplicationDomainVersion]
                  forKey:userDefaultsVersionApplicationDomainKey];
}

@end
