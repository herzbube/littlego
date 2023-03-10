// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/Player.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/NSStringAdditions.h"


// -----------------------------------------------------------------------------
/// @brief User defaults keys and values that are no longer active but that
/// are still used to perform upgrades.
// -----------------------------------------------------------------------------
//@{
NSString* boardInnerMarginPercentageKey = @"BoardInnerMarginPercentage";
NSString* crossHairPointDistanceFromFingerKey = @"CrossHairPointDistanceFromFinger";
NSString* blackPlayerKey = @"BlackPlayer";
NSString* whitePlayerKey = @"WhitePlayer";
NSString* placeStoneUnderFingerKey = @"PlaceStoneUnderFinger";
NSString* displayMoveNumbersKey = @"DisplayMoveNumbers";
NSString* boardPositionLastViewedKey = @"BoardPositionLastViewed";
NSString* boardOuterMarginPercentageKey = @"BoardOuterMarginPercentage";
const float stoneDistanceFromFingertipMaximum = 4.0;
const float maximumZoomScaleDefault = 3.0;
NSString* playViewKey = @"PlayView";
NSString* backgroundColorKey = @"BackgroundColor";
NSString* boardColorKey = @"BoardColor";
NSString* lineColorKey = @"LineColor";
NSString* boundingLineWidthKey = @"BoundingLineWidth";
NSString* normalLineWidthKey = @"NormalLineWidth";
NSString* starPointColorKey = @"StarPointColor";
NSString* starPointRadiusKey = @"StarPointRadius";
NSString* stoneRadiusPercentageKey = @"StoneRadiusPercentage";
NSString* crossHairColorKey = @"CrossHairColor";
NSString* alphaTerritoryColorBlackKey = @"AlphaTerritoryColorBlack";
NSString* alphaTerritoryColorWhiteKey = @"AlphaTerritoryColorWhite";
NSString* deadStoneSymbolColorKey = @"DeadStoneSymbolColor";
NSString* deadStoneSymbolPercentageKey = @"DeadStoneSymbolPercentage";
NSString* inconsistentTerritoryDotSymbolColorKey = @"InconsistentTerritoryDotSymbolColor";
NSString* inconsistentTerritoryDotSymbolPercentageKey = @"InconsistentTerritoryDotSymbolPercentage";
NSString* inconsistentTerritoryFillColorKey = @"InconsistentTerritoryFillColor";
NSString* inconsistentTerritoryFillColorAlphaKey = @"InconsistentTerritoryFillColorAlpha";
NSString* blackSekiSymbolColorKey = @"BlackSekiSymbolColor";
NSString* whiteSekiSymbolColorKey = @"WhiteSekiSymbolColor";
NSString* maximumZoomScaleKey = @"MaximumZoomScale";
NSString* selectedTabIndexKey = @"SelectedTabIndex";
NSString* stoneDistanceFromFingertipKey = @"StoneDistanceFromFingertip";
const float stoneDistanceFromFingertipDefault = 0.5;
NSString* scoreWhenGameEndsKey = @"ScoreWhenGameEnds";
NSString* discardFutureMovesAlertKey = @"DiscardFutureMovesAlert";
NSString* crashDataContactAllowKey = @"CrashDataContactAllowKey";
NSString* crashDataContactEmailKey = @"CrashDataContactEmailKey";
//@}


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
      NSString* errorMessage = @"UserDefaultsUpdater: Aborting upgrade, registration domain defaults are already registered";
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                       reason:errorMessage
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
  else if (0 == applicationDomainVersion)
  {
    // Theoretically, applicationDomainVersion could also be 0 if an extremely
    // old version of the source code were built & run, i.e. one before user
    // defaults versioning was introduced. User defaults versioning was
    // introduced during the work for version 0.6 of the project (actually, in
    // commit aee80ead04a34b274932199878a4f3e1b06bf9b8), i.e. well before the
    // first public release on the App Store.
    DDLogInfo(@"Fresh install, setting user defaults version to %d", registrationDomainVersion);
    [userDefaults setValue:[NSNumber numberWithInt:registrationDomainVersion]
                    forKey:userDefaultsVersionApplicationDomainKey];
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

      // Passing the registration domain defaults as parameter is deprecated.
      // See the class documentation for details. At this point we still
      // support upgrade methods that require the parameter, but once GitHub
      // issue #405 is resolved this support should be removed from here.
      NSString* upgradeMethodName1 = [NSString stringWithFormat:@"upgradeToVersion%d:", applicationDomainVersion];
      SEL upgradeSelector1 = NSSelectorFromString(upgradeMethodName1);
      bool respondsToUpgradeSelector1 = [[UserDefaultsUpdater class] respondsToSelector:upgradeSelector1];

      NSString* upgradeMethodName2 = [NSString stringWithFormat:@"upgradeToVersion%d", applicationDomainVersion];
      SEL upgradeSelector2 = NSSelectorFromString(upgradeMethodName2);
      bool respondsToUpgradeSelector2 = [[UserDefaultsUpdater class] respondsToSelector:upgradeSelector2];

      if (respondsToUpgradeSelector1 || respondsToUpgradeSelector2)
      {
        DDLogInfo(@"UserDefaultsUpdater performs incremental upgrade to version = %d. Final target version = %d",
                  applicationDomainVersion,
                  registrationDomainVersion);

        // TODO How do we learn of success/failure of upgradeSelector, and how
        // do we react to failure?
        if (respondsToUpgradeSelector1)
          [[UserDefaultsUpdater class] performSelector:upgradeSelector1 withObject:registrationDomainDefaults];
        else
          [[UserDefaultsUpdater class] performSelector:upgradeSelector2];

        ++numberOfUpgradesPerformed;
        // Update the application domain version number
        [userDefaults setValue:[NSNumber numberWithInt:applicationDomainVersion]
                        forKey:userDefaultsVersionApplicationDomainKey];
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
  // New top-level key
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setValue:[NSNumber numberWithBool:NO] forKey:loggingEnabledKey];

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
  [dictionary setValue:[NSNumber numberWithBool:discardFutureNodesAlertDefault] forKey:discardFutureMovesAlertKey];
  [dictionary setValue:[NSNumber numberWithInt:-1] forKey:boardPositionLastViewedKey];
  [userDefaults setObject:dictionary forKey:boardPositionKey];

  // Add new keys to "PlayView" dictionary
  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    // This key is new
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithInt:ScoreInfoType] forKey:infoTypeLastSelectedKey];
    // This key now has device-specific values
    [UserDefaultsUpdater upgradeDictionary:playViewDictionaryUpgrade
                                    forKey:boardOuterMarginPercentageKey
                       upgradeDeviceSuffix:nil
                registrationDomainDefaults:[registrationDomainDefaults objectForKey:playViewKey]];
    // placeStoneUnderFingerKey is replaced by stoneDistanceFromFingertip. The
    // original boolean value is converted into a corresponding float value.
    float stoneDistanceFromFingertip;
    bool placeStoneUnderFinger = [[playViewDictionary valueForKey:[placeStoneUnderFingerKey stringByAppendingDeviceSuffix]] boolValue];
    if (placeStoneUnderFinger)
      stoneDistanceFromFingertip = 0;
    else
      stoneDistanceFromFingertip = stoneDistanceFromFingertipDefault;
    [playViewDictionaryUpgrade removeObjectForKey:[placeStoneUnderFingerKey stringByAppendingDeviceSuffix]];
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithFloat:stoneDistanceFromFingertip] forKey:[stoneDistanceFromFingertipKey stringByAppendingDeviceSuffix]];

    [userDefaults setObject:playViewDictionaryUpgrade forKey:playViewKey];
  }

  // Add new keys to / remove unused key from "NewGame" dictionary
  id newGameDictionary = [userDefaults objectForKey:newGameKey];
  if (newGameDictionary)  // is nil if the key is not present
  {
    NSString* defaultHumanPlayerUUID = @"F1017CAF-BCF5-406F-AC4C-5B4F794C006C";
    NSString* defaultComputerPlayerUUID = @"766CDA23-0C58-480B-A8B5-1F34BDA41677";
    NSMutableDictionary* newGameDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:newGameDictionary];
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:gDefaultGameType] forKey:gameTypeKey];
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:gDefaultGameType] forKey:gameTypeLastSelectedKey];
    [newGameDictionaryUpgrade setValue:defaultHumanPlayerUUID forKey:humanPlayerKey];
    [newGameDictionaryUpgrade setValue:defaultComputerPlayerUUID forKey:computerPlayerKey];
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithBool:gDefaultComputerPlaysWhite] forKey:computerPlaysWhiteKey];
    [newGameDictionaryUpgrade setValue:defaultHumanPlayerUUID forKey:humanBlackPlayerKey];
    [newGameDictionaryUpgrade setValue:defaultHumanPlayerUUID forKey:humanWhitePlayerKey];
    [newGameDictionaryUpgrade setValue:defaultComputerPlayerUUID forKey:computerPlayerSelfPlayKey];
    [newGameDictionaryUpgrade removeObjectForKey:blackPlayerKey];
    [newGameDictionaryUpgrade removeObjectForKey:whitePlayerKey];
    [userDefaults setObject:newGameDictionaryUpgrade forKey:newGameKey];
  }

  // Add new key to "Scoring" dictionary
  id scoringDictionary = [userDefaults objectForKey:scoringKey];
  if (scoringDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* scoringDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:scoringDictionary];
    [scoringDictionaryUpgrade setValue:[NSNumber numberWithBool:true] forKey:scoreWhenGameEndsKey];
    [userDefaults setObject:scoringDictionaryUpgrade forKey:scoringKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 6.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion6:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Add new keys to / change existing keys in "PlayView" dictionary
  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    // This key is new
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithFloat:maximumZoomScaleDefault] forKey:maximumZoomScaleKey];
    // Replace "DisplayMoveNumbers" key with "MoveNumbersPercentage"
    [playViewDictionaryUpgrade removeObjectForKey:displayMoveNumbersKey];
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithFloat:moveNumbersPercentageDefault] forKey:moveNumbersPercentageKey];
    // Remove unused device-specific key
    for (NSString* deviceSuffix in [UIDevice deviceSuffixes])
    {
      NSString* keyWithDeviceSuffix = [boardOuterMarginPercentageKey stringByAppendingString:deviceSuffix];
      [playViewDictionaryUpgrade removeObjectForKey:keyWithDeviceSuffix];
    }
    // These keys change their value: The value they previously had
    // (between 0 and stoneDistanceFromFingertipMaximum) must be transformed
    // into a percentage (stoneDistanceFromFingertipMaximum = 100%). Because of
    // the new semantics of the user preference, we don't attempt a linear
    // conversion.
    for (NSString* deviceSuffix in [UIDevice deviceSuffixes])
    {
      NSString* keyWithDeviceSuffix = [stoneDistanceFromFingertipKey stringByAppendingString:deviceSuffix];
      float stoneDistanceFromFingertip = [[playViewDictionaryUpgrade valueForKey:keyWithDeviceSuffix] floatValue];
      if (stoneDistanceFromFingertip > 0)
        stoneDistanceFromFingertip = 1.0f;
      [playViewDictionaryUpgrade setValue:[NSNumber numberWithFloat:stoneDistanceFromFingertip] forKey:keyWithDeviceSuffix];
    }
    [userDefaults setObject:playViewDictionaryUpgrade forKey:playViewKey];
  }

  // Remove unused key from "BoardPosition" dictionary
  id boardPositionDictionary = [userDefaults objectForKey:boardPositionKey];
  if (boardPositionDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* boardPositionDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:boardPositionDictionary];
    [boardPositionDictionaryUpgrade removeObjectForKey:boardPositionLastViewedKey];
    [userDefaults setObject:boardPositionDictionaryUpgrade forKey:boardPositionKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 7.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion7:(NSDictionary*)registrationDomainDefaults
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
      [profileDictionaryUpgrade setValue:[NSNumber numberWithBool:autoSelectFuegoResignMinGamesDefault] forKey:autoSelectFuegoResignMinGamesKey];
      unsigned long long fuegoResignMinGames;
      if (autoSelectFuegoResignMinGamesDefault)
      {
        unsigned long long fuegoMaxGames  = [[profileDictionaryUpgrade valueForKey:fuegoMaxGamesKey] unsignedLongLongValue];
        fuegoResignMinGames = [GtpEngineProfile fuegoResignMinGamesForMaxGames:fuegoMaxGames];
      }
      else
      {
        fuegoResignMinGames = fuegoResignMinGamesDefault;
      }
      [profileDictionaryUpgrade setValue:[NSNumber numberWithUnsignedLongLong:fuegoResignMinGames] forKey:fuegoResignMinGamesKey];
      NSMutableArray* fuegoResignThreshold = [NSMutableArray array];
      for (int arrayIndex = 0; arrayIndex < arraySizeFuegoResignThresholdDefault; ++arrayIndex)
      {
        NSNumber* resignThresholdDefault = [NSNumber numberWithInt:fuegoResignThresholdDefault[arrayIndex]];
        [fuegoResignThreshold addObject:resignThresholdDefault];
      }
      [profileDictionaryUpgrade setValue:fuegoResignThreshold forKey:fuegoResignThresholdKey];
      [profileListArrayUpgrade addObject:profileDictionaryUpgrade];
    }
    [userDefaults setObject:profileListArrayUpgrade forKey:gtpEngineProfileListKey];
  }

  // Add new key to "BoardPosition" dictionary
  id boardPositionDictionary = [userDefaults objectForKey:boardPositionKey];
  if (boardPositionDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* boardPositionDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:boardPositionDictionary];
    [boardPositionDictionaryUpgrade setValue:[NSNumber numberWithBool:markNextMoveDefault] forKey:markNextMoveKey];
    [userDefaults setObject:boardPositionDictionaryUpgrade forKey:boardPositionKey];
  }

  // New keys for tab bar controller appearance are top-level, so there is no
  // need to add values for them, they will be picked from the registration
  // domain defaults.
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 8.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion8:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Add new key to "PlayView" dictionary
  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    NSMutableDictionary* playViewDictionaryRegistrationDomain = [registrationDomainDefaults objectForKey:playViewKey];
    [playViewDictionaryUpgrade setValue:[NSNumber numberWithBool:displayPlayerInfluenceDefault] forKey:displayPlayerInfluenceKey];
    // Here we preserve the "maximum zoom scale" user default
    [UserDefaultsUpdater upgradeDictionary:playViewDictionaryUpgrade
                                    forKey:maximumZoomScaleKey
                       upgradeDeviceSuffix:[UIDevice currentDeviceSuffix]
                registrationDomainDefaults:playViewDictionaryRegistrationDomain];
    NSString* maximumZoomScaleKeyWithDeviceSuffix = [maximumZoomScaleKey stringByAppendingDeviceSuffix];
    float maximumZoomScaleUser = [[playViewDictionaryUpgrade valueForKey:maximumZoomScaleKeyWithDeviceSuffix] floatValue];
    float maximumZoomScaleRegistrationDomain = [[playViewDictionaryRegistrationDomain valueForKey:maximumZoomScaleKeyWithDeviceSuffix] floatValue];
    // Here we discard the user default if it is too high. It *will* be too high
    // if the user has never touched the preference.
    if (maximumZoomScaleUser > maximumZoomScaleRegistrationDomain)
      [playViewDictionaryUpgrade setValue:[NSNumber numberWithFloat:maximumZoomScaleRegistrationDomain] forKey:maximumZoomScaleKeyWithDeviceSuffix];

    [userDefaults setObject:playViewDictionaryUpgrade forKey:playViewKey];
  }

  // Add new key to "NewGame" dictionary
  id newGameDictionary = [userDefaults objectForKey:newGameKey];
  if (newGameDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* newGameDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:newGameDictionary];
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:GoKoRuleSimple] forKey:koRuleKey];
    [newGameDictionaryUpgrade setValue:[NSNumber numberWithInt:GoScoringSystemAreaScoring] forKey:scoringSystemKey];
    // We are switching the default scoring system from territory to area
    // scoring, so if the user still has the default komi for territory scoring,
    // we switch komi as well
    NSNumber* komiAsNumber = [newGameDictionaryUpgrade valueForKey:komiKey];
    double komi = [komiAsNumber doubleValue];
    if (gDefaultKomiTerritoryScoring == komi)
      [newGameDictionaryUpgrade setValue:[NSNumber numberWithDouble:gDefaultKomiAreaScoring] forKey:komiKey];
    [userDefaults setObject:newGameDictionaryUpgrade forKey:newGameKey];
  }

  // Add new key to "Scoring" dictionary
  id scoringDictionary = [userDefaults objectForKey:scoringKey];
  if (scoringDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* scoringDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:scoringDictionary];
    [scoringDictionaryUpgrade setValue:[NSNumber numberWithInt:GoScoreMarkModeDead] forKey:scoreMarkModeKey];
    id scoringDictionaryRegistrationDefaults = [registrationDomainDefaults objectForKey:scoringKey];
    NSString* blackSekiSymbolColorString = [scoringDictionaryRegistrationDefaults valueForKey:blackSekiSymbolColorKey];
    if (! blackSekiSymbolColorString)
      blackSekiSymbolColorString = @"ff0000";
    [scoringDictionaryUpgrade setValue:blackSekiSymbolColorString forKey:blackSekiSymbolColorKey];
    NSString* whiteSekiSymbolColorString = [scoringDictionaryRegistrationDefaults valueForKey:whiteSekiSymbolColorKey];
    if (! whiteSekiSymbolColorString)
      whiteSekiSymbolColorString = @"ff0000";
    [scoringDictionaryUpgrade setValue:whiteSekiSymbolColorString forKey:whiteSekiSymbolColorKey];
    [userDefaults setObject:scoringDictionaryUpgrade forKey:scoringKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 9.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion9:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Remove obsolete keys from "PlayView" dictionary, and rename "PlayView"
  // to "BoardView" dictionary
  id playViewDictionary = [userDefaults objectForKey:playViewKey];
  if (playViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* playViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:playViewDictionary];
    [playViewDictionaryUpgrade removeObjectForKey:backgroundColorKey];
    [playViewDictionaryUpgrade removeObjectForKey:boardColorKey];
    [playViewDictionaryUpgrade removeObjectForKey:lineColorKey];
    [UserDefaultsUpdater removeDeviceSpecificKeysForDeviceAgnosticKey:boundingLineWidthKey fromDictionary:playViewDictionaryUpgrade];
    [playViewDictionaryUpgrade removeObjectForKey:normalLineWidthKey];
    [playViewDictionaryUpgrade removeObjectForKey:starPointColorKey];
    [UserDefaultsUpdater removeDeviceSpecificKeysForDeviceAgnosticKey:starPointRadiusKey fromDictionary:playViewDictionaryUpgrade];
    [playViewDictionaryUpgrade removeObjectForKey:stoneRadiusPercentageKey];
    [playViewDictionaryUpgrade removeObjectForKey:crossHairColorKey];
    [UserDefaultsUpdater removeDeviceSpecificKeysForDeviceAgnosticKey:maximumZoomScaleKey fromDictionary:playViewDictionaryUpgrade];
    [userDefaults setObject:playViewDictionaryUpgrade forKey:boardViewKey];
  }

  // Remove obsolete keys from "Scoring" dictionary
  id scoringDictionary = [userDefaults objectForKey:scoringKey];
  if (scoringDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* scoringDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:scoringDictionary];
    [scoringDictionaryUpgrade removeObjectForKey:alphaTerritoryColorBlackKey];
    [scoringDictionaryUpgrade removeObjectForKey:alphaTerritoryColorWhiteKey];
    [scoringDictionaryUpgrade removeObjectForKey:deadStoneSymbolColorKey];
    [scoringDictionaryUpgrade removeObjectForKey:deadStoneSymbolPercentageKey];
    [scoringDictionaryUpgrade removeObjectForKey:inconsistentTerritoryDotSymbolColorKey];
    [scoringDictionaryUpgrade removeObjectForKey:inconsistentTerritoryDotSymbolPercentageKey];
    [scoringDictionaryUpgrade removeObjectForKey:inconsistentTerritoryFillColorKey];
    [scoringDictionaryUpgrade removeObjectForKey:inconsistentTerritoryFillColorAlphaKey];
    [scoringDictionaryUpgrade removeObjectForKey:blackSekiSymbolColorKey];
    [scoringDictionaryUpgrade removeObjectForKey:whiteSekiSymbolColorKey];
    [userDefaults setObject:scoringDictionaryUpgrade forKey:scoringKey];
  }

  id profileListArray = [userDefaults objectForKey:gtpEngineProfileListKey];
  if (profileListArray)  // is nil if the key is not present
  {
    NSMutableArray* profileListArrayUpgrade = [NSMutableArray array];
    for (NSDictionary* profileDictionary in profileListArray)
    {
      NSMutableDictionary* profileDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:profileDictionary];
      NSString* uuid = [profileDictionaryUpgrade valueForKey:gtpEngineProfileUUIDKey];
      if ([uuid isEqualToString:@"1051CE0D-D8BA-405C-A93D-7AA140683D11"])
      {
        NSString* name = [profileDictionaryUpgrade valueForKey:gtpEngineProfileNameKey];
        // If the profile name is the same as the one we deployed, we assume
        // that the user did not change any values and that we can update name
        // and description
        if ([name isEqualToString:@"iPhone 4S"])
        {
          [profileDictionaryUpgrade setValue:@"Strong" forKey:gtpEngineProfileNameKey];
          [profileDictionaryUpgrade setValue:@"This profile uses maximum playing strength, doubles the memory used by the default profile, and makes use of a second processor core." forKey:gtpEngineProfileDescriptionKey];
        }
      }
      [profileListArrayUpgrade addObject:profileDictionaryUpgrade];
    }
    [userDefaults setObject:profileListArrayUpgrade forKey:gtpEngineProfileListKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 10.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion10:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Just remove the value, we don't bother converting to the new key
  // "VisibleUIArea"
  [userDefaults removeObjectForKey:selectedTabIndexKey];

  // Remove obsolete keys from "BoardView" dictionary
  id boardViewDictionary = [userDefaults objectForKey:boardViewKey];
  if (boardViewDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* boardViewDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:boardViewDictionary];
    [UserDefaultsUpdater removeDeviceSpecificKeysForDeviceAgnosticKey:stoneDistanceFromFingertipKey fromDictionary:boardViewDictionaryUpgrade];
    [userDefaults setObject:boardViewDictionaryUpgrade forKey:boardViewKey];
  }

  // Rename key in "Scoring" dictionary
  id scoringDictionary = [userDefaults objectForKey:scoringKey];
  if (scoringDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* scoringDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:scoringDictionary];
    bool scoreWhenGameEnds = [[scoringDictionaryUpgrade valueForKey:scoreWhenGameEndsKey] boolValue];
    [scoringDictionaryUpgrade removeObjectForKey:scoreWhenGameEndsKey];
    [scoringDictionaryUpgrade setValue:[NSNumber numberWithBool:scoreWhenGameEnds] forKey:autoScoringAndResumingPlayKey];
    [userDefaults setObject:scoringDictionaryUpgrade forKey:scoringKey];
  }

  // The intent of the following upgrade block is to change the human vs. human
  // games GTP engine profile so that it no longer enables pondering. The
  // upgrade does this by copying the human vs. human games profile from the
  // registration domain into the application domain. The upgrade also copies
  // other profiles and players from the registration domain into the
  // application domain to provide a useful set of profiles and players to those
  // users who are not interested in fiddling with the technical details of
  // profile & player settings. It is expected that this is the majority of the
  // user base.
  //
  // At the same time, the upgrade must make sure that customizations made by
  // technically interested users are preserved. For this reason, a backup copy
  // is made of those profiles and players that the upgrade process is going to
  // overwrite.

  // First pass: Update profiles. Also remember which profiles had to be
  // renamed (i.e. the backup) - this information is required by the second
  // pass.
  NSMutableDictionary* renamedProfiles;
  bool renamedAtLeastOneProfile = [UserDefaultsUpdater addToUserDefaults:userDefaults
                                                  fromRegistrationDomain:registrationDomainDefaults
                                                             addProfiles:true
                                                         renamedProfiles:&renamedProfiles];  // renamedProfiles = out parameter
  // Second pass: Update players (includes fixing references to renamed
  // profiles)
  bool renamedAtLeastOnePlayer = [UserDefaultsUpdater addToUserDefaults:userDefaults
                                                 fromRegistrationDomain:registrationDomainDefaults
                                                            addProfiles:false
                                                        renamedProfiles:&renamedProfiles];  // renamedProfiles = in parameter

  // Inform the user
  if (renamedAtLeastOneProfile || renamedAtLeastOnePlayer)
  {
    NSString* alertTitle = @"Updated Settings";
    NSString* alertMessage = (@"Your settings had to be updated for this version of the app.\n\n"
                              "Please review the changes that were made in the 'Players & Profiles' section.\n\n"
                              "You will find that a backup has been created for some players and/or profiles. "
                              "This is to preserve any customizations you may have made. If you don't need these "
                              "backups you can simply delete them.");

    [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle message:alertMessage];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 11.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion11:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  // Add two new GTP commands to "GtpCannedCommands" array
  id cannedCommandsArray = [userDefaults objectForKey:gtpCannedCommandsKey];
  if (cannedCommandsArray)  // is nil if the key is not present
  {
    NSMutableArray* cannedCommandsArrayUpgrade = [NSMutableArray arrayWithArray:cannedCommandsArray];
    [cannedCommandsArrayUpgrade addObject:@"list_setup"];
    [cannedCommandsArrayUpgrade addObject:@"list_setup_player"];
    [userDefaults setObject:cannedCommandsArrayUpgrade forKey:gtpCannedCommandsKey];
  }
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 12.
///
/// Migration goals:
/// - Human players remain as they currently are, i.e. no need to migrate.
/// - Every computer player has its own dedicated GTP engine profile. No two
///   computer players share the same profile.
/// - Every GTP engine profile except the human vs. human profile is referenced
///   by exactly one computer player.
/// - The human vs. human GTP engine profile is not referenced by any computer
///   player.
///
/// Migration cases:
/// - Case 1: Profile is the human vs. human profile and it is referenced by
///   1-n players. Action: For each reference create a new profile that is a
///   duplicate of the human vs. human profile, then replace the player's
///   reference to the human vs. human profile with a reference to the new
///   profile.
/// - Case 2: Profile is not the human vs. human profile and it is referenced
///   by 2-n players. Action: For each reference beyond the first create a new
///   profile that is a duplicate of the original profile, then replace the
///   player's reference to the original profile with a reference to the new
///   profile.
/// - Case 3: Profile is not the human vs. human profile and it is not
///   referenced by a player. Action: Create a new player that references the
///   profile.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion12:(NSDictionary*)registrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  NSArray* userDefaultsPlayers = [userDefaults objectForKey:playerListKey];
  if (! userDefaultsPlayers)
    userDefaultsPlayers = [NSArray array];  // should not be possible
  NSMutableArray* players = [NSMutableArray array];
  for (NSDictionary* playerDictionary in userDefaultsPlayers)
  {
    Player* player = [[[Player alloc] initWithDictionary:playerDictionary] autorelease];
    [players addObject:player];
  }

  NSArray* userDefaultsProfiles = [userDefaults objectForKey:gtpEngineProfileListKey];
  if (! userDefaultsProfiles)
    userDefaultsProfiles = [NSArray array];  // should not be possible
  NSMutableArray* profiles = [NSMutableArray array];
  for (NSDictionary* profileDictionary in userDefaultsProfiles)
  {
    GtpEngineProfile* profile = [[[GtpEngineProfile alloc] initWithDictionary:profileDictionary] autorelease];
    [profiles addObject:profile];
  }

  NSString* humanVsHumanProfileName = @"Human vs. human games";

  // Use an index-based iteration and check the array count in each iteration
  // because elements can be added to the array during iteration
  for (NSUInteger indexOfProfile = 0; indexOfProfile < profiles.count; indexOfProfile++)
  {
    GtpEngineProfile* profile = [profiles objectAtIndex:indexOfProfile];
    bool isHumanVsHumanProfile = [profile.uuid isEqualToString:fallbackGtpEngineProfileUUID];

    int numberOfPlayersReferencingProfile = 0;

    for (Player* player in players)
    {
      if (player.isHuman)
        continue;

      if (! [profile.uuid isEqualToString:player.gtpEngineProfileUUID])
        continue;

      numberOfPlayersReferencingProfile++;

      // Migration cases 1 and 2
      if (isHumanVsHumanProfile || numberOfPlayersReferencingProfile > 1)
      {
        NSMutableDictionary* duplicateProfileDictionary = [NSMutableDictionary dictionaryWithDictionary:[profile asDictionary]];
        NSString* duplicateProfileUUID = [NSString UUIDString];
        [duplicateProfileDictionary setValue:duplicateProfileUUID forKey:gtpEngineProfileUUIDKey];

        GtpEngineProfile* duplicateProfile = [[[GtpEngineProfile alloc] initWithDictionary:duplicateProfileDictionary] autorelease];
        [profiles addObject:duplicateProfile];

        duplicateProfile.name = @"";
        if (isHumanVsHumanProfile)
          duplicateProfile.profileDescription = [NSString stringWithFormat:@"Settings copied from profile '%@'", humanVsHumanProfileName];

        player.gtpEngineProfileUUID = duplicateProfile.uuid;
      }
    }

    if (isHumanVsHumanProfile)
    {
      // In case the user changed this special profile's name and/or description
      // we give it back its default name and description. We use the same name
      // and description as in RegistrationDomainDefaults.plist. Note: From now
      // on the user will no longer be able to change this profile's name and
      // description.
      profile.name = humanVsHumanProfileName;
      profile.profileDescription = @"The computer uses these settings to make calculations in games where both players are human. By default these settings disable the 'Pondering' feature so as not to consume too much battery power.";
    }
    else
    {
      // Migration case 3
      if (numberOfPlayersReferencingProfile == 0)
      {
        Player* player = [[[Player alloc] initWithDictionary:nil] autorelease];
        [players addObject:player];

        // The profiles in RegistrationDomainDefaults.plist up until now were
        // named "Weak", "Strong", "Extra strong" and players were named
        // "Fuego (Weak)", "Fuego (Strong)" and "Fuego (Extra strong)". If
        // the user merely deleted a player but kept the profile name, then
        // this naming scheme will restore the original player.
        player.name = [NSString stringWithFormat:@"Fuego (%@)", profile.name];
        player.human = false;
        player.gtpEngineProfileUUID = profile.uuid;
      }

      // We no longer have a use for the profile name.
      profile.name = @"";
    }
  }

  NSMutableArray* userDefaultsPlayersUpgrade = [NSMutableArray array];
  for (Player* player in players)
    [userDefaultsPlayersUpgrade addObject:[player asDictionary]];
  [userDefaults setObject:userDefaultsPlayersUpgrade forKey:playerListKey];

  NSMutableArray* userDefaultsProfilesUpgrade = [NSMutableArray array];
  for (GtpEngineProfile* profile in profiles)
    [userDefaultsProfilesUpgrade addObject:[profile asDictionary]];
  [userDefaults setObject:userDefaultsProfilesUpgrade forKey:gtpEngineProfileListKey];
}

