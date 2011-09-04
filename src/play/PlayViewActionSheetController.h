// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "../newgame/NewGameController.h"


// -----------------------------------------------------------------------------
/// @brief The PlayViewActionSheetController class is responsible for managing
/// an action sheet when the user taps the "Game Actions" button on the "Play"
/// view.
///
/// Tasks implementend by PlayViewActionSheetController are:
/// - Displaying the action sheet with buttons that are appropriate to the
///   current game state
/// - Reacting to the user tapping on each action sheet button
/// - Managing sub-controllers for views that need to be displayed as part of
///   handling the tap on an action sheet button
// -----------------------------------------------------------------------------
@interface PlayViewActionSheetController : NSObject <UIActionSheetDelegate, UIAlertViewDelegate, NewGameDelegate>
{
}

- (id) initWithModalMaster:(UIViewController*)aController;
- (void) showActionSheetFromBarButtonItem:(UIBarButtonItem*)item;

/// @brief Master controller based on which modal view controllers can be
/// displayed.
@property(assign) UIViewController* modalMaster;
/// @brief Maps action sheet button indexes to actions known by this controller.
/// Key = action sheet button index, value = #ActionSheetButton enum value
@property(retain) NSMutableDictionary* buttonIndexes;
@end
