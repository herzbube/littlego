// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "PageViewController.h"
#import "AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PageViewController.
// -----------------------------------------------------------------------------
@interface PageViewController()
/// @brief True if the controller object is in the process of deallocating.
@property (nonatomic, assign) bool deallocating;
@property (nonatomic, assign) bool animationIsInProgress;
@property (nonatomic, assign) NSInteger indexOfCurrentPage;
@property (nonatomic, copy) NSArray* viewControllers;
@property (nonatomic, assign) UIViewController* initialViewController;
@property (nonatomic, retain) UIPageControl* pageControl;
@property (nonatomic, retain) UISwipeGestureRecognizer* swipeLeftGestureRecognizer;
@property (nonatomic, retain) UISwipeGestureRecognizer* swipeRightGestureRecognizer;
@property (nonatomic, retain) NSMutableArray* autoLayoutConstraints;
@property (nonatomic, retain) NSLayoutConstraint* leftEdgeConstraint;
@property (nonatomic, retain) NSLayoutConstraint* widthConstraint;
@end


@implementation PageViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a PageViewController configured
/// to display @a viewControllers. The initial view controller being displayed
/// is the first element in @a viewControllers.
// -----------------------------------------------------------------------------
+ (PageViewController*) pageViewControllerWithViewControllers:(NSArray*)viewControllers
{
  PageViewController* pageViewController = [[[PageViewController alloc] init] autorelease];
  pageViewController.viewControllers = viewControllers;
  if (viewControllers.count > 0)
    pageViewController.initialViewController = [viewControllers objectAtIndex:0];
  return pageViewController;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a PageViewController configured
/// to display @a viewControllers. The initial view controller being displayed
/// is the first element in @a viewControllers.
// -----------------------------------------------------------------------------
+ (PageViewController*) pageViewControllerWithViewControllers:(NSArray*)viewControllers
                                        initialViewController:(UIViewController*)initialViewController
{
  PageViewController* pageViewController = [[[PageViewController alloc] init] autorelease];
  pageViewController.viewControllers = viewControllers;
  pageViewController.initialViewController = initialViewController;
  return pageViewController;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an PageViewController object.
///
/// @note This is the designated initializer of PageViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.delegate = nil;
  self.initialViewController = nil;

  // The default value is an arbitrary value that was experimentally determined
  // to look good
  self.slideAnimationDurationInSeconds = 0.3;
  self.pageControlTintColor = nil;
  self.pageControlPageIndicatorTintColor = nil;
  self.pageControlCurrentPageIndicatorTintColor = nil;
  self.pageControlHeight = -1;
  self.pageControlVerticalSpacing = -1;
  if (@available(iOS 14, *))
    self.pageControlBackgroundStyle = UIPageControlBackgroundStyleAutomatic;

  self.deallocating = false;
  self.animationIsInProgress = false;
  self.indexOfCurrentPage = -1;
  self.viewControllers = [NSArray array];
  self.pageControl = nil;
  self.swipeLeftGestureRecognizer = nil;
  self.swipeRightGestureRecognizer = nil;
  self.autoLayoutConstraints = nil;
  self.leftEdgeConstraint = nil;
  self.widthConstraint = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PageViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.deallocating = true;

  self.delegate = nil;
  self.initialViewController = nil;

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

  self.pageControl = nil;
  self.swipeLeftGestureRecognizer = nil;
  self.swipeRightGestureRecognizer = nil;
  self.autoLayoutConstraints = nil;
  self.leftEdgeConstraint = nil;
  self.widthConstraint = nil;

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

  [self removeChildViewControllers];
  if (self.isViewLoaded)
  {
    if (self.indexOfCurrentPage >= 0)
    {
      [self removeAutoLayoutConstraints];
      [self removePageFromViewHierarchy:self.indexOfCurrentPage];
    }
  }

  [_viewControllers release];
  _viewControllers = [[NSArray alloc] initWithArray:viewControllers];

  [self setupChildViewControllers:_viewControllers];
  if (self.isViewLoaded && !self.deallocating)
  {
    [self setupInitialPage];
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

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  // When swipes are animated pages are moving in from outside our view's bounds
  // and moving out from our view's bounds. We don't want to show whatever is
  // happening outside of our view's bounds.
  self.view.clipsToBounds = YES;

  // One-time setup
  [self setupGestureRecognizers];
  [self setupPageControl];

  // Setup that needs to be repeated when view controllers change
  [self setupInitialPage];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupGestureRecognizers
{
  self.swipeLeftGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeftFrom:)] autorelease];
  self.swipeLeftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
  [self.view addGestureRecognizer:self.swipeLeftGestureRecognizer];

  self.swipeRightGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRightFrom:)] autorelease];
  self.swipeRightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
  [self.view addGestureRecognizer:self.swipeRightGestureRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupPageControl
{
  self.pageControl = [[[UIPageControl alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.pageControl];

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  self.pageControl.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"pageControl"] = self.pageControl;
  [visualFormats addObject:@"H:|-0-[pageControl]-0-|"];
  if (self.pageControlHeight >= 0)
    [visualFormats addObject:[NSString stringWithFormat:@"V:[pageControl(==%d)]-0-|", self.pageControlHeight]];
  else
    [visualFormats addObject:@"V:[pageControl]-0-|"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.pageControl.superview];

  if (self.pageControlTintColor)
    self.pageControl.tintColor = self.pageControlTintColor;

  if (self.pageControlPageIndicatorTintColor)
    self.pageControl.pageIndicatorTintColor = self.pageControlPageIndicatorTintColor;
  
  if (self.pageControlCurrentPageIndicatorTintColor)
    self.pageControl.currentPageIndicatorTintColor = self.pageControlCurrentPageIndicatorTintColor;
  
  if (@available(iOS 14, *))
    self.pageControl.backgroundStyle = self.pageControlBackgroundStyle;

  [self.pageControl addTarget:self
                       action:@selector(pageChanged:)
             forControlEvents:UIControlEventValueChanged];
}

#pragma mark - Initialization when view controllers change

// -----------------------------------------------------------------------------
/// @brief Sets up the initial page. Needs to be invoked after the view
/// controllers change.
// -----------------------------------------------------------------------------
- (void) setupInitialPage
{
  if (self.initialViewController)
  {
    [self notifyDelegateWillHideViewController:nil
                        willShowViewController:self.initialViewController];

    self.indexOfCurrentPage = [self.viewControllers indexOfObject:self.initialViewController];
  }
  else
  {
    self.indexOfCurrentPage = -1;
  }

  [self configurePageControlToMatchContent];
  [self addInitialPageToViewHierarchyIfAny];

  if (self.initialViewController)
  {
    [self notifyDelegateDidHideViewController:nil
                        didShowViewController:self.initialViewController];
  }
}

// -----------------------------------------------------------------------------
/// @brief Configures the page control to match the current number of pages
/// provided by view controllers.
// -----------------------------------------------------------------------------
- (void) configurePageControlToMatchContent
{
  self.pageControl.numberOfPages = self.numberOfPages;

  if (self.indexOfCurrentPage == -1)
    self.pageControl.currentPage = 0;  // cannot go below 0
  else
    self.pageControl.currentPage = self.indexOfCurrentPage;
}

// -----------------------------------------------------------------------------
/// @brief Adds the initial page (if there is one) to the view hierarchy. Needs
/// to be invoked after the view controllers change.
// -----------------------------------------------------------------------------
- (void) addInitialPageToViewHierarchyIfAny
{
  if (self.indexOfCurrentPage == -1)
    return;

  [self addPageToViewHierarchy:self.indexOfCurrentPage];
  [self setupAutoLayoutConstraintsForPage:self.indexOfCurrentPage];
}

#pragma mark - Add/remove pages to/from view hierarchy

// -----------------------------------------------------------------------------
/// @brief Adds the page view specified by @a indexOfPage to the view hierarchy
/// of this view controller.
// -----------------------------------------------------------------------------
- (void) addPageToViewHierarchy:(NSInteger)indexOfPage
{
  UIView* pageView = [self pageViewAtIndex:indexOfPage];
  [self.view addSubview:pageView];
}

// -----------------------------------------------------------------------------
/// @brief Removes the page view specified by @a indexOfPage from the view
/// hierarchy of this view controller.
// -----------------------------------------------------------------------------
- (void) removePageFromViewHierarchy:(NSInteger)indexOfPage
{
  UIView* pageView = [self pageViewAtIndex:indexOfPage];
  [pageView removeFromSuperview];
}

#pragma mark - Auto layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Sets up the auto layout constraints for the page view specified by
/// @a indexOfPage
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraintsForPage:(NSInteger)indexOfPage
{
  UIView* pageView = [self pageViewAtIndex:indexOfPage];

  self.autoLayoutConstraints = [NSMutableArray array];
  NSArray* autoLayoutConstraints;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  int pageControlVerticalSpacing = 4;
  if (self.pageControlVerticalSpacing >= 0)
    pageControlVerticalSpacing = self.pageControlVerticalSpacing;

  pageView.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"pageView"] = pageView;
  viewsDictionary[@"pageControl"] = self.pageControl;
  [visualFormats addObject:[NSString stringWithFormat:@"V:|-0-[pageView]-%d-[pageControl]", pageControlVerticalSpacing]];
  autoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.pageControl.superview];
  [self.autoLayoutConstraints addObjectsFromArray:autoLayoutConstraints];

  self.leftEdgeConstraint = [AutoLayoutUtility alignFirstView:pageView
                                               withSecondView:self.view
                                                  onAttribute:NSLayoutAttributeLeft
                                             constraintHolder:self.view];
  [self.autoLayoutConstraints addObject:self.leftEdgeConstraint];
  self.widthConstraint = [AutoLayoutUtility alignFirstView:pageView
                                            withSecondView:self.view
                                               onAttribute:NSLayoutAttributeWidth
                                          constraintHolder:self.view];
  [self.autoLayoutConstraints addObject:self.widthConstraint];
}

