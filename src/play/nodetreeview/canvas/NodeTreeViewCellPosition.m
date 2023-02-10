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
#import "NodeTreeViewCellPosition.h"


// One-time calculation how many bits are in an unsigned short value
static unsigned short numberOfUnsignedShortBits = CHAR_BIT * sizeof(unsigned short);


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewCellPosition.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCellPosition()
@property(nonatomic, assign, readonly) NSUInteger hashValue;
@end


@implementation NodeTreeViewCellPosition

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed NodeTreeViewCellPosition object that has
/// x-coordinate @a x and y-coordinate @a y.
// -----------------------------------------------------------------------------
+ (NodeTreeViewCellPosition*) positionWithX:(unsigned short)x y:(unsigned short)y
{
  return [[[self alloc] initWithX:x y:y] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns a newly constructed NodeTreeViewCellPosition object that
/// refers to the top-left position in a canvas whose origin is in the top-left
/// corner. The returned NodeTreeViewCellPosition object has both the
/// x-coordinate and y-coordinate set to 0 (zero).
// -----------------------------------------------------------------------------
+ (NodeTreeViewCellPosition*) topLeftPosition
{
  return [NodeTreeViewCellPosition positionWithX:0 y:0];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewCellPosition object with x-coordinate @a x
/// and y-coordinate @a y.
///
/// @note This is the designated initializer of NodeTreeViewCellPosition.
// -----------------------------------------------------------------------------
- (id) initWithX:(unsigned short)x y:(unsigned short)y
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  _x = x;
  _y = y;

  // Shifting makes sure that if the values of x and y are swapped the resulting
  // hash is still different. This avoids hash collisions for positions near the
  // top of the tree where the values of x and y are small and x/y swapping is
  // likely to occur. Deeper in the tree x/y swapping is much less likely to
  // occur because in a reasonable game the number of moves (i.e. the tree depth
  // or x-value) is much higher than the number of game variations (i.e. the
  // tree width or y-value).
  // Note: It is expected that sizeof(NSUInteger) > sizeof(unsigned short). This
  // expectation is reasonable since all Apple platforms are 64 bit platforms.
  // Even if the expectation is not met, we still satisfy all requirements for
  // using NodeTreeViewCellPosition as key in a hash collection (e.g.
  // NSDictionary), the only problem is that there will be more hash collisions
  // as now only the value of y is relevant for the hash.
  _hashValue = (_x << numberOfUnsignedShortBits) ^ _y;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewCellPosition object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief NSObject method
// -----------------------------------------------------------------------------
- (NSUInteger) hash
{
  return _hashValue;
}

// -----------------------------------------------------------------------------
/// @brief NSObject method
// -----------------------------------------------------------------------------
- (BOOL) isEqual:(id)otherPosition
{
  if (! otherPosition)
    return NO;
  else if (self == otherPosition)
    return YES;
  else if (! [otherPosition isKindOfClass:[NodeTreeViewCellPosition class]])
    return NO;
  else
    return [self isEqualToPosition:otherPosition];
}

// -----------------------------------------------------------------------------
/// @brief NSObject method
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"NodeTreeViewCellPosition: x = %hu, y = %hu", _x, _y];
}

#pragma mark - NSCopying overrides

// -----------------------------------------------------------------------------
/// @brief NSCopying method
// -----------------------------------------------------------------------------
- (id) copyWithZone:(NSZone *)zone
{
  // Implementation notes:
  // - According to Apple's docs for NSCopying [1], it is OK to return self
  //   "[...] when the class and its contents are immutable".
  // - In addition we retain the returned instance because "[...] A copy
  //   produced with NSCopying is implicitly retained by the sender, who is
  //   responsible for releasing it."
  // - Because we inherit directly from NSObject, and NSObject itself does not
  //   adopt NSCopying, we must not invoke super's copyWithZone:().
  // [1] https://developer.apple.com/documentation/foundation/nscopying?language=objc
  return [self retain];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Returns @e YES if the receiving NodeTreeViewCellPosition object is
/// equal to @a otherPosition. Equality is measured by comparing the values of
/// the properties @e x and @e y.
// -----------------------------------------------------------------------------
- (BOOL) isEqualToPosition:(NodeTreeViewCellPosition*)otherPosition
{
  if (! otherPosition)
    return NO;
  else if (self == otherPosition)
    return YES;
  else
    return (_x == otherPosition.x && _y == otherPosition.y);
}

@end
