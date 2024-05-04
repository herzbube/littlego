// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeNumbersViewCell.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeNumbersViewCell.
// -----------------------------------------------------------------------------
@interface NodeNumbersViewCell()
@end


@implementation NodeNumbersViewCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed NodeNumbersViewCell object without any
/// content.
// -----------------------------------------------------------------------------
+ (NodeNumbersViewCell*) emptyCell
{
  return [[[self alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeNumbersViewCell object without any content.
///
/// @note This is the designated initializer of NodeNumbersViewCell.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeNumber = -1;
  self.selected = false;
  self.nodeNumberExistsOnlyForSelection = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeNumbersViewCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief NSObject method
// -----------------------------------------------------------------------------
- (BOOL) isEqual:(id)otherCell
{
  if (! otherCell)
    return NO;
  else if (self == otherCell)
    return YES;
  else if (! [otherCell isKindOfClass:[NodeNumbersViewCell class]])
    return NO;
  else
    return [self isEqualToCell:otherCell];
}

// -----------------------------------------------------------------------------
/// @brief NSObject method
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"NodeNumbersViewCell: nodeNumber = %u, part = %hu, selected = %d, nodeNumberExistsOnlyForSelection = %d", _nodeNumber, _part, _selected, _nodeNumberExistsOnlyForSelection];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns @e YES if the receiving NodeNumbersViewCell object is equal
/// to @a otherCell. Equality is measured by comparing the values of all
/// properties (@e nodeNumber, @e part, @e selected and
/// @e nodeNumberExistsOnlyForSelection).
// -----------------------------------------------------------------------------
- (BOOL) isEqualToCell:(NodeNumbersViewCell*)otherCell
{
  if (! otherCell)
    return NO;
  else if (self == otherCell)
    return YES;
  else
    return (_nodeNumber == otherCell.nodeNumber &&
            _part == otherCell.part &&
            _selected == otherCell.selected &&
            _nodeNumberExistsOnlyForSelection == otherCell.nodeNumberExistsOnlyForSelection);
}

@end
