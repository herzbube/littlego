// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NSArrayAdditions.h"


@implementation NSArray(NSArrayAdditions)

// -----------------------------------------------------------------------------
/// @brief Creates and returns an array containing the objects in @a otherArray
/// in reverse order (from highest index position down to 0).
// -----------------------------------------------------------------------------
+ (NSArray*) arrayWithArrayInReverseOrder:(NSArray*)otherArray
{
  return [[otherArray reverseObjectEnumerator] allObjects];
}

// -----------------------------------------------------------------------------
/// @brief Compares the contents of the receiving array with the contents of
/// @a otherArray. Returns @e YES if the contents of @a otherArray are equal to
/// the contents of the receiving array, otherwise returns @e NO. The order in
/// which elements appear in the two arrays is ignored.
///
/// Two arrays have equal contents if they each hold the same number of objects,
/// and if each element of one array is present in the other. Object equality
/// is tested using isEqual:().
// -----------------------------------------------------------------------------
- (BOOL) isEqualToArrayIgnoringOrder:(NSArray*)otherArray;
{
  NSCountedSet* set1 = [[[NSCountedSet alloc] initWithArray:self] autorelease];
  NSCountedSet* set2 = [[[NSCountedSet alloc] initWithArray:otherArray] autorelease];

  return [set1 isEqualToSet:set2];
}

@end
