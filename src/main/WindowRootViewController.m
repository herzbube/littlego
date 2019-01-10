// -----------------------------------------------------------------------------
// Copyright 2015-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "WindowRootViewController.h"
#import "MainNavigationController.h"
#import "MainTabBarController.h"
#import "../shared/LayoutManager.h"
#import "../ui/AutoLayoutUtility.h"
#import "../ui/MagnifyingViewController.h"
#import "../utility/ExceptionUtility.h"


enum MainApplicationViewControllerType
{
  MainApplicationViewControllerType_MainTabBarController,
  MainApplicationViewControllerType_MainNavigationController
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for WindowRootViewController.
// -----------------------------------------------------------------------------
@interface WindowRootViewController()
@property(nonatomic, assign) enum MainApplicationViewControllerType currentMainApplicationViewControllerType;
@property(nonatomic, retain) NSArray* autoLayoutConstraints;
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) bool magnifyingGlassEnabled;
@property(nonatomic, retain, readwrite) MagnifyingViewController* magnifyingViewController;
//@}
@end


@implementation WindowRootViewController

#pragma mark - Property synthesizing

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize the properties declared in the
// MagnifyingGlassOwner protocol.
@synthesize magnifyingGlassEnabled = _magnifyingGlassEnabled;
@synthesize magnifyingViewController = _magnifyingViewController;


#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a WindowRootViewController.
///
/// @note This is the designated initializer of WindowRootViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  enum MainApplicationViewControllerType mainApplicationViewControllerType = [self mainApplicationViewControllerTypeForCurrentApplicationState];
  [self setupMainApplicationViewControllerForType:mainApplicationViewControllerType];
  self.magnifyingGlassEnabled = false;  // initializes self.magnifyingViewController
  self.autoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this WindowRootViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.view = nil;
  self.mainApplicationViewController = nil;
  self.magnifyingGlassEnabled = false;  // resets self.magnifyingViewController
  self.autoLayoutConstraints = nil;
  self.magnifyingViewController = nil;
  [super dealloc];
}

#pragma mark - Main application view controller handling

// -----------------------------------------------------------------------------
/// Returns which type of main application view controller is appropriate for
/// the current application state.
///
/// The following pieces of information from the application state are taken
/// into account:
/// - The UI type from LayoutManager
/// - The current interface orientation
// -----------------------------------------------------------------------------
- (enum MainApplicationViewControllerType) mainApplicationViewControllerTypeForCurrentApplicationState
{
  switch ([LayoutManager sharedManager].uiType)
  {
    case UITypePhonePortraitOnly:
      return MainApplicationViewControllerType_MainTabBarController;
    case UITypePhone:
      return MainApplicationViewControllerType_MainNavigationController;
    case UITypePad:
      return MainApplicationViewControllerType_MainTabBarController;
    default:
      [ExceptionUtility throwInvalidUIType:[LayoutManager sharedManager].uiType];
  }
}

// -----------------------------------------------------------------------------
/// Installs the main application view controller that matches the specified
/// type.
// -----------------------------------------------------------------------------
- (void) setupMainApplicationViewControllerForType:(enum MainApplicationViewControllerType)mainApplicationViewControllerType
{
  switch (mainApplicationViewControllerType)
  {
    case MainApplicationViewControllerType_MainTabBarController:
    {
      self.mainApplicationViewController = [[[MainTabBarController alloc] init] autorelease];
      break;
    }
    case MainApplicationViewControllerType_MainNavigationController:
    {
      self.mainApplicationViewController = [[[MainNavigationController alloc] init] autorelease];
      break;
    }
    default:
    {
      [ExceptionUtility throwInvalidArgumentExceptionWithFormat:@"Invalid main application view controller type %d"
                                                  argumentValue:mainApplicationViewControllerType];
    }
  }
  self.currentMainApplicationViewControllerType = mainApplicationViewControllerType;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setMainApplicationViewController:(UIViewController*)mainApplicationViewController
{
  if (_mainApplicationViewController == mainApplicationViewController)
    return;
  if (_mainApplicationViewController)
  {
    [_mainApplicationViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_mainApplicationViewController removeFromParentViewController];
    [_mainApplicationViewController release];
    _mainApplicationViewController = nil;
  }
  if (mainApplicationViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:mainApplicationViewController];
    [mainApplicationViewController didMoveToParentViewController:self];
    [mainApplicationViewController retain];
    _mainApplicationViewController = mainApplicationViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self setupViewHierarchy];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  enum MainApplicationViewControllerType newMainApplicationViewControllerType = [self mainApplicationViewControllerTypeForCurrentApplicationState];
  if (newMainApplicationViewControllerType == self.currentMainApplicationViewControllerType)
    return;

  [self removeViewHierarchy];
  [self setupMainApplicationViewControllerForType:newMainApplicationViewControllerType];
  [self setupViewHierarchy];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotate
{
  return [LayoutManager sharedManager].shouldAutorotate;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (UIInterfaceOrientationMask) supportedInterfaceOrientations
{
  return [LayoutManager sharedManager].supportedInterfaceOrientations;
}

#pragma mark - View hierarchy setup and removal

// -----------------------------------------------------------------------------
/// @brief Sets up the view hierarchy and installs Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.mainApplicationViewController.view];
  self.mainApplicationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.autoLayoutConstraints = [AutoLayoutUtility fillSuperview:self.view withSubview:self.mainApplicationViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Removes subviews and Auto Layout constraints.
// -----------------------------------------------------------------------------
- (void) removeViewHierarchy
{
  [self.view removeConstraints:self.autoLayoutConstraints];
  [self.mainApplicationViewController.view removeFromSuperview];
}

#pragma mark - MagnifyingGlassOwner overrides

// -----------------------------------------------------------------------------
/// @brief MagnifyingGlassOwner method.
// -----------------------------------------------------------------------------
- (void) enableMagnifyingGlass:(id<MagnifyingViewControllerDelegate>)magnifyingViewControllerDelegate
{
  if (self.magnifyingGlassEnabled)
    return;
  self.magnifyingGlassEnabled = true;
  self.magnifyingViewController = [[[MagnifyingViewController alloc] init] autorelease];
  self.magnifyingViewController.magnifyingViewControllerDelegate = magnifyingViewControllerDelegate;
  // MagnifyingViewController manages the frame
  [self.view addSubview:self.magnifyingViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief MagnifyingGlassOwner method.
// -----------------------------------------------------------------------------
- (void) disableMagnifyingGlass
{
  if (! self.magnifyingGlassEnabled)
    return;
  self.magnifyingGlassEnabled = false;
  [self.magnifyingViewController.view removeFromSuperview];
  self.magnifyingViewController = nil;
}

@end
