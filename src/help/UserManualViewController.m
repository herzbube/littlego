// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "UserManualViewController.h"
#import "UserManualUtilities.h"
#import "../command/SetupUserManualCommand.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/PlaceholderView.h"
#import "../ui/WebBrowserViewController.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for UserManualViewController.
// -----------------------------------------------------------------------------
@interface UserManualViewController()
@property(nonatomic, retain) PlaceholderView* placeholderView;
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicatorView;
@property(nonatomic, retain) WebBrowserViewController* webBrowserViewController;
@end


@implementation UserManualViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an UserManualViewController object.
///
/// @note This is the designated initializer of UserManualViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.placeholderView = nil;
  self.activityIndicatorView = nil;
  self.webBrowserViewController = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UserManualViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.placeholderView = nil;
  self.activityIndicatorView = nil;
  self.webBrowserViewController = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  // self.edgesForExtendedLayout is UIRectEdgeAll, therefore we have to provide
  // a background color that is visible behind the navigation bar at the top
  // (which on smaller iPhones extends behind the statusbar) and the tab bar
  // at the bottom. The background is only visible when the placeholder view
  // is shown.
  self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];

  [self setupViewHierarchy];
  [self configureViews];
  [self setupAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self setupUserManual];
}

#pragma mark - View hierarchy and layout setup

// -----------------------------------------------------------------------------
/// @brief One-time setup of view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.placeholderView = [[[PlaceholderView alloc] initWithFrame:CGRectZero placeholderText:@"Preparing the user manual.\n\nThis should take only a moment ..."] autorelease];
  [self.view addSubview:self.placeholderView];

  self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.activityIndicatorView];
}

// -----------------------------------------------------------------------------
/// @brief One-time configuration of views.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.activityIndicatorView.transform = CGAffineTransformMakeScale(3, 3);
}

// -----------------------------------------------------------------------------
/// @brief One-time setup of Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;

  [AutoLayoutUtility fillSuperview:self.view withSubview:self.placeholderView];

  [AutoLayoutUtility alignFirstView:self.activityIndicatorView
                     withSecondView:self.placeholderView
                        onAttribute:NSLayoutAttributeCenterX
                   constraintHolder:self.view];
  [AutoLayoutUtility alignFirstView:self.activityIndicatorView
                     withSecondView:self.placeholderView
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
}

#pragma mark - Handling of user manual setup

// -----------------------------------------------------------------------------
/// @brief Initiates the setup of the user manual by submitting
/// SetupUserManualCommand.
///
/// SetupUserManualCommand is an asynchronous command because the setup may take
/// some time and we don't want to block the UI when the user calls up the
/// "Help" tab.
///
/// Also it is conceivable that the setup might occur during application launch
/// when the application delegate sets up the UI. If in that moment the "Help"
/// tab is the current tab (because the user ended the last app session on that
/// tab) the view of this UserManualViewController is loaded and the user manual
/// setup is triggered. Because application launch must not be delayed in any
/// way (otherwise iOS might kill the app) the setup must be performed
/// asynchronously.
///
/// @note When testing this scenario on the simulator the UIViewController
/// method viewDidLoad() always was invoked after SetupApplicationCommand was
/// already executing. However, we don't want to rely on this because different
/// versions of iOS might behave differently.
///
/// Because the command execution progress HUD is already occupied during app
/// launch (by SetupApplicationCommand) the SetupUserManualCommand must not
/// also use the progress HUD. In its stead this UserManualViewController shows
/// a placeholder text and an activity indicator.
// -----------------------------------------------------------------------------
- (void) setupUserManual
{
  [self.activityIndicatorView startAnimating];

  SetupUserManualCommand* command = [[[SetupUserManualCommand alloc] init] autorelease];
  [command submitWithCompletionHandler:^(NSObject<Command>* command, bool success)
   {
    // UIKit manipulations must occur on the main thread. This completion
    // handler is not invoked on the main thread because SetupUserManualCommand
    // is an asynchronous command.
    SEL handler = (success
                   ? @selector(handleUserManualSetupSucceeded)
                   : @selector(handleUserManualSetupFailed));
    [self performSelectorOnMainThread:handler withObject:nil waitUntilDone:NO];
  }];
}

// -----------------------------------------------------------------------------
/// @brief This handler needs to be invoked when setting up the user manual
/// succeeds.
///
/// Permanently pushes an instance of WebBrowserViewController to the top of the
/// navigation controller associated with this UserManualViewController, thus
/// hiding the no longer needed placeholder view and activity indicator view.
// -----------------------------------------------------------------------------
- (void) handleUserManualSetupSucceeded
{
  [self.activityIndicatorView stopAnimating];

  NSString* title = self.title;
  NSString* filePath = [UserManualUtilities userManualEntryPointFilePath];
  NSURL* url = [NSURL fileURLWithPath:filePath];
  UIViewController* webBrowserViewController = [WebBrowserViewController controllerWithTitle:title homeUrl:url];
  [self.navigationController pushViewController:webBrowserViewController animated:false];
}

// -----------------------------------------------------------------------------
/// @brief This handler needs to be invoked when setting up the user manual
/// fails.
///
/// Updates the placeholder view with information about the failure and stops
/// the no longer needed activity indicator.
// -----------------------------------------------------------------------------
- (void) handleUserManualSetupFailed
{
  [self.activityIndicatorView stopAnimating];

  self.placeholderView.placeholderLabel.text = @"The user manual is not available.\n\nPreparing the user manual failed.\nPlease submit a bug report.";
}

@end