// -----------------------------------------------------------------------------
/// @brief Removes the currently installed page view auto layout constraints.
// -----------------------------------------------------------------------------
- (void) removeAutoLayoutConstraints
{
  if (self.autoLayoutConstraints)
  {
    [self.view removeConstraints:self.autoLayoutConstraints];
    self.autoLayoutConstraints = nil;

    self.leftEdgeConstraint = nil;
    self.widthConstraint = nil;
  }
}

#pragma mark - Page management

// -----------------------------------------------------------------------------
/// @brief Returns the number of pages managed by the PageViewController.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfPages
{
  return self.viewControllers.count;
}

// -----------------------------------------------------------------------------
/// @brief Returns the page view at the specified index position @a indexOfPage.
/// Returns @e nil if @a indexOfPage refers to a non-existing page.
// -----------------------------------------------------------------------------
- (UIView*) pageViewAtIndex:(NSInteger)indexOfPage
{
  if (indexOfPage < 0 || indexOfPage > self.numberOfPages)
    return nil;

  UIViewController* pageViewController = [self.viewControllers objectAtIndex:indexOfPage];
  UIView* pageView = pageViewController.view;
  return pageView;
}

#pragma mark - Delegate notifications

// -----------------------------------------------------------------------------
/// @brief Invokes the delegate method
/// pageViewController:willHideViewController:willShowViewController: if a
/// delegate has been configured and it responds to the selector.
// -----------------------------------------------------------------------------
- (void) notifyDelegateWillHideViewController:(UIViewController*)currentViewController
                       willShowViewController:(UIViewController*)nextViewController

