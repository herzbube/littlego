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
#import "ArchiveViewModel.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ArchiveViewModel.
// -----------------------------------------------------------------------------
@interface ArchiveViewModel()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
@end


@implementation ArchiveViewModel

@synthesize sortCriteria;
@synthesize sortAscending;


// -----------------------------------------------------------------------------
/// @brief Initializes a ArchiveViewModel object with user defaults data.
///
/// @note This is the designated initializer of ArchiveViewModel.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.sortCriteria = FileNameArchiveSort;
  self.sortAscending = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ArchiveViewModel object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Initializes default values in this model with user defaults data.
// -----------------------------------------------------------------------------
- (void) readUserDefaults
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  NSDictionary* dictionary = [userDefaults dictionaryForKey:archiveViewKey];
  self.sortCriteria = [[dictionary valueForKey:sortCriteriaKey] intValue];
  self.sortAscending = [[dictionary valueForKey:sortAscendingKey] boolValue];
}

// -----------------------------------------------------------------------------
/// @brief Writes current values in this model to the user default system's
/// application domain.
// -----------------------------------------------------------------------------
- (void) writeUserDefaults
{
  NSMutableDictionary* dictionary = [NSMutableDictionary dictionary];
  [dictionary setValue:[NSNumber numberWithInt:self.sortCriteria] forKey:sortCriteriaKey];
  [dictionary setValue:[NSNumber numberWithBool:self.sortAscending] forKey:sortAscendingKey];
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:dictionary forKey:playViewKey];
}

@end
