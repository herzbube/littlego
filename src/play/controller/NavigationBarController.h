// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewController.h"
#import "PlayViewActionSheetController.h"

// Forward declarations
@class CommandBase;
@class NavigationBarController;
@class StatusViewController;


// -----------------------------------------------------------------------------
/// @brief The NavigationBarControllerDelegate protocol must be implemented by
/// the delegate of NavigationBarController.
// -----------------------------------------------------------------------------
@protocol NavigationBarControllerDelegate
/// @brief This method is invoked when the user attempts to play a move. The
/// delegate executes @a command, possibly displaying an alert first which the
/// user must confirm.
- (void) navigationBarController:(NavigationBarController*)controller playOrAlertWithCommand:(CommandBase*)command;
/// @brief This method is invoked when the user attempts to discard board
/// positions. The delegate executes @a command, possibly displaying an alert
/// first which the user must confirmed.
- (void) navigationBarController:(NavigationBarController*)controller discardOrAlertWithCommand:(CommandBase*)command;
@end


// -----------------------------------------------------------------------------
/// @brief The NavigationBarController class is responsible for managing the
/// navigation bar above the Go board on the Play tab.
///
/// NavigationBarController is a container view controller. Its responsibilities
/// include:
/// - Populate the navigation bar with buttons that are appropriate for the
///   current game state
/// - Enable/disable buttons
/// - React to the user tapping on buttons
/// - Integrate the status view provided by the StatusViewController child view
///   controller into the navigation bar
// -----------------------------------------------------------------------------
@interface NavigationBarController : UIViewController <GameInfoViewControllerDelegate,
                                                       PlayViewActionSheetDelegate,
                                                       UIAlertViewDelegate,
                                                       UISplitViewControllerDelegate>
{
}

@property(nonatomic, retain) StatusViewController* statusViewController;
@property(nonatomic, assign) id<NavigationBarControllerDelegate> delegate;

@end
