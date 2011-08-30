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
#import "GtpEngineSettings.h"
#import "../gtp/GtpCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for GtpEngineSettings.
// -----------------------------------------------------------------------------
@interface GtpEngineSettings()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation GtpEngineSettings

@synthesize fuegoMaxMemory;
@synthesize fuegoThreadCount;
@synthesize fuegoPondering;
@synthesize fuegoReuseSubtree;


// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngineSettings object with its attributes set to
/// sensible default values.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  // Invoke designated initializer
  return [self initWithDictionary:nil];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a GtpEngineSettings object with user defaults data stored
/// inside @a dictionary.
///
/// If @a dictionary is @e nil, the GtpEngineSettings object has its attributes
/// set to sensible default values.
///
/// Invoke the asDictionary() method to convert a GtpEngineSettings object's
/// user defaults attributes back into an NSDictionary suitable for storage in
/// the user defaults system.
///
/// @note This is the designated initializer of GtpEngineSettings.
// -----------------------------------------------------------------------------
- (id) initWithDictionary:(NSDictionary*)dictionary
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  else if (! dictionary)
  {
    self.fuegoMaxMemory = fuegoMaxMemoryDefault;
    self.fuegoThreadCount = fuegoThreadCountDefault;
    self.fuegoPondering = fuegoPonderingDefault;
    self.fuegoReuseSubtree = fuegoReuseSubtreeDefault;
  }
  else
  {
    self.fuegoMaxMemory = [[dictionary valueForKey:fuegoMaxMemoryKey] intValue];
    self.fuegoThreadCount = [[dictionary valueForKey:fuegoThreadCountKey] intValue];
    self.fuegoPondering = [[dictionary valueForKey:fuegoPonderingKey] boolValue];
    self.fuegoReuseSubtree = [[dictionary valueForKey:fuegoReuseSubtreeKey] boolValue];
  }
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GtpEngineSettings object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Returns this GtpEngineSettings object's user defaults attributes as a
/// dictionary suitable for storage in the user defaults system.
// -----------------------------------------------------------------------------
- (NSDictionary*) asDictionary
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.fuegoMaxMemory] forKey:fuegoMaxMemoryKey];
  [dictionary setValue:[NSNumber numberWithInt:self.fuegoThreadCount] forKey:fuegoThreadCountKey];
  [dictionary setValue:[NSNumber numberWithBool:self.fuegoPondering] forKey:fuegoPonderingKey];
  [dictionary setValue:[NSNumber numberWithBool:self.fuegoReuseSubtree] forKey:fuegoReuseSubtreeKey];
  return dictionary;
}

// -----------------------------------------------------------------------------
/// @brief Applies settings to the GTP engine.
// -----------------------------------------------------------------------------
- (void) applySettings
{
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

@end
