// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
@class BoardPositionListViewController;


// -----------------------------------------------------------------------------
/// @brief The BoardPositionToolbarController class is responsible for managing
/// the toolbar with controls to navigate the game's list of board positions.
///
/// BoardPositionToolbarController is a container view controller on the iPhone,
/// and a child view controller on the iPad. It has the following
/// responsibilities:
/// - Populate the toolbar with controls. This includes knowledge how the
///   controls need to be laid out in the toolbar.
/// - iPhone only: Integrate child view controllers' root views into the toolbar
///   as bar button items with custom views
/// - React to taps on bar buttons (only those owned by
///   BoardPositionToolbarController)
///
/// BoardPositionToolbarController specifically is @b NOT responsible for
/// managing user interaction with custom view bar button items - this is the
/// job of the respective child view controllers.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController : UIViewController <UIToolbarDelegate, CurrentBoardPositionViewControllerDelegate>
{
}

@property(nonatomic, retain) BoardPositionListViewController* boardPositionListViewController;
@property(nonatomic, retain) CurrentBoardPositionViewController* currentBoardPositionViewController;

@end
