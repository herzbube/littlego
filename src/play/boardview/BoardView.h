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


// Forward declarations
@class BoardTileView;
@class BoardView;

// -----------------------------------------------------------------------------
/// @brief The data source of BoardView must adopt the BoardViewDataSource
/// protocol.
// -----------------------------------------------------------------------------
@protocol BoardViewDataSource <NSObject>
- (BoardTileView*) boardView:(BoardView*)boardView boardTileViewForRow:(int)row column:(int)column;
@end


// -----------------------------------------------------------------------------
/// @brief The BoardView class xxx
// -----------------------------------------------------------------------------
@interface BoardView : UIScrollView
{
}

- (BoardTileView*) dequeueReusableTile;
- (void) reloadData;

@property(nonatomic, assign) id<BoardViewDataSource> dataSource;
@property(nonatomic, retain, readonly) UIView* tileContainerView;
@property(nonatomic, assign) CGSize tileSize;

@end