{
  if (! self.delegate)
    return;

  SEL selector = @selector(pageViewController:willHideViewController:willShowViewController:);
  if (! [self.delegate respondsToSelector:selector])
    return;

  [self.delegate pageViewController:self
             willHideViewController:currentViewController
             willShowViewController:nextViewController];
}

// -----------------------------------------------------------------------------
/// @brief Invokes the delegate method
/// pageViewController:didHideViewController:didShowViewController: if a
/// delegate has been configured and it responds to the selector.
// -----------------------------------------------------------------------------
- (void) notifyDelegateDidHideViewController:(UIViewController*)currentViewController
                       didShowViewController:(UIViewController*)nextViewController

{
  if (! self.delegate)
    return;

  SEL selector = @selector(pageViewController:didHideViewController:didShowViewController:);
  if (! [self.delegate respondsToSelector:selector])
    return;

  [self.delegate pageViewController:self
              didHideViewController:currentViewController
              didShowViewController:nextViewController];
}

#pragma mark - Gesture handling

// -----------------------------------------------------------------------------
/// @brief Handles a swipe gesture from right-to-left by sliding in a new page
/// on the right-hand side.
// -----------------------------------------------------------------------------
- (void) handleSwipeLeftFrom:(UISwipeGestureRecognizer*)gestureRecognizer
{
  if (self.numberOfPages < 2)
    return;

  NSInteger indexOfNextPage;
  if (self.indexOfCurrentPage == self.numberOfPages - 1)
    indexOfNextPage = 0;
  else
    indexOfNextPage = self.indexOfCurrentPage + 1;

  [self swipeToNextPage:indexOfNextPage swipeDirection:gestureRecognizer.direction];
}