// -----------------------------------------------------------------------------
/// @brief Performs the incremental upgrade to the user defaults format
/// version 13.
// -----------------------------------------------------------------------------
+ (void) upgradeToVersion13
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

  // Rename key in "BoardPosition" dictionary
  id boardPositionDictionary = [userDefaults objectForKey:boardPositionKey];
  if (boardPositionDictionary)  // is nil if the key is not present
  {
    NSMutableDictionary* boardPositionDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:boardPositionDictionary];
    bool discardFutureMovesAlert = [[boardPositionDictionaryUpgrade valueForKey:discardFutureMovesAlertKey] boolValue];
    [boardPositionDictionaryUpgrade removeObjectForKey:discardFutureMovesAlertKey];
    [boardPositionDictionaryUpgrade setValue:[NSNumber numberWithBool:discardFutureMovesAlert] forKey:discardFutureNodesAlertKey];
    [userDefaults setObject:boardPositionDictionaryUpgrade forKey:boardPositionKey];
  }

  // Move some top-level keys to new "UiSettings" dictionary
  // Also add a key for a new user preference
  NSMutableDictionary* uiSettingsDictionaryUpgrade = [NSMutableDictionary dictionary];
  [uiSettingsDictionaryUpgrade setValue:[userDefaults valueForKey:visibleUIAreaKey] forKey:visibleUIAreaKey];
  [uiSettingsDictionaryUpgrade setValue:[userDefaults valueForKey:tabOrderKey] forKey:tabOrderKey];
  [uiSettingsDictionaryUpgrade setValue:[userDefaults valueForKey:uiAreaPlayModeKey] forKey:uiAreaPlayModeKey];
  [uiSettingsDictionaryUpgrade setValue:[userDefaults valueForKey:visibleAnnotationViewPageKey] forKey:visibleAnnotationViewPageKey];
  // Add key for new user preference
  [uiSettingsDictionaryUpgrade setValue:@[@0.7, @0.3] forKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsPortraitSuffix]];
  [uiSettingsDictionaryUpgrade setValue:@[@0.7, @0.3] forKey:[resizableStackViewControllerInitialSizesUiAreaPlayKey stringByAppendingString:uiSettingsLandscapeSuffix]];
  [userDefaults setObject:uiSettingsDictionaryUpgrade forKey:uiSettingsKey];
  [userDefaults removeObjectForKey:visibleUIAreaKey];
  [userDefaults removeObjectForKey:tabOrderKey];
  [userDefaults removeObjectForKey:uiAreaPlayModeKey];
  [userDefaults removeObjectForKey:visibleAnnotationViewPageKey];

  // Move some top-level keys to new "MagnifyingGlass" dictionary
  NSMutableDictionary* magnifyingGlassDictionaryUpgrade = [NSMutableDictionary dictionary];
  [magnifyingGlassDictionaryUpgrade setValue:[userDefaults valueForKey:magnifyingGlassEnableModeKey] forKey:magnifyingGlassEnableModeKey];
  [magnifyingGlassDictionaryUpgrade setValue:[userDefaults valueForKey:magnifyingGlassAutoThresholdKey] forKey:magnifyingGlassAutoThresholdKey];
  [magnifyingGlassDictionaryUpgrade setValue:[userDefaults valueForKey:magnifyingGlassVeerDirectionKey] forKey:magnifyingGlassVeerDirectionKey];
  [magnifyingGlassDictionaryUpgrade setValue:[userDefaults valueForKey:magnifyingGlassDistanceFromMagnificationCenterKey] forKey:magnifyingGlassDistanceFromMagnificationCenterKey];
  [userDefaults setObject:magnifyingGlassDictionaryUpgrade forKey:magnifyingGlassKey];
  [userDefaults removeObjectForKey:magnifyingGlassEnableModeKey];
  [userDefaults removeObjectForKey:magnifyingGlassAutoThresholdKey];
  [userDefaults removeObjectForKey:magnifyingGlassVeerDirectionKey];
  [userDefaults removeObjectForKey:magnifyingGlassDistanceFromMagnificationCenterKey];

  // Move some top-level keys to new "GameSetup" dictionary
  NSMutableDictionary* gameSetupDictionaryUpgrade = [NSMutableDictionary dictionary];
  [gameSetupDictionaryUpgrade setValue:[userDefaults valueForKey:boardSetupStoneColorKey] forKey:boardSetupStoneColorKey];
  [gameSetupDictionaryUpgrade setValue:[userDefaults valueForKey:doubleTapToZoomKey] forKey:doubleTapToZoomKey];
  [gameSetupDictionaryUpgrade setValue:[userDefaults valueForKey:autoEnableBoardSetupModeKey] forKey:autoEnableBoardSetupModeKey];
  [gameSetupDictionaryUpgrade setValue:[userDefaults valueForKey:changeHandicapAlertKey] forKey:changeHandicapAlertKey];
  [gameSetupDictionaryUpgrade setValue:[userDefaults valueForKey:tryNotToPlaceIllegalStonesKey] forKey:tryNotToPlaceIllegalStonesKey];
  [userDefaults setObject:gameSetupDictionaryUpgrade forKey:gameSetupKey];
  [userDefaults removeObjectForKey:boardSetupStoneColorKey];
  [userDefaults removeObjectForKey:doubleTapToZoomKey];
  [userDefaults removeObjectForKey:autoEnableBoardSetupModeKey];
  [userDefaults removeObjectForKey:changeHandicapAlertKey];
  [userDefaults removeObjectForKey:tryNotToPlaceIllegalStonesKey];

  // Move some top-level keys to new "CrashReporting" dictionary
  // Also rename some of the keys (remove unnecessary "Key" suffix)
  NSMutableDictionary* crashReportingDictionaryUpgrade = [NSMutableDictionary dictionary];
  [crashReportingDictionaryUpgrade setValue:[userDefaults valueForKey:collectCrashDataKey] forKey:collectCrashDataKey];
  [crashReportingDictionaryUpgrade setValue:[userDefaults valueForKey:automaticReportCrashDataKey] forKey:automaticReportCrashDataKey];
  [crashReportingDictionaryUpgrade setValue:[userDefaults valueForKey:crashDataContactAllowKey] forKey:allowContactCrashDataKey];
  [crashReportingDictionaryUpgrade setValue:[userDefaults valueForKey:crashDataContactEmailKey] forKey:contactEmailCrashDataKey];
  [userDefaults setObject:crashReportingDictionaryUpgrade forKey:crashReportingKey];
  [userDefaults removeObjectForKey:collectCrashDataKey];
  [userDefaults removeObjectForKey:automaticReportCrashDataKey];
  [userDefaults removeObjectForKey:crashDataContactAllowKey];
  [userDefaults removeObjectForKey:crashDataContactEmailKey];

  // Move some top-level keys to new "Logging" dictionary
  NSMutableDictionary* loggingDictionaryUpgrade = [NSMutableDictionary dictionary];
  [loggingDictionaryUpgrade setValue:[userDefaults valueForKey:loggingEnabledKey] forKey:loggingEnabledKey];
  [userDefaults setObject:loggingDictionaryUpgrade forKey:loggingKey];
  [userDefaults removeObjectForKey:loggingEnabledKey];

  // For user defaults format 13, the registration domain defaults also move the
  // key additiveKnowledgeMemoryThresholdKey to a new "GtpEngineConfiguration"
  // dictionary. Because the value for this key was never exposed in the UI as
  // a configurable user preference it cannot appear in the user defaults, and
  // therefore no migration needs to be done for this.
}

