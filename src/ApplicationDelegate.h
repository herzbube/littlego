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


// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class GtpClient;
@class GtpEngine;


// -----------------------------------------------------------------------------
/// @brief The ApplicationDelegate class implements the role of delegate of the
/// UIApplication main object.
///
/// As an additional responsibility, it creates instances of GtpEngine and
/// GtpClient and sets them up to communicate with each other.
///
/// @note ApplicationDelegate is instantiated when MainWindow.xib is loaded.
/// The single instance of ApplicationDelegate is available to clients via the
/// class method sharedDelegate().
// -----------------------------------------------------------------------------
@interface ApplicationDelegate : NSObject <UIApplicationDelegate>
{
@private
  /// @name Outlets
  /// @brief These variables are outlets and initialized in MainWindow.xib.
  //@{
  UIWindow* window;
  UITabBarController* tabBarController;
  //@}
}

+ (ApplicationDelegate*) sharedDelegate;

/// @brief The main application window.
@property(nonatomic, retain) IBOutlet UIWindow* window;
/// @brief The main application controller.
@property(nonatomic, retain) IBOutlet UITabBarController* tabBarController;
/// @brief The GTP client instance.
@property(retain) GtpClient* gtpClient;
/// @brief The GTP engine instance.
@property(retain) GtpEngine* gtpEngine;

@end

