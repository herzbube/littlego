// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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


// Project references
#import "../ui/ItemScrollView.h"


// -----------------------------------------------------------------------------
/// @brief The MoveListController class xxx
///
/// Properties have different values depending on the device type and the
/// current device orientation.
///
/// moveListView frame must be set by outsider
// -----------------------------------------------------------------------------
@interface MoveListController : NSObject <ItemScrollViewDataSource>
{
}

+ (int) moveListViewFontSize;
- (id) init;

/// @brief The move list view.
@property(nonatomic, assign, readonly) ItemScrollView* moveListView;
/// @brief The move list view's total width.
@property(nonatomic, assign, readonly) int moveListViewWidth;
/// @brief The move list view's total height.
@property(nonatomic, assign, readonly) int moveListViewHeight;

@end