// -----------------------------------------------------------------------------
/// @brief Handles a swipe gesture from left-to-right by sliding in a new page
/// on the left-hand side.
// -----------------------------------------------------------------------------
- (void) handleSwipeRightFrom:(UISwipeGestureRecognizer*)gestureRecognizer
{
  if (self.numberOfPages < 2)
    return;

  NSInteger indexOfNextPage;
  if (self.indexOfCurrentPage == 0)
    indexOfNextPage = self.numberOfPages - 1;
  else
    indexOfNextPage = self.indexOfCurrentPage - 1;

  [self swipeToNextPage:indexOfNextPage swipeDirection:gestureRecognizer.direction];
}

#pragma mark - Page control interaction

// -----------------------------------------------------------------------------
/// @brief Handles a direct interaction with the page control by sliding in a
/// new page corresponding to the page control's @e currentPage property value.
///
/// The direction of the slide animation is derived from the relative location
/// of the new page compared to the current page (e.g. if the new page is to the
/// left of the current page then a left-to-right swipe animation is initiated).
// -----------------------------------------------------------------------------
- (void) pageChanged:(id)sender
{
  if (self.numberOfPages < 2)
    return;

  NSInteger indexOfNextPage = self.pageControl.currentPage;
  if (indexOfNextPage == self.indexOfCurrentPage)
    return;

  UISwipeGestureRecognizerDirection swipeDirection;
  if (indexOfNextPage < self.indexOfCurrentPage)
    swipeDirection = UISwipeGestureRecognizerDirectionRight;
  else
    swipeDirection = UISwipeGestureRecognizerDirectionLeft;

  [self swipeToNextPage:indexOfNextPage swipeDirection:swipeDirection];
}

#pragma mark - Slide animation

