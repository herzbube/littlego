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


// Project includes
#import "GtpEngineProfileModel.h"
#import "GtpEngineProfile.h"


@implementation GtpEngineProfileModel

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngineProfileModel object with user defaults data.
///
/// @note This is the designated initializer of GtpEngineProfileModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.profileCount = 0;
  self.profileList = [NSMutableArray arrayWithCapacity:self.profileCount];
  self.activeProfile = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpEngineProfileModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.profileList = nil;
  self.activeProfile = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  // Remove the reference before the object being referenced is deallocated
  self.activeProfile = nil;

  NSMutableArray* localProfileList = [NSMutableArray array];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSArray* userDefaultsProfileList = [userDefaults arrayForKey:gtpEngineProfileListKey];
  for (NSDictionary* profileDictionary in userDefaultsProfileList)
  {
    GtpEngineProfile* profile = [[GtpEngineProfile alloc] initWithDictionary:profileDictionary];
    // We want the array to retain and release the object for us -> decrease
    // the retain count by 1 (was set to 1 by alloc/init)
    [profile autorelease];
    [localProfileList addObject:profile];
  }
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // profiles.
  self.profileCount = (int)[localProfileList count];
  // Completely replace the previous profile list to trigger the
  // key-value-observing mechanism.
  self.profileList = localProfileList;
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableArray* userDefaultsProfileList = [NSMutableArray array];
  for (GtpEngineProfile* profile in self.profileList)
    [userDefaultsProfileList addObject:[profile asDictionary]];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:userDefaultsProfileList forKey:gtpEngineProfileListKey];
}

// -----------------------------------------------------------------------------
/// @brief Discards the current user defaults and re-initializes this model with
/// registration domain defaults data.
// -----------------------------------------------------------------------------
- (void) resetToRegistrationDomainDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults removeObjectForKey:gtpEngineProfileListKey];
  [self readUserDefaults];
}

// -----------------------------------------------------------------------------
/// @brief Returns the name of the profile at position @a index in the list of
/// profiless. This is a convenience method.
// -----------------------------------------------------------------------------
- (NSString*) profileNameAtIndex:(int)index
{
  assert(index >= 0 && index < [self.profileList count]);
  GtpEngineProfile* profile = (GtpEngineProfile*)[self.profileList objectAtIndex:index];
  return profile.name;
}

// -----------------------------------------------------------------------------
/// @brief Adds object @a profile to this model.
// -----------------------------------------------------------------------------
- (void) add:(GtpEngineProfile*)profile
{
  NSMutableArray* localProfileList = (NSMutableArray*)self.profileList;
  [localProfileList addObject:profile];
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // profiles.
  self.profileCount = (int)[localProfileList count];
}

// -----------------------------------------------------------------------------
/// @brief Removes object @a profile from this model.
// -----------------------------------------------------------------------------
- (void) remove:(GtpEngineProfile*)profile
{
  NSMutableArray* localProfileList = (NSMutableArray*)self.profileList;
  [localProfileList removeObject:profile];
  // Cast is required because NSUInteger and int differ in size in 64-bit. Cast
  // is safe because this app was not made to handle more than pow(2, 31)
  // profiles.
  self.profileCount = (int)[localProfileList count];
}

// -----------------------------------------------------------------------------
/// @brief Returns the profile object identified by @a uuid. Returns nil if no
/// such object exists.
// -----------------------------------------------------------------------------
- (GtpEngineProfile*) profileWithUUID:(NSString*)uuid
{
  for (GtpEngineProfile* profile in self.profileList)
  {
    if ([profile.uuid isEqualToString:uuid])
      return profile;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns the fallback profile object. See the class documentation of
/// GtpEngineProfile for details.
// -----------------------------------------------------------------------------
- (GtpEngineProfile*) fallbackProfile
{
  for (GtpEngineProfile* profile in self.profileList)
  {
    if ([profile isFallbackProfile])
      return profile;
  }
  return nil;
}

@end
