// -----------------------------------------------------------------------------
// Copyright 2023 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewIntegration.h"
#import "../model/NodeTreeViewModel.h"
#import "../nodetreeview/NodeTreeViewController.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewIntegration.
// -----------------------------------------------------------------------------
@interface NodeTreeViewIntegration()
@property(nonatomic, retain) ResizableStackViewController* resizableStackViewController;
@property(nonatomic, retain) NodeTreeViewModel* nodeTreeViewModel;
@property(nonatomic, retain) UiSettingsModel* uiSettingsModel;
@property(nonatomic, assign) bool interfaceOrientationIsPortrait;
@property(nonatomic, retain) UIViewController* resizablePane2ViewController;
@property(nonatomic, retain) NodeTreeViewController* nodeTreeViewController;
@end


@implementation NodeTreeViewIntegration

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewIntegration object.
///
/// @note This is the designated initializer of NodeTreeViewIntegration.
// -----------------------------------------------------------------------------
- (id) initWithResizableStackViewController:(ResizableStackViewController*)resizableStackViewController
                          nodeTreeViewModel:(NodeTreeViewModel*)nodeTreeViewModel
                            uiSettingsModel:(UiSettingsModel*)uiSettingsModel
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.resizableStackViewController = resizableStackViewController;
  self.nodeTreeViewModel = nodeTreeViewModel;
  self.uiSettingsModel = uiSettingsModel;

  // Determine the interface orientation which the NodeTreeViewIntegration
  // object manages only once and keep it static afterwards. If it were
  // determined dynamically by resizableStackViewController:viewSizesDidChange:
  // then there would be a potential that the wrong interface orientation would
  // be determined. Specifically, if a resize gesture is in progress and the
  // device changes the interface orientation => the gesture is cancelled, but
  // resizableStackViewController:viewSizesDidChange: is still invoked; at the
  // time the new interface orientation is already in effect, which would cause
  // resizableStackViewController:viewSizesDidChange: to write to the wrong
  // user preference.
  self.interfaceOrientationIsPortrait = [UiElementMetrics interfaceOrientationIsPortrait];

  self.resizablePane2ViewController = nil;
  self.nodeTreeViewController = nil;

  self.resizableStackViewController.delegate = self;
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"displayNodeTreeView" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewIntegration object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (self.nodeTreeViewController)
    [self removeNodeTreeView];

  self.resizableStackViewController.delegate = nil;
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"displayNodeTreeView"];

  self.resizablePane2ViewController = nil;
  self.nodeTreeViewModel = nil;
  self.uiSettingsModel = nil;
  self.resizablePane2ViewController = nil;
  self.nodeTreeViewController = nil;

  [super dealloc];
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Performs the initial node tree view integration if the user
/// preference "display node tree view" indicates that the node tree view
/// should be displayed. Does nothing if the user preference indicates that the
/// node tree view should not be displayed.
// -----------------------------------------------------------------------------
- (void) performIntegration
{
  [self setupOrRemoveNodeTreeView];
}

// -----------------------------------------------------------------------------
/// @brief Updates the color styling of the node tree view to match the current
/// UIUserInterfaceStyle (light/dark mode).
// -----------------------------------------------------------------------------
- (void) updateColors
{
  if (self.nodeTreeViewController)
    [self updateColors:self.nodeTreeViewController.traitCollection];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"displayNodeTreeView"])
    [self setupOrRemoveNodeTreeView];
}

#pragma mark - Setup/remove node tree view

