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
@property(nonatomic, retain) UIView* placeholderContainerView;
@property(nonatomic, retain) PlaceholderView* placeholderView;
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicatorView;
@property(nonatomic, retain) UIView* webBrowserContainerView;
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

  self.placeholderContainerView = nil;
  self.placeholderView = nil;
  self.activityIndicatorView = nil;
  self.webBrowserContainerView = nil;

  NSString* filePath = [UserManualUtilities userManualEntryPointFilePath];
  NSURL* url = [NSURL fileURLWithPath:filePath];
  self.webBrowserViewController = [[[WebBrowserViewController alloc] initWithHomeUrl:url] autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this UserManualViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.placeholderContainerView = nil;
  self.placeholderView = nil;
  self.activityIndicatorView = nil;
  self.webBrowserContainerView = nil;
  self.webBrowserViewController = nil;

  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setWebBrowserViewController:(WebBrowserViewController*)webBrowserViewController
{
  if (_webBrowserViewController == webBrowserViewController)
    return;
  if (_webBrowserViewController)
  {
    [_webBrowserViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_webBrowserViewController removeFromParentViewController];
    [_webBrowserViewController release];
    _webBrowserViewController = nil;
  }
  if (webBrowserViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:webBrowserViewController];
    [webBrowserViewController didMoveToParentViewController:self];
    [webBrowserViewController retain];
    _webBrowserViewController = webBrowserViewController;
  }
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

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];

  // In iOS 5, the system purges the view and self.isViewLoaded becomes false
  // before didReceiveMemoryWarning() is invoked. In iOS 6 the system does not
  // purge the view and self.isViewLoaded is still true when we get here. The
  // view's window property then becomes important: It is nil if the main tab
  // bar controller displays a different tab than the one where the view is
  // visible.
  if (self.isViewLoaded && ! self.view.window)
  {
    self.placeholderContainerView = nil;
    self.placeholderView = nil;
    self.activityIndicatorView = nil;
    self.webBrowserContainerView = nil;
    self.view = nil;
  }
}

#pragma mark - View hierarchy and layout setup

// -----------------------------------------------------------------------------
/// @brief One-time setup of view hierarchy.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.placeholderContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.placeholderContainerView];

  self.webBrowserContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.webBrowserContainerView];

  self.placeholderView = [[[PlaceholderView alloc] initWithFrame:CGRectZero placeholderText:@"Preparing the user manual.\n\nThis should take only a moment ..."] autorelease];
  [self.placeholderContainerView addSubview:self.placeholderView];

  self.activityIndicatorView = [[[UIActivityIndicatorView alloc] initWithFrame:CGRectZero] autorelease];
  [self.placeholderContainerView addSubview:self.activityIndicatorView];
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
  self.placeholderContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  self.webBrowserContainerView.translatesAutoresizingMaskIntoConstraints = NO;

  [AutoLayoutUtility fillSuperview:self.view withSubview:self.placeholderContainerView];
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.webBrowserContainerView];

  self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
  self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;

  [AutoLayoutUtility fillSuperview:self.placeholderContainerView withSubview:self.placeholderView];

  [AutoLayoutUtility alignFirstView:self.activityIndicatorView
                     withSecondView:self.placeholderView
                        onAttribute:NSLayoutAttributeCenterX
                   constraintHolder:self.placeholderContainerView];
  [NSLayoutConstraint constraintWithItem:self.activityIndicatorView
                               attribute:NSLayoutAttributeTop
                               relatedBy:NSLayoutRelationEqual
                                  toItem:self.placeholderView.placeholderLabel
                               attribute:NSLayoutAttributeBottom
                              multiplier:1.0f
                                constant:50.0f].active = YES;
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
/// Adds the view of WebBrowserViewController to the view hierarchy and hides
/// the no longer needed placeholder view and activity indicator view. Also
/// adds the web browser controls provided by WebBrowserViewController to the
/// navigation item of this UserManualViewController.
///
/// @attention Accessing the view of WebBrowserViewController triggers a request
/// to the home URL. This means that the view of WebBrowserViewController must
/// only be accessed after the user manual is present.
// -----------------------------------------------------------------------------
- (void) handleUserManualSetupSucceeded
{
  [self.activityIndicatorView stopAnimating];

  [self.webBrowserContainerView addSubview:self.webBrowserViewController.view];

  self.webBrowserViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  // Vertically only fill the safe area because the web view should not extend
  // below the navigation bar at the top and the tab bar at the bottom.
  // Horizontally it's fine to fill the entire view and therefore to extend to
  // the screen edges => we rely on the web view to render content only within
  // its own safe area.
  [AutoLayoutUtility fillSuperview:self.webBrowserContainerView
                       withSubview:self.webBrowserViewController.view
                     viewEdgesAxis:UILayoutConstraintAxisHorizontal
                 safeAreaEdgesAxis:UILayoutConstraintAxisVertical];

  self.placeholderContainerView.hidden = YES;

  self.navigationItem.rightBarButtonItems = @[
    self.webBrowserViewController.homeButton,
    self.webBrowserViewController.forwardButton,
    self.webBrowserViewController.backButton];
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
