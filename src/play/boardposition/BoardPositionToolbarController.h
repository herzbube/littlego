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



// -----------------------------------------------------------------------------
/// @brief The BoardPositionToolbarController class is responsible for managing
/// the toolbar with controls to navigate the game's list of board positions.
///
/// BoardPositionToolbarController has the following responsibilities:
/// - Populate the toolbar with controls. This includes knowledge how the
///   controls need to be laid out in the toolbar.
/// - React to taps on self-created bar buttons
///
/// Some of the controls that are displayed in the toolbar are custom views
/// that are externally provided when BoardPositionToolbarController is
/// initialized. BoardPositionToolbarController is @b NOT responsible for
/// managing user interaction with these custom views - there are separate
/// controllers for that.
///
/// The remaining controls are a set of buttons that are self-created by
/// BoardPositionToolbarController. For these, BoardPositionToolbarController
/// also manages user interaction.
///
/// BoardPositionToolbarController can be triggered to repopulate the toolbar.
/// External forces need to invoke certain methods to indicate which controls
/// are desired.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController : NSObject
{
}

- (id) initWithToolbar:(UIToolbar*)toolbar boardPositionListView:(UIView*)listView currentBoardPositionView:(UIView*)currentView;
- (void) toggleToolbarItems;

@end
