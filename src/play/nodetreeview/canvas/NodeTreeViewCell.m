// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewCell.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewCell.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCell()
@end


@implementation NodeTreeViewCell

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed NodeTreeViewCell object that is a
/// standalone cell without any content.
// -----------------------------------------------------------------------------
+ (NodeTreeViewCell*) emptyCell
{
  return [[[self alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewCell object so that it is a standalone cell
/// without any content.
///
/// @note This is the designated initializer of NodeTreeViewCell.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.symbol = NodeTreeViewCellSymbolNone;
  self.selected = false;
  self.lines = NodeTreeViewCellLineNone;
  self.linesSelectedGameVariation = NodeTreeViewCellLineNone;
  self.part = 0;
  self.parts = 1;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewCell object.
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
  else if (! [otherCell isKindOfClass:[NodeTreeViewCell class]])
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
  return [NSString stringWithFormat:@"NodeTreeViewCell: symbol = %u, selected = %d, lines = %hu, linesSelectedGameVariation = %hu, part = %hu, parts = %hu", _symbol, _selected, _lines, _linesSelectedGameVariation, _part, _parts];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isMultipart
{
  return self.parts > 1;
}

// -----------------------------------------------------------------------------
/// @brief Returns @e YES if the receiving NodeTreeViewCell object is equal to
/// @a otherCell. Equality is measured by comparing the values of all properties
/// (@e symbol, @e selected, @e lines, @e linesSelectedGameVariation, @e part
/// and @e parts).
// -----------------------------------------------------------------------------
- (BOOL) isEqualToCell:(NodeTreeViewCell*)otherCell
{
  if (! otherCell)
    return NO;
  else if (self == otherCell)
    return YES;
  else
    return (_symbol == otherCell.symbol &&
            _selected == otherCell.selected &&
            _lines == otherCell.lines &&
            _linesSelectedGameVariation == otherCell.linesSelectedGameVariation &&
            _part == otherCell.part &&
            _parts == otherCell.parts);
}

@end
