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


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewCellPosition class stores the coordinates that
/// uniquely identify a cell on the abstract canvas used by NodeTreeViewModel.
///
/// NodeTreeViewCellPosition objects are immutable, i.e. they cannot be changed
/// once they have been created. NodeTreeViewCellPosition conforms to NSCopying
/// and overrides the NSObject methods hash() and isEqual:() so that
/// NodeTreeViewCellPosition objects can be used as keys in NSDictionary.
///
/// @par Implementation note
///
/// The data type for the x/y coordinate values is unsigned short instead of,
/// say, unsigned int, for two reasons:
/// - To reduce the amount of memory being used by a NodeTreeViewCellPosition
/// - To be able to avoid hash collisions when the x/y values are swapped (see
///   implementation for how the hash is calculated).
///
/// unsigned short should be of sufficient size to store any realistic x/y
/// values:
/// - On the x-axis the value is restricted because the app has a limit on the
///   number of moves it supports in any game variation.
/// - On the y-axis the value has no hard restrictions, but the number of
///   variations in a resaonable tree will never exceed the number that can
///   be stored in an unsigned short.
///
/// Having said this, it is of course possible to craft an .sgf file that
/// exceeds the limits imposed by the unsigned short value range in both x and y
/// directions. If someone wants to break the app with such an .sgf file, this
/// is an accepted risk.
// -----------------------------------------------------------------------------
@interface NodeTreeViewCellPosition : NSObject <NSCopying>
{
}

+ (NodeTreeViewCellPosition*) positionWithX:(unsigned short)x y:(unsigned short)y;
+ (NodeTreeViewCellPosition*) topLeftPosition;

- (BOOL) isEqualToPosition:(NodeTreeViewCellPosition*)otherPosition;

/// @brief The cell position in x-direction on the abstract NodeTreeViewModel
/// canvas.
@property(nonatomic, assign, readonly) unsigned short x;

/// @brief The cell position in y-direction on the abstract NodeTreeViewModel
/// canvas.
@property(nonatomic, assign, readonly) unsigned short y;

@end