// -----------------------------------------------------------------------------
/// @brief Sets up the node tree view or removes it, as described in the class
/// documentation.
// -----------------------------------------------------------------------------
- (void) setupOrRemoveNodeTreeView
{
  bool shouldDisplayNodeTreeView = self.nodeTreeViewModel.displayNodeTreeView;
  bool nodeTreeViewIsCurrentlyDisplayed = self.nodeTreeViewController != nil;
  if (nodeTreeViewIsCurrentlyDisplayed == shouldDisplayNodeTreeView)
    return;

  if (shouldDisplayNodeTreeView)
    [self setupNodeTreeView];
  else
    [self removeNodeTreeView];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the node tree view in the view hierarchy and in Auto Layout.
// -----------------------------------------------------------------------------
- (void) setupNodeTreeView
{
  self.resizablePane2ViewController = [[[UIViewController alloc] initWithNibName:nil bundle:nil] autorelease];

  self.nodeTreeViewController = [[[NodeTreeViewController alloc] initWithModel:self.nodeTreeViewModel
                                                                darkBackground:false] autorelease];

  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureResizableStackViewController];
  [self configureViews];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNodeTreeView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.resizablePane2ViewController.view addSubview:self.nodeTreeViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNodeTreeView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  UIView* nodeTreeView = self.nodeTreeViewController.view;
  nodeTreeView.translatesAutoresizingMaskIntoConstraints = NO;

  viewsDictionary[@"nodeTreeView"] = nodeTreeView;

  [visualFormats addObject:@"H:|-0-[nodeTreeView]-0-|"];
  [visualFormats addObject:@"V:|-0-[nodeTreeView]-0-|"];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:nodeTreeView.superview];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNodeTreeView.
// -----------------------------------------------------------------------------
- (void) configureResizableStackViewController
{
  // Add the new resizable pane at the end
  NSMutableArray* resizablePaneViewControllers = [NSMutableArray arrayWithArray:self.resizableStackViewController.viewControllers];
  [resizablePaneViewControllers addObject:self.resizablePane2ViewController];
  self.resizableStackViewController.viewControllers = resizablePaneViewControllers;

  if (self.interfaceOrientationIsPortrait)
    self.resizableStackViewController.sizes = self.uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlayPortrait;
  else
    self.resizableStackViewController.sizes = self.uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlayLandscape;

  NSNumber* uiAreaPlayResizablePaneMinimumSizeAsNumber = [NSNumber numberWithDouble:uiAreaPlayResizablePaneMinimumSize];
  self.resizableStackViewController.minimumSizes = @[uiAreaPlayResizablePaneMinimumSizeAsNumber, uiAreaPlayResizablePaneMinimumSizeAsNumber];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupNodeTreeView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  [self updateColors:self.nodeTreeViewController.traitCollection];
}

// -----------------------------------------------------------------------------
/// @brief Removes the node tree view from the view hierarchy and from
/// Auto Layout.
// -----------------------------------------------------------------------------
- (void) removeNodeTreeView
{
  NSMutableArray* resizablePaneViewControllers = [NSMutableArray arrayWithArray:self.resizableStackViewController.viewControllers];
  [resizablePaneViewControllers removeObject:self.resizablePane2ViewController];
  self.resizableStackViewController.viewControllers = resizablePaneViewControllers;

  [self.nodeTreeViewController.view removeFromSuperview];
  self.nodeTreeViewController = nil;

  self.resizablePane2ViewController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setNodeTreeViewController:(NodeTreeViewController*)nodeTreeViewController
{
  if (_nodeTreeViewController == nodeTreeViewController)
    return;
  if (_nodeTreeViewController)
  {
    [_nodeTreeViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_nodeTreeViewController removeFromParentViewController];
    [_nodeTreeViewController release];
    _nodeTreeViewController = nil;
  }
  if (nodeTreeViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self.resizablePane2ViewController addChildViewController:nodeTreeViewController];
    [nodeTreeViewController didMoveToParentViewController:self.resizablePane2ViewController];
    [nodeTreeViewController retain];
    _nodeTreeViewController = nodeTreeViewController;
  }
}

#pragma mark - ResizableStackViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ResizableStackViewControllerDelegate method.
// -----------------------------------------------------------------------------
- (void) resizableStackViewController:(ResizableStackViewController*)controller
                   viewSizesDidChange:(NSArray*)newSizes;
{
  if (self.interfaceOrientationIsPortrait)
    self.uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlayPortrait = newSizes;
  else
    self.uiSettingsModel.resizableStackViewControllerInitialSizesUiAreaPlayLandscape = newSizes;
}

#pragma mark - User interface style handling (light/dark mode)

// -----------------------------------------------------------------------------
/// @brief Updates the color styling of the node tree view to match the
/// UIUserInterfaceStyle (light/dark mode) provided by @a traitCollection.
// -----------------------------------------------------------------------------
- (void) updateColors:(UITraitCollection*)traitCollection
{
  if (self.nodeTreeViewController)
    [UiUtilities applyTransparentStyleToView:self.nodeTreeViewController.view traitCollection:traitCollection];
}

@end