// -----------------------------------------------------------------------------
/// @brief Private helper for handleSwipeLeftFrom:() and
/// handleSwipeRightFrom:().
// -----------------------------------------------------------------------------
- (void) swipeToNextPage:(NSInteger)indexOfNextPage
          swipeDirection:(UISwipeGestureRecognizerDirection)swipeDirection
{
  if (self.animationIsInProgress)
    return;
  self.animationIsInProgress = true;

  [self notifyDelegateWillHideViewController:[self.viewControllers objectAtIndex:self.indexOfCurrentPage]
                      willShowViewController:[self.viewControllers objectAtIndex:indexOfNextPage]];

  NSArray* temporaryConstraints = [self createTemporaryConstraintsForSwipeToNextPage:indexOfNextPage
                                                                     fromCurrentPage:self.indexOfCurrentPage
                                                                      swipeDirection:swipeDirection];

  [self animateSlideToNextPage:indexOfNextPage
               fromCurrentPage:self.indexOfCurrentPage
                swipeDirection:swipeDirection
          temporaryConstraints:temporaryConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for swipeToNextPage:swipeDirection:().
// -----------------------------------------------------------------------------
- (NSArray*) createTemporaryConstraintsForSwipeToNextPage:(NSInteger)indexOfNextPage
                                          fromCurrentPage:(NSInteger)indexOfCurrentPage
                                           swipeDirection:(UISwipeGestureRecognizerDirection)swipeDirection
{
  UIView* currentPageView = [self pageViewAtIndex:indexOfCurrentPage];
  UIView* nextPageView = [self pageViewAtIndex:indexOfNextPage];

  NSLayoutAttribute nextPageAttribute;
  NSLayoutAttribute currentPageAttribute;
  if (swipeDirection == UISwipeGestureRecognizerDirectionLeft)
  {
    nextPageAttribute = NSLayoutAttributeLeft;
    currentPageAttribute = NSLayoutAttributeRight;
  }
  else
  {
    nextPageAttribute = NSLayoutAttributeRight;
    currentPageAttribute = NSLayoutAttributeLeft;
  }

  [self.view addSubview:nextPageView];
  nextPageView.translatesAutoresizingMaskIntoConstraints = NO;

  NSLayoutConstraint* placementConstraintX = [NSLayoutConstraint constraintWithItem:nextPageView
                                                                          attribute:nextPageAttribute
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:currentPageView
                                                                          attribute:currentPageAttribute
                                                                         multiplier:1.0f
                                                                           constant:0];
  [self.view addConstraint:placementConstraintX];
  NSLayoutConstraint* placementConstraintY = [AutoLayoutUtility alignFirstView:nextPageView
                                                                withSecondView:currentPageView
                                                                   onAttribute:NSLayoutAttributeTop
                                                              constraintHolder:self.view];
  NSLayoutConstraint* sizeConstraintWidth = [AutoLayoutUtility alignFirstView:nextPageView
                                                               withSecondView:currentPageView
                                                                  onAttribute:NSLayoutAttributeWidth
                                                             constraintHolder:self.view];
  NSLayoutConstraint* sizeConstraintHeight = [AutoLayoutUtility alignFirstView:nextPageView
                                                                withSecondView:currentPageView
                                                                   onAttribute:NSLayoutAttributeHeight
                                                              constraintHolder:self.view];

  return @[placementConstraintX, placementConstraintY, sizeConstraintWidth, sizeConstraintHeight];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for swipeToNextPage:swipeDirection:().
// -----------------------------------------------------------------------------
- (void) animateSlideToNextPage:(NSInteger)indexOfNextPage
                fromCurrentPage:(NSInteger)indexOfCurrentPage
                 swipeDirection:(UISwipeGestureRecognizerDirection)swipeDirection
           temporaryConstraints:(NSArray*)temporaryConstraints
{
  // Layout pass 1: Places the next page outside of the visible area using
  // temporary Auto Layout constraints
  [self.view layoutIfNeeded];

  // Layout pass 2: Slides in the next page and slides out the current page by
  // animating a change in a temporary Auto Layout constraint
  [UIView animateWithDuration:self.slideAnimationDurationInSeconds
                   animations:^
   {
    CGFloat slideConstant;
    if (swipeDirection == UISwipeGestureRecognizerDirectionLeft)
      slideConstant = -self.view.bounds.size.width;
    else
      slideConstant = self.view.bounds.size.width;

    self.leftEdgeConstraint.constant = slideConstant;
    [self.view layoutIfNeeded];
  }
   // Layout pass 3: Removes the current page and replaces the temporary
   // Auto Layout constraints with the final ones
                   completion:^(BOOL finished)
   {
    // Remove current page + constraints
    [self removeAutoLayoutConstraints];
    [self removePageFromViewHierarchy:indexOfCurrentPage];

    // Remove temporary constraints
    [self.view removeConstraints:temporaryConstraints];

    [self setupAutoLayoutConstraintsForPage:indexOfNextPage];

    self.pageControl.currentPage = indexOfNextPage;
    self.indexOfCurrentPage = indexOfNextPage;

    self.animationIsInProgress = false;

    [self notifyDelegateDidHideViewController:[self.viewControllers objectAtIndex:indexOfCurrentPage]
                        didShowViewController:[self.viewControllers objectAtIndex:indexOfNextPage]];
  }];
}

@end
