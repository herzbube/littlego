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
#import "GtpEngineProfile.h"
#import "../utility/NSStringAdditions.h"
#import "../gtp/GtpCommand.h"


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
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* uuid;
//@}
@end


@implementation GtpEngineProfile

@synthesize uuid;
@synthesize name;
@synthesize profileDescription;
@synthesize fuegoMaxMemory;
@synthesize fuegoThreadCount;
@synthesize fuegoPondering;
@synthesize fuegoReuseSubtree;


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
    self.fuegoMaxMemory = fuegoMaxMemoryDefault;
    self.fuegoThreadCount = fuegoThreadCountDefault;
    self.fuegoPondering = fuegoPonderingDefault;
    self.fuegoReuseSubtree = fuegoReuseSubtreeDefault;
  }
  else
  {
    self.uuid = (NSString*)[dictionary valueForKey:gtpEngineProfileUUIDKey];
    self.name = (NSString*)[dictionary valueForKey:gtpEngineProfileNameKey];
    self.profileDescription = (NSString*)[dictionary valueForKey:gtpEngineProfileDescriptionKey];
    self.fuegoMaxMemory = [[dictionary valueForKey:fuegoMaxMemoryKey] intValue];
    self.fuegoThreadCount = [[dictionary valueForKey:fuegoThreadCountKey] intValue];
    self.fuegoPondering = [[dictionary valueForKey:fuegoPonderingKey] boolValue];
    self.fuegoReuseSubtree = [[dictionary valueForKey:fuegoReuseSubtreeKey] boolValue];
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
  return [NSString stringWithFormat:@"GtpEngineProfile(%p): name = %@, uuid = %@", self, name, uuid];
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
  [dictionary setValue:[NSNumber numberWithBool:self.fuegoReuseSubtree] forKey:fuegoReuseSubtreeKey];
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
  commandString = [NSString stringWithFormat:@"uct_max_memory %d", fuegoMaxMemoryInBytes];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_search number_threads %d", self.fuegoThreadCount];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_player ponder %d", (self.fuegoPondering ? 1 : 0)];
  command = [GtpCommand command:commandString];
  [command submit];
  commandString = [NSString stringWithFormat:@"uct_param_player reuse_subtree %d", (self.fuegoReuseSubtree ? 1 : 0)];
  command = [GtpCommand command:commandString];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if this GtpEngineProfile object is the default profile.
// -----------------------------------------------------------------------------
- (bool) isDefaultProfile
{
  return [uuid isEqualToString:defaultGtpEngineProfileUUID];
}

@end
