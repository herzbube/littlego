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


// -----------------------------------------------------------------------------
/// @brief The LayoutManager class is a singleton that provides information
/// about the user interface type and the user interface layout to classes that
/// are layout-aware, i.e. view controllers and possibly views.
///
/// As a convenience, LayoutManager adopts UINavigationControllerDelegate so
/// that it may be assigned as the delegate of a UINavigationController. The
/// only delegate method that LayoutManager overrides is
/// navigationControllerSupportedInterfaceOrientations:(). In the implementation
/// LayoutManager returns the value of its @e supportedInterfaceOrientations
/// property. The purpose of this is so that clients can create a standard
/// UINavigationController object, assign LayoutManager as its delegate, and use
/// it to modally present a view controller. By supplying the proper interface
/// orientations to the navigation controller, LayoutManager makes sure that
/// the user interface can be properly rotated while the modal presentation is
/// taking place.
// -----------------------------------------------------------------------------
@interface LayoutManager : NSObject <UINavigationControllerDelegate>
{
}

+ (LayoutManager*) sharedManager;
+ (void) releaseSharedManager;

/// @brief The user interface type that is currently in effect. The user
/// interface type is determined upon application launch, based on the current
/// device type and the device's screen characteristics. The user interface type
/// never changes during the application's runtime.
@property(nonatomic, assign, readonly) enum UIType uiType;
/// @brief The interface orientation(s) supported by the user interface type
/// that the property @e uiType returns.
///
/// This method implements application-wide orientation support. It can be
/// invoked by all view controllers' implementation of
/// supportedInterfaceOrientations().
///
/// @note supportedInterfaceOrientations:() is relevant for iOS 6 and later.
@property(nonatomic, assign, readonly) NSUInteger supportedInterfaceOrientations;
/// @brief Returns true if the application's user interface is allowed to
/// rotate in response to the device orientation changing. Returns false if the
/// UI is not allowed to rotate.
///
/// The default is true. The value of this property should be set to false only
/// temporarily.
@property(nonatomic, assign) bool shouldAutorotate;

@end
