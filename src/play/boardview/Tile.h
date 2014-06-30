// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The Tile protocol defines the interface that tile views displayed
/// by TiledScrollView must implement.
///
/// The tile with row/column = 0/0 is in the upper-left corner.
// -----------------------------------------------------------------------------
@protocol Tile <NSObject>
/// @brief Invalidates the content currently displayed by the tile.
///
/// The tile should redraw its content in response to this method being invoked.
- (void) invalidateContent;

@property(nonatomic, assign) int row;
@property(nonatomic, assign) int column;
@end
