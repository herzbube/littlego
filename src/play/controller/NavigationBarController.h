// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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

// Forward declarations
@class NavigationBarButtonModel;


// -----------------------------------------------------------------------------
/// @brief The NavigationBarController class represents the controller that is
/// responsible for managing the navigation bar above the Go board in
/// #UIAreaPlay.
///
/// The navigation bar in #UIAreaPlay is managed differently depending on the
/// UI type that is effective at runtime. Use the class method
/// navigationBarController() to obtain a UI type-dependent controller object
/// that knows how to correctly manage the navigation bar for the current UI
/// type.
///
/// @todo The controller object that manages the navigation bar in #UITypePhone
/// (NavigationBarControllerPhone) currently is not a subclass of
/// NavigationBarController. If possible this should be changed. One notable
/// difficulty is that NavigationBarControllerPhone is not a view controller,
/// while NavigationBarController itself derives from UIViewController.
// -----------------------------------------------------------------------------
@interface NavigationBarController : UIViewController <GameActionManagerUIDelegate>
{
}

+ (NavigationBarController*) navigationBarController;

// Methods to override by subclasses
- (void) populateNavigationBar;
- (UIView*) moreGameActionsNavigationBar;

// Properties for use by subclasses
@property(nonatomic, retain) NavigationBarButtonModel* navigationBarButtonModel;

@end
