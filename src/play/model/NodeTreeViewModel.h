// -----------------------------------------------------------------------------
// Copyright 2022-2023 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The NodeTreeViewModel class provides user defaults data and other
/// values to its clients that are related to drawing the node tree view.
// -----------------------------------------------------------------------------
@interface NodeTreeViewModel : NSObject
{
}

- (id) init;

- (void) readUserDefaults;
- (void) writeUserDefaults;

@property(nonatomic, assign) bool displayNodeTreeView;
@property(nonatomic, assign) bool displayNodeNumbers;
@property(nonatomic, assign) bool condenseMoveNodes;
@property(nonatomic, assign) bool alignMoveNodes;
@property(nonatomic, assign) enum NodeTreeViewBranchingStyle branchingStyle;
@property(nonatomic, assign) enum NodeTreeViewNodeSelectionStyle nodeSelectionStyle;
@property(nonatomic, assign) enum NodeTreeViewFocusMode focusMode;
@property(nonatomic, assign) bool nodeNumberViewIsOverlay;
@property(nonatomic, assign) bool numberCondensedMoveNodes;
@property(nonatomic, assign) int numberOfCellsOfMultipartCell;

@end