// -----------------------------------------------------------------------------
/// @brief If @a addProfiles is true this method adds a copy of all profiles
/// existing in @a registrationDomainDefaults to @a userDefaults. If
/// @a addProfiles is false, the same is done for players.
///
/// Players and profiles already in @a userDefaults remain. If a player or
/// profile in @a userDefaults has the same UUID as one of the players or
/// profiles copied from @a registrationDomainDefaults, it is given a new UUID
/// and renamed with the suffix " (backup)".
///
/// When profiles are processed, @a renamedProfiles is treated as an out
/// parameter and initialized with a newly allocated dictionary object. The
/// dictionary is populated with entries, one for each profile for which a
/// backup is created. The key of the entry is the old UUID, the value of the
/// entry is the new UUID.
///
/// When players are processed, @a renamedProfiles is treated as an in
/// parameter. If a player is found which refers to one of the old profile UUIDs
/// in the dictionary, the reference is changed to the profile's new UUID.
// -----------------------------------------------------------------------------
+ (bool) addToUserDefaults:(NSUserDefaults*)userDefaults
    fromRegistrationDomain:(NSDictionary*)registrationDomainDefaults
               addProfiles:(bool)addProfiles
           renamedProfiles:(NSMutableDictionary**)renamedProfiles
{
  NSMutableDictionary* localRenamedProfiles;
  NSString* mainArrayKey;
  NSString* uuidKey;
  NSString* nameKey;
  if (addProfiles)
  {
    localRenamedProfiles = [NSMutableDictionary dictionary];
    *renamedProfiles = localRenamedProfiles;
    mainArrayKey = gtpEngineProfileListKey;
    uuidKey = gtpEngineProfileUUIDKey;
    nameKey = gtpEngineProfileNameKey;
  }
  else
  {
    localRenamedProfiles = *renamedProfiles;
    mainArrayKey = playerListKey;
    uuidKey = playerUUIDKey;
    nameKey = playerNameKey;
  }

  bool renamedAtLeastOneEntry = false;
  id applicationDomainArray = [userDefaults objectForKey:mainArrayKey];
  if (! applicationDomainArray)
    return renamedAtLeastOneEntry;

  // At the end of processing this array will contain the list of dictionaries
  // that we want to write
  NSMutableArray* applicationDomainArrayUpgrade = [NSMutableArray array];

  // Step 1: Prepare a lookup table. As a side-effect we transform all immutable
  // dictionaries into mutable dictionaries.
  // For players only: We also fix references to renamed profiles.
  NSMutableDictionary* applicationDomainLookupTable = [NSMutableDictionary dictionary];
  for (NSDictionary* applicationDomainDictionary in applicationDomainArray)
  {
    NSMutableDictionary* applicationDomainDictionaryUpgrade = [NSMutableDictionary dictionaryWithDictionary:applicationDomainDictionary];
    NSString* uuid = applicationDomainDictionaryUpgrade[uuidKey];
    applicationDomainLookupTable[uuid] = applicationDomainDictionaryUpgrade;
    if (! addProfiles)
    {
      NSString* profileUUID = applicationDomainDictionaryUpgrade[gtpEngineProfileReferenceKey];
      NSString* renamedProfileUUID = localRenamedProfiles[profileUUID];
      // renamedProfileUUID is nil if the profile wasn't renamed - which means
      // we don't need to fix the reference
      if (renamedProfileUUID)
        applicationDomainDictionaryUpgrade[gtpEngineProfileReferenceKey] = renamedProfileUUID;
    }
  }

  // Step 2: Process entries in registration domain
  NSMutableArray* backupEntriesArray = [NSMutableArray array];
  id registrationDomainArray = [registrationDomainDefaults objectForKey:mainArrayKey];
  for (NSDictionary* registrationDomainDictionary in registrationDomainArray)
  {
    NSString* uuid = registrationDomainDictionary[uuidKey];
    NSMutableDictionary* applicationDomainDictionary = applicationDomainLookupTable[uuid];
    if (! applicationDomainDictionary)
    {
      [applicationDomainArrayUpgrade addObject:registrationDomainDictionary];
      continue;
    }

    // When step 2 has finished processing we only want entries in the lookup
    // table that exist in the application domain, but NOT in the registration
    // domain. This is important for step 3.
    [applicationDomainLookupTable removeObjectForKey:uuid];

    // Keep the registration domain entry in all cases
    [applicationDomainArrayUpgrade addObject:registrationDomainDictionary];

    // Make a backup copy of the application domain entry if it is different
    // from the registration domain entry in any way
    if (![registrationDomainDictionary isEqualToDictionary:applicationDomainDictionary])
    {
      NSString* newUUID = [NSString UUIDString];
      applicationDomainDictionary[uuidKey] = newUUID;
      NSString* name = applicationDomainDictionary[nameKey];
      NSString* newName = [name stringByAppendingString:@" (backup)"];
      applicationDomainDictionary[nameKey] = newName;
      [backupEntriesArray addObject:applicationDomainDictionary];

      // Remember the old/new UUID pair so that when we later process players
      // we can fix their references to the renamed profile
      if (addProfiles)
        localRenamedProfiles[uuid] = newUUID;

      renamedAtLeastOneEntry = true;
    }
  }

  // Step 3: Keep entries that exist in the application domain, but NOT in the
  // registration domain. Those are the entries that the user has newly created
  // on his device.
  [applicationDomainArrayUpgrade addObjectsFromArray:[applicationDomainLookupTable allValues]];

  // Step 4: Keep backup copies, but place them at the end of the list
  [applicationDomainArrayUpgrade addObjectsFromArray:backupEntriesArray];

  // Step 5: Write changed values back to user defaults
  [userDefaults setObject:applicationDomainArrayUpgrade forKey:mainArrayKey];
  return renamedAtLeastOneEntry;
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

// -----------------------------------------------------------------------------
/// @brief Upgrades @a dictionary so that after the upgrade it no longer
/// contains device-specific keys that match the device-agnostic @a key.
// -----------------------------------------------------------------------------
+ (void) removeDeviceSpecificKeysForDeviceAgnosticKey:(NSString*)key fromDictionary:(NSMutableDictionary*)dictionary
{
  for (NSString* deviceSuffix in [UIDevice deviceSuffixes])
  {
    NSString* keyWithDeviceSuffix = [key stringByAppendingString:deviceSuffix];
    [dictionary removeObjectForKey:keyWithDeviceSuffix];
  }
}

@end
