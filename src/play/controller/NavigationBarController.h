// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameActionManager.h"
#import "../../ui/SplitViewController.h"

// Forward declarations
@class StatusViewController;


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
///
/// The navigation bar that the user sees actually consists of 3 different
/// UINavigationBar instances:
/// - Left side: Contains some buttons
/// - Center: Contains the status view
/// - Right side: Contains more buttons
///
/// The center UINavigationBar is used only to provide the status view with the
/// standard translucent background appearance, making it appear to the user as
/// if there were a single navigation bar. On the iPhone the widths of the three
/// UINavigationBar views are dynamically calculated, to make room for longer
/// texts that can appear in the status view. This is necessary because the
/// screen width is so limited.
// -----------------------------------------------------------------------------
@interface NavigationBarController : UIViewController <SplitViewControllerDelegate, GameActionManagerUIDelegate>
{
}

@property(nonatomic, retain) StatusViewController* statusViewController;

@end
