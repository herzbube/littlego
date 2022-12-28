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

#pragma mark - Public API

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (bool) isMultipart
{
  return self.parts > 1;
}

@end
