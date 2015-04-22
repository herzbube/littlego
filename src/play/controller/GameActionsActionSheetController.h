// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../newgame/NewGameController.h"
#import "../../ui/EditTextController.h"

// Forward declarations
@class GameActionsActionSheetController;


// -----------------------------------------------------------------------------
/// @brief The GameActionsActionSheetDelegate protocol must be implemented by
/// the delegate of GameActionsActionSheetController.
// -----------------------------------------------------------------------------
@protocol GameActionsActionSheetDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for releasing
/// @a controller.
- (void) gameActionsActionSheetControllerDidFinish:(GameActionsActionSheetController*)controller;
@end


// -----------------------------------------------------------------------------
/// @brief The GameActionsActionSheetController class is responsible for
/// managing an action sheet when the user taps the "Game Actions" button in
/// #UIAreaPlay.
///
/// Tasks implementend by GameActionsActionSheetController are:
/// - Displaying the action sheet with buttons that are appropriate to the
///   current game state
/// - Reacting to the user tapping on each action sheet button
/// - Managing sub-controllers for views that need to be displayed as part of
///   handling the tap on an action sheet button
// -----------------------------------------------------------------------------
@interface GameActionsActionSheetController : NSObject <UIActionSheetDelegate, UIAlertViewDelegate, NewGameControllerDelegate, EditTextDelegate>
{
}

- (id) initWithModalMaster:(UIViewController*)aController delegate:(id<GameActionsActionSheetDelegate>)aDelegate;
- (void) showActionSheetFromRect:(CGRect)rect inView:(UIView*)view;
- (void) cancelActionSheet;

/// @brief This is the delegate that will be informed when
/// GameActionsActionSheetController has finished its task.
@property(nonatomic, assign) id<GameActionsActionSheetDelegate> delegate;
/// @brief Master controller based on which modal view controllers can be
/// displayed.
@property(nonatomic, assign) UIViewController* modalMaster;
/// @brief Maps action sheet button indexes to actions known by this controller.
/// Key = action sheet button index, value = #ActionSheetButton enum value
@property(nonatomic, retain) NSMutableDictionary* buttonIndexes;

@end
