// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "SplitViewController.h"
#import "AutoLayoutUtility.h"
#import "UiElementMetrics.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SplitViewController.
// -----------------------------------------------------------------------------
@interface SplitViewController()
@property (nonatomic, retain) UIView* dividerView;
@property (nonatomic, retain) UIBarButtonItem* barButtonItemLeftPane;
@property (nonatomic, assign) bool leftPaneIsShownInOverlay;
@property (nonatomic, retain) UIView* overlayView;
@property (nonatomic, retain) NSLayoutConstraint* leftPaneLeftEdgeConstraint;
@property (nonatomic, assign) bool viewsAreInPortraitOrientation;
@property (nonatomic, retain) NSArray* autoLayoutConstraints;
@end


@implementation SplitViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an SplitViewController object.
///
/// @note This is the designated initializer of SplitViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.viewControllers = [NSArray array];
  self.delegate = nil;
  self.dividerView = nil;
  self.barButtonItemLeftPane = nil;
  self.leftPaneIsShownInOverlay = false;
  self.overlayView = nil;
  self.leftPaneLeftEdgeConstraint = nil;
  self.viewsAreInPortraitOrientation = true;
  self.autoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SplitViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  // First, let the property setter get rid of all child view controllers and
  // their subviews
  self.viewControllers = [NSArray array];
  // Second, get rid of the NSArray object. We can't use the property setter
  // for that because it contains a guard against setting a nil value.
  if (_viewControllers)
  {
    [_viewControllers release];
    _viewControllers = nil;
  }
  self.delegate = nil;
  self.dividerView = nil;
  self.barButtonItemLeftPane = nil;
  self.overlayView = nil;
  self.leftPaneLeftEdgeConstraint = nil;
  self.autoLayoutConstraints = nil;
  [super dealloc];
}

#pragma mark - View controller handling

