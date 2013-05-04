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


// Project includes
#import "CurrentBoardPositionViewController.h"

// Forward declarations
@class BoardPositionViewMetrics;


// -----------------------------------------------------------------------------
/// @brief The BoardPositionToolbarController class is responsible for managing
/// the toolbar with controls to navigate the game's list of board positions.
///
/// BoardPositionToolbarController has the following responsibilities:
/// - Populate the toolbar with controls. This includes knowledge how the
///   controls need to be laid out in the toolbar.
/// - React to taps on self-created bar buttons
///
/// One of the initializers is used to supply custom views that also need to be
/// displayed in the toolbar. The only thing BoardPositionToolbarController
/// knows about these custom views is where to place them in the toolbar.
/// BoardPositionToolbarController specifically is @b NOT responsible for
/// managing user interaction with these custom views - there are separate
/// controllers for that.
///
/// @note Custom views are used on the iPhone only.
///
/// The remaining controls are a set of buttons that are self-created by
/// BoardPositionToolbarController. For these, BoardPositionToolbarController
/// also manages user interaction.
///
/// BoardPositionToolbarController can be triggered to repopulate the toolbar.
/// This only has an effect if custom views are used.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController : UIViewController <CurrentBoardPositionViewControllerDelegate>
{
}

@property(nonatomic, retain) BoardPositionViewMetrics* boardPositionViewMetrics;

@end
