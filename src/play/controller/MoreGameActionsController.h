// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class MoreGameActionsController;


// -----------------------------------------------------------------------------
/// @brief The MoreGameActionsControllerDelegate protocol must be implemented by
/// the delegate of MoreGameActionsController.
// -----------------------------------------------------------------------------
@protocol MoreGameActionsControllerDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for releasing
/// @a controller.
- (void) moreGameActionsControllerDidFinish:(MoreGameActionsController*)controller;
@end


// -----------------------------------------------------------------------------
/// @brief The MoreGameActionsController class is responsible for managing an
/// alert message when the user taps the "More Game Actions" button in
/// #UIAreaPlay. The alert message displays buttons that represent game actions
/// that are not used very often and therefore do not need to be visible all the
/// time.
///
/// Tasks implementend by MoreGameActionsController are:
/// - Displaying an alert message with buttons that are appropriate to the
///   current game state
/// - Reacting to the user tapping on each button
/// - Managing sub-controllers for views that need to be displayed as part of
///   handling the tap on a button
// -----------------------------------------------------------------------------
@interface MoreGameActionsController : NSObject <NewGameControllerDelegate, EditTextDelegate, ItemPickerDelegate>
{
}

- (id) initWithModalMaster:(UIViewController*)aController delegate:(id<MoreGameActionsControllerDelegate>)aDelegate;
- (void) showAlertMessageFromRect:(CGRect)rect inView:(UIView*)view;
- (void) cancelAlertMessage;

/// @brief This is the delegate that will be informed when
/// MoreGameActionsController has finished its task.
@property(nonatomic, assign) id<MoreGameActionsControllerDelegate> delegate;
/// @brief Master controller based on which modal view controllers can be
/// displayed.
@property(nonatomic, assign) UIViewController* modalMaster;

@end
