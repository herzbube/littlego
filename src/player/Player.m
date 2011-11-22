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
#import "Player.h"
#import "PlayerStatistics.h"
#import "GtpEngineProfile.h"
#import "GtpEngineProfileModel.h"
#import "../utility/NSStringAdditions.h"
#import "../ApplicationDelegate.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for Player.
// -----------------------------------------------------------------------------
@interface Player()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(readwrite, retain) NSString* uuid;
//@}
@end


@implementation Player

@synthesize uuid;
@synthesize name;
@synthesize human;
@synthesize gtpEngineProfileUUID;
@synthesize statistics;
@synthesize playing;


// -----------------------------------------------------------------------------
/// @brief Initializes a Player object with user defaults data.
// -----------------------------------------------------------------------------
- (id) init
{
  // Invoke designated initializer
  return [self initWithDictionary:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a Player object with user defaults data stored inside
/// @a dictionary.
///
/// If @a dictionary is @e nil, the Player object is human, has no name, and is
/// associated with a PlayerStatistics object that has all attributes set to
/// zero/undefined values. The UUID is randomly generated.
///
/// Invoke the asDictionary() method to convert a Player object's user defaults
/// attributes back into an NSDictionary suitable for storage in the user
/// defaults system.
///
/// @note This is the designated initializer of Player.
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
    self.human = true;
    self.gtpEngineProfileUUID = @"";
    self.statistics = [[PlayerStatistics alloc] init];
    [self.statistics release];
  }
  else
  {
    self.uuid = (NSString*)[dictionary valueForKey:playerUUIDKey];
    self.name = (NSString*)[dictionary valueForKey:playerNameKey];
    // The value returned from the NSDictionary has the type NSCFBoolean. It
    // appears that this can be treated as an NSNumber object, from which we
    // can get the value by sending the message "boolValue".
    self.human = [[dictionary valueForKey:isHumanKey] boolValue];
    if (self.human)
      self.gtpEngineProfileUUID = @"";
    else
      self.gtpEngineProfileUUID = (NSString*)[dictionary valueForKey:gtpEngineProfileReferenceKey];
    NSDictionary* statisticsDictionary = (NSDictionary*)[dictionary valueForKey:statisticsKey];
    self.statistics = [[PlayerStatistics alloc] initWithDictionary:statisticsDictionary];
  }
  assert([self.uuid length] > 0);

  self.playing = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this Player object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.uuid = nil;
  self.name = nil;
  self.gtpEngineProfileUUID = nil;
  self.statistics = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns this Player object's user defaults attributes as a dictionary
/// suitable for storage in the user defaults system.
// -----------------------------------------------------------------------------
- (NSDictionary*) asDictionary
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  // setValue:forKey:() allows for nil values, so we use that instead of
  // setObject:forKey:() which is less forgiving and would force us to check
  // for nil values.
  // Note: Use NSNumber to represent int and bool values as an object.
  [dictionary setValue:self.uuid forKey:playerUUIDKey];
  [dictionary setValue:self.name forKey:playerNameKey];
  [dictionary setValue:[NSNumber numberWithBool:self.isHuman] forKey:isHumanKey];
  if (! self.isHuman)
    [dictionary setValue:self.gtpEngineProfileUUID forKey:gtpEngineProfileReferenceKey];
  [dictionary setValue:[self.statistics asDictionary] forKey:statisticsKey];
  return dictionary;
}

// -----------------------------------------------------------------------------
/// @brief Returns the GtpEngineProfile object that this Player references via
/// the @e gtpEngineProfileUUID property.
///
/// Returns nil if this Player is not a computer player (i.e. isHuman() returns
/// true).
///
/// This is a convenience method so that clients do not need to know
/// GtpEngineProfileModel, or how to obtain an instance of
/// GtpEngineProfileModel.
// -----------------------------------------------------------------------------
- (GtpEngineProfile*) gtpEngineProfile
{
  if (self.isHuman)
    return nil;
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  return [model profileWithUUID:self.gtpEngineProfileUUID];
}

@end