// -----------------------------------------------------------------------------
/// @brief Setter for public @e viewControllers property.
// -----------------------------------------------------------------------------
- (void) setViewControllers:(NSArray*)viewControllers
{
  if (viewControllers == _viewControllers)
    return;
  if (! viewControllers)
  {
    // This check exists because the rest of the implementation of this
    // controller is simpler if it can rely on the property always containing
    // a valid NSArray object (even if it is empty)
    NSString* errorMessage = @"viewControllers argument must not be nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  if (viewControllers.count > 0 && viewControllers.count != 2)
  {
    NSString* errorMessage = @"viewControllers must contain 0 or 2 elements";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }

  [self removeChildViewControllers];
  if (self.isViewLoaded)
  {
    if (self.leftPaneIsShownInOverlay)
      [self dismissLeftPaneInOverlay];
    [self removeAutoLayoutConstraints];
    [self removeViewHierarchy];
    [self removeBarButtonItem];
  }

  [_viewControllers release];
  _viewControllers = [[NSArray alloc] initWithArray:viewControllers];

  [self setupChildViewControllers:_viewControllers];
  if (self.isViewLoaded)
  {
    [self updateViewHierarchyForInterfaceOrientation:self.interfaceOrientation];
    [self updateAutoLayoutConstraintsForInterfaceOrientation:self.interfaceOrientation];
    [self updateBarButtonItemForInterfaceOrientation:self.interfaceOrientation];
    [self viewLayoutDidChangeToInterfaceOrientation:self.interfaceOrientation];
  }
}

// -----------------------------------------------------------------------------
/// @brief Adds all view controllers in @a viewControllers as child view
/// controllers to this controller.
// -----------------------------------------------------------------------------
- (void) setupChildViewControllers:(NSArray*)viewControllers
{
  for (UIViewController* controller in viewControllers)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all child view controllers from this controller.
// -----------------------------------------------------------------------------
- (void) removeChildViewControllers
{
  for (UIViewController* controller in self.childViewControllers)
  {
    [controller willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [controller removeFromParentViewController];
  }
}

#pragma mark - Internal accessors for left/right pane controllers and their views

// -----------------------------------------------------------------------------
/// @brief The view controller that manages the left pane. Can be nil if this
/// split view controller is not configured with any view controllers.
// -----------------------------------------------------------------------------
- (UIViewController*) leftPaneViewController
{
  if (_viewControllers.count < 1)
    return nil;
  return [_viewControllers objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief The view controller that manages the right pane. Can be nil if this
/// split view controller is not configured with any view controllers.
// -----------------------------------------------------------------------------
- (UIViewController*) rightPaneViewController
{
  if (_viewControllers.count < 2)
    return nil;
  return [_viewControllers objectAtIndex:1];
}

// -----------------------------------------------------------------------------
/// @brief The view that is displayed in the left pane. Can be nil if this
/// split view controller is not configured with any view controllers.
// -----------------------------------------------------------------------------
- (UIView*) leftPaneView
{
  UIViewController* leftPaneViewController = [self leftPaneViewController];
  if (leftPaneViewController)
    return leftPaneViewController.view;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief The view that is displayed in the right pane. Can be nil if this
/// split view controller is not configured with any view controllers.
// -----------------------------------------------------------------------------
- (UIView*) rightPaneView
{
  UIViewController* rightPaneViewController = [self rightPaneViewController];
  if (rightPaneViewController)
    return rightPaneViewController.view;
  else
    return nil;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  self.view.backgroundColor = [UIColor clearColor];
  self.dividerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.dividerView.backgroundColor = [UIColor blackColor];

  [self updateViewHierarchyForInterfaceOrientation:self.interfaceOrientation];
  [self updateAutoLayoutConstraintsForInterfaceOrientation:self.interfaceOrientation];
  [self updateBarButtonItemForInterfaceOrientation:self.interfaceOrientation];
  [self viewLayoutDidChangeToInterfaceOrientation:self.interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillLayoutSubviews
{
  if ([self isViewLayoutChangeRequiredForInterfaceOrientation:self.interfaceOrientation])
  {
    [self prepareForInterfaceOrientationChange:self.interfaceOrientation];
    [self completeInterfaceOrientationChange:self.interfaceOrientation];
    [self viewLayoutDidChangeToInterfaceOrientation:self.interfaceOrientation];
  }
}

#pragma mark - Interface orientation change handling

// -----------------------------------------------------------------------------
/// @brief Returns true if rotating to the specified interface orientation
/// requires a change to the view layout of this SplitViewController.
// -----------------------------------------------------------------------------
- (bool) isViewLayoutChangeRequiredForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool newOrientationIsPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  return (self.viewsAreInPortraitOrientation != newOrientationIsPortraitOrientation);
}

// -----------------------------------------------------------------------------
/// @brief Updates the internal state of this SplitViewController to remember
/// that the current view layout now matches @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (void) viewLayoutDidChangeToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  self.viewsAreInPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

// -----------------------------------------------------------------------------
/// @brief Prepares this SplitViewController for an upcoming interface
/// orientation change. The new orientation is @a interfaceOrientation.
///
/// This method should only be invoked if
/// isViewLayoutChangeRequiredForInterfaceOrientation:() returns true for the
/// specified interface orientation.
///
/// This method was originally invoked by
/// willRotateToInterfaceOrientation:duration:() as the first step of a two-step
/// orientation change. Clients that invoke this method must also call
/// completeInterfaceOrientationChange:() to perform the second step of the
/// orientation change.
// -----------------------------------------------------------------------------
- (void) prepareForInterfaceOrientationChange:(UIInterfaceOrientation)interfaceOrientation
{
  // Dismiss the left pane if it is currently shown in an overlay. This is
  // important so that the left pane view can be integrated into the regular
  // landscape view herarchy.
  if (self.leftPaneIsShownInOverlay)
    [self dismissLeftPaneInOverlay];

  // Invoke this so that the delegate is notified before the left pane is
  // actually shown/hidden
  [self updateBarButtonItemForInterfaceOrientation:interfaceOrientation];

  // Remove constraints before views are resized (at the time
  // willAnimateRotationToInterfaceOrientation:duration:() is invoked it is too
  // late, views are already resized to match the new interface orientation). If
  // we don't remove constraints here, Auto Layout will have trouble resizing
  // views (although the reason why is unknown).
  [self removeAutoLayoutConstraints];
  // Since we don't have any constraints anymore, we must also remove the view
  // hierarchy
  [self removeViewHierarchy];
}

// -----------------------------------------------------------------------------
/// @brief Completes the interface orientation change that was begun when
/// prepareForInterfaceOrientationChange:() was invoked. The new orientation is
/// @a interfaceOrientation.
///
/// This method should only be invoked if
/// isViewLayoutChangeRequiredForInterfaceOrientation:() returns true for the
/// specified interface orientation.
///
/// This method was originally invoked by
/// willAnimateRotationToInterfaceOrientation:duration:() as the second step of
/// a two-step orientation change. Clients that invoke this method must have
/// previously also called prepareForInterfaceOrientationChange:() to perform
/// the first step of the orientation change.
// -----------------------------------------------------------------------------
- (void) completeInterfaceOrientationChange:(UIInterfaceOrientation)interfaceOrientation
{
  [self updateViewHierarchyForInterfaceOrientation:interfaceOrientation];
  [self updateAutoLayoutConstraintsForInterfaceOrientation:interfaceOrientation];
}

#pragma mark - View hierarchy handling

// -----------------------------------------------------------------------------
/// @brief Updates the view hierarchy managed by this split view controller to
/// match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) updateViewHierarchyForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  UIView* leftPaneView = [self leftPaneView];
  UIView* rightPaneView = [self rightPaneView];
  if (! leftPaneView || ! rightPaneView)
    return;

  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    if (self.dividerView.superview)
      [self.dividerView removeFromSuperview];
    if (leftPaneView.superview)
      [leftPaneView removeFromSuperview];
    if (! rightPaneView.superview)
      [self.view addSubview:rightPaneView];
  }
  else
  {
    if (! self.dividerView.superview)
      [self.view addSubview:self.dividerView];
    if (! leftPaneView.superview)
      [self.view addSubview:leftPaneView];
    if (! rightPaneView.superview)
      [self.view addSubview:rightPaneView];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all subviews from the view of this split view controller.
// -----------------------------------------------------------------------------
- (void) removeViewHierarchy
{
  for (UIView* subview in self.view.subviews)
    [subview removeFromSuperview];
}

#pragma mark - Auto layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Sets up the auto layout constraints of the view of this split view
/// controller to match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) updateAutoLayoutConstraintsForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  UIView* leftPaneView = [self leftPaneView];
  UIView* rightPaneView = [self rightPaneView];
  if (! leftPaneView || ! rightPaneView)
    return;

  // Only remove constraints that we generated. UIKit may also have generated
  // some constraints, those we must not touch.
  if (self.autoLayoutConstraints)
  {
    [self.view removeConstraints:self.autoLayoutConstraints];
    self.autoLayoutConstraints = nil;
  }

  self.dividerView.translatesAutoresizingMaskIntoConstraints = NO;
  leftPaneView.translatesAutoresizingMaskIntoConstraints = NO;
  rightPaneView.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.dividerView, @"dividerView",
                                   leftPaneView, @"leftPaneView",
                                   rightPaneView, @"rightPaneView",
                                   nil];

  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    NSArray* visualFormats = [NSArray arrayWithObjects:
                              @"H:|-0-[rightPaneView]-0-|",
                              @"V:|-0-[rightPaneView]-0-|",
                              nil];
    self.autoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                               withViews:viewsDictionary
                                                                  inView:self.view];
  }
  else
  {
    NSArray* visualFormats = [NSArray arrayWithObjects:
                              [NSString stringWithFormat:@"H:|-0-[leftPaneView(==%d)]-0-[dividerView(==0)]-0-[rightPaneView]-0-|", [UiElementMetrics splitViewControllerLeftPaneWidth]],
                              @"V:|-0-[dividerView]-0-|",
                              @"V:|-0-[leftPaneView]-0-|",
                              @"V:|-0-[rightPaneView]-0-|",
                              nil];
    self.autoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                               withViews:viewsDictionary
                                                                  inView:self.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all auto layout constraints from the view of this split view
/// controller.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  // Only remove constraints that we generated. UIKit may also have generated
  // some constraints, those we must not touch.
  if (self.autoLayoutConstraints)
  {
    [self.view removeConstraints:self.autoLayoutConstraints];
    self.autoLayoutConstraints = nil;
  }
}

#pragma mark - Bar button item handling

// -----------------------------------------------------------------------------
/// @brief Sets up the bar button item used to display the left pane of this
/// split view controller to match the specified interface orientation.
// -----------------------------------------------------------------------------
- (void) updateBarButtonItemForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isPortraitOrientation = UIInterfaceOrientationIsPortrait(interfaceOrientation);
  if (isPortraitOrientation)
  {
    self.barButtonItemLeftPane = [[[UIBarButtonItem alloc] initWithTitle:nil
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(showLeftPaneInOverlay:)] autorelease];
    if (self.delegate)
    {
      [self.delegate splitViewController:self
                  willHideViewController:[self leftPaneViewController]
                       withBarButtonItem:self.barButtonItemLeftPane];
    }
  }
  else
  {
    if (self.delegate)
    {
      [self.delegate splitViewController:self
                  willShowViewController:[self leftPaneViewController]
               invalidatingBarButtonItem:self.barButtonItemLeftPane];
    }
    self.barButtonItemLeftPane = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes the bar button item used to display the left pane of this
/// split view controller.
// -----------------------------------------------------------------------------
- (void) removeBarButtonItem
{
  if (! self.barButtonItemLeftPane)
    return;
  if (self.delegate)
  {
    [self.delegate splitViewController:self
                willShowViewController:[self leftPaneViewController]
             invalidatingBarButtonItem:self.barButtonItemLeftPane];
  }
  self.barButtonItemLeftPane = nil;
}

#pragma mark - Show/dismiss left pane in overlay view

// -----------------------------------------------------------------------------
/// @brief Displays the left pane of this split view controller in an overlay
/// view. The change is animated. If the user taps anywhere in the area not
/// covered by the left pane, the overlay view is dismissed.
// -----------------------------------------------------------------------------
- (void) showLeftPaneInOverlay:(id)sender
{
  if (self.leftPaneIsShownInOverlay)
    return;
  UIView* leftPaneView = [self leftPaneView];
  if (! leftPaneView)
    return;
  if (leftPaneView.superview)
    return;
  self.leftPaneIsShownInOverlay = true;

  leftPaneView.layer.borderWidth = 1.0f;
  leftPaneView.layer.cornerRadius = 3.0f;

  // The overlay view makes sure that no touches get through to the right pane
  // covered by the overlay.
  self.overlayView = [[[UIView alloc] initWithFrame:self.view.bounds] autorelease];
  [self.view addSubview:self.overlayView];

  // A transparent view is laid out to the right of the left pane. A gesture
  // recognizer makes sure that tap gestures trigger dismissal of the overlay
  // view
  UIView* transparentRightPaneView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  UIGestureRecognizer* tapGestureRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
  [transparentRightPaneView addGestureRecognizer:tapGestureRecognizer];

  [self.overlayView addSubview:leftPaneView];
  [self.overlayView addSubview:transparentRightPaneView];

  transparentRightPaneView.translatesAutoresizingMaskIntoConstraints = NO;
  leftPaneView.translatesAutoresizingMaskIntoConstraints = NO;
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   leftPaneView, @"leftPaneView",
                                   transparentRightPaneView, @"transparentRightPaneView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:[leftPaneView(==%d)]-0-[transparentRightPaneView]-0-|", [UiElementMetrics splitViewControllerLeftPaneWidth]],
                            @"V:|-0-[leftPaneView]-0-|",
                            @"V:|-0-[transparentRightPaneView]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.overlayView];

  // This constraint is used to animate the showing/dismissal of the left pane
  self.leftPaneLeftEdgeConstraint = [NSLayoutConstraint constraintWithItem:leftPaneView
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.overlayView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0f
                                                                  constant:-[UiElementMetrics splitViewControllerLeftPaneWidth]];
  [self.overlayView addConstraint:self.leftPaneLeftEdgeConstraint];

  // First layout pass that will place the left pane outside of the visible
  // area
  [self.view layoutIfNeeded];
  // Second layout pass slides in the left pane
  [UIView animateWithDuration:0.2 animations:^{
    self.leftPaneLeftEdgeConstraint.constant = 0;
    [self.overlayView layoutIfNeeded];
  }];
}

// -----------------------------------------------------------------------------
/// @brief Dismisses the left pane of this split view controller that is
/// currently displayed in an overlay view. The change is animated.
// -----------------------------------------------------------------------------
- (void) dismissLeftPaneInOverlayWithAnimation
{
  if (! self.leftPaneIsShownInOverlay)
    return;
  [UIView animateWithDuration:0.2
                   animations:^{
                     self.leftPaneLeftEdgeConstraint.constant = -[UiElementMetrics splitViewControllerLeftPaneWidth];
                     [self.overlayView layoutIfNeeded];
                   }
                   completion:^(BOOL finished){
                     [self dismissLeftPaneInOverlay];
                   }];
}

// -----------------------------------------------------------------------------
/// @brief Dismisses the left pane of this split view controller that is
/// currently displayed in an overlay view. The change is @b NOT animated.
// -----------------------------------------------------------------------------
- (void) dismissLeftPaneInOverlay
{
  if (! self.leftPaneIsShownInOverlay)
    return;
  self.leftPaneIsShownInOverlay = false;

  UIView* leftPaneView = [self leftPaneView];
  if (! leftPaneView)
    return;
  if (! leftPaneView.superview)
    return;

  [leftPaneView removeFromSuperview];
  leftPaneView.layer.borderWidth = 0.0f;
  leftPaneView.layer.cornerRadius = 0.0f;

  self.leftPaneLeftEdgeConstraint = nil;

  // Important because this decreases the retain count
  [self.overlayView removeFromSuperview];

  // Releases not only the view, but all the other objects
  // that were allocated by showLeftPaneInOverlay
  // (constraints, gesture recognizer)
  self.overlayView = nil;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user tapping in the area not covered by the left pane.
/// Dismisses the left pane. The change is animated.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  [self dismissLeftPaneInOverlayWithAnimation];
}

@end
