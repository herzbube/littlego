// -----------------------------------------------------------------------------
// Copyright 2013-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardPositionToolbarController.h"
#import "BoardPositionListViewController.h"
#import "CurrentBoardPositionViewController.h"
#import "../../shared/LayoutManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// BoardPositionToolbarController.
// -----------------------------------------------------------------------------
@interface BoardPositionToolbarController()
@property(nonatomic, assign) bool toolbarNeedsPopulation;
@property(nonatomic, assign) UIToolbar* toolbar;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItems;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsBackward;
@property(nonatomic, retain) NSMutableArray* navigationBarButtonItemsForward;
@property(nonatomic, assign) bool boardPositionListViewIsVisible;
@end


@implementation BoardPositionToolbarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardPositionToolbarController object.
///
/// @note This is the designated initializer of BoardPositionToolbarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.toolbarNeedsPopulation = false;
  self.toolbar = nil;
  self.navigationBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsBackward = [NSMutableArray arrayWithCapacity:0];
  self.navigationBarButtonItemsForward = [NSMutableArray arrayWithCapacity:0];
  self.boardPositionListViewIsVisible = false;
  [self setupChildControllers];
  [BoardPositionNavigationManager sharedNavigationManager].delegate = self;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardPositionToolbarController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if ([BoardPositionNavigationManager sharedNavigationManager].delegate == self)
    [BoardPositionNavigationManager sharedNavigationManager].delegate = nil;
  self.toolbar = nil;
  self.navigationBarButtonItems = nil;
  self.navigationBarButtonItemsBackward = nil;
  self.navigationBarButtonItemsForward = nil;
  self.boardPositionListViewController = nil;
  self.currentBoardPositionViewController = nil;
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  if ([LayoutManager sharedManager].uiType != UITypePad)
  {
    self.boardPositionListViewController = [[[BoardPositionListViewController alloc] init] autorelease];
    self.currentBoardPositionViewController = [[[CurrentBoardPositionViewController alloc] init] autorelease];

    self.currentBoardPositionViewController.delegate = self;
  }
  else
  {
    self.boardPositionListViewController = nil;
    self.currentBoardPositionViewController = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionListViewController:(BoardPositionListViewController*)boardPositionListViewController
{
  if (_boardPositionListViewController == boardPositionListViewController)
    return;
  if (_boardPositionListViewController)
  {
    [_boardPositionListViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionListViewController removeFromParentViewController];
    [_boardPositionListViewController release];
    _boardPositionListViewController = nil;
  }
  if (boardPositionListViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionListViewController];
    [boardPositionListViewController didMoveToParentViewController:self];
    [boardPositionListViewController retain];
    _boardPositionListViewController = boardPositionListViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)currentBoardPositionViewController
{
  if (_currentBoardPositionViewController == currentBoardPositionViewController)
    return;
  if (_currentBoardPositionViewController)
  {
    [_currentBoardPositionViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_currentBoardPositionViewController removeFromParentViewController];
    [_currentBoardPositionViewController release];
    _currentBoardPositionViewController = nil;
  }
  if (currentBoardPositionViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:currentBoardPositionViewController];
    [currentBoardPositionViewController didMoveToParentViewController:self];
    [currentBoardPositionViewController retain];
    _currentBoardPositionViewController = currentBoardPositionViewController;
  }
}

#pragma mark - loadView and helpers

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  // As of iOS 13 UIToolbar needs to be initialized with a frame that is
  // sufficiently sized, otherwise the toolbar will generate an
  // "Unable to simultaneously satisfy constraints" message when bar button
  // items are addded. We use an arbitrary size here because the toolbar will
  // resized later on to its proper dimensions.
  CGRect initialFrame = CGRectMake(0, 0, 100, 100);
  self.toolbar = [[[UIToolbar alloc] initWithFrame:initialFrame] autorelease];
  self.toolbar.accessibilityIdentifier = boardPositionNavigationButtonContainerAccessibilityIdentifier;
  self.view = self.toolbar;
  self.toolbar.delegate = self;

  [self setupBarButtonItems];
  if ([LayoutManager sharedManager].uiType != UITypePad)
    [self setupBoardPositionViews];  // cf. the override of viewDidLayoutSubviews()

  self.toolbarNeedsPopulation = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];

  // When we invoked setupBoardPositionViews() during loadView() we added our
  // own subviews to the toolbar, but when the toolbar is laid out it creates
  // its own internal views on top of our own subviews, making them unresponsive
  // to touches and gestures. Here we bring our subviews to the front and make
  // them responsive. We have to do this only once.
  //
  // This kind of special treatment started to be necessary with iOS 11, when
  // UIToolbar began working with an internal content view
  // (cf. https://stackoverflow.com/a/46448751/1054378). It used to be
  // sufficient to invoke layoutSubviews() on the toolbar before invoking our
  // own setupBoardPositionViews(). Starting with iOS 13 this stopped working,
  // so now we explicitly bring our subviews to the top of the z-stack.
  static bool subviewsAreResponsive = false;
  if (! subviewsAreResponsive)
  {
    subviewsAreResponsive = true;
    [self.view bringSubviewToFront:self.boardPositionListViewController.view];
    [self.view bringSubviewToFront:self.currentBoardPositionViewController.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupBarButtonItems
{
  UIBarButtonItem* navigationBarButtonSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                              target:nil
                                                                                              action:nil] autorelease];

  enum BoardPositionNavigationDirection direction = BoardPositionNavigationDirectionBackward;
  [self addButtonWithImageNamed:rewindToStartButtonIconResource withSelector:@selector(rewindToStart:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  [self addButtonWithImageNamed:backButtonIconResource withSelector:@selector(previousBoardPosition:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  direction = BoardPositionNavigationDirectionForward;
  [self addButtonWithImageNamed:forwardButtonIconResource withSelector:@selector(nextBoardPosition:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
  [self addButtonWithImageNamed:forwardToEndButtonIconResource withSelector:@selector(fastForwardToEnd:) navigationDirection:direction];
  [self.navigationBarButtonItems addObject:navigationBarButtonSpacer];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for setupBarButtonItems().
// -----------------------------------------------------------------------------
- (void) addButtonWithImageNamed:(NSString*)imageName withSelector:(SEL)selector navigationDirection:(enum BoardPositionNavigationDirection)direction
{
  UIBarButtonItem* button = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageName]
                                                              style:UIBarButtonItemStylePlain
                                                             target:[BoardPositionNavigationManager sharedNavigationManager]
                                                             action:selector] autorelease];
  button.enabled = [[BoardPositionNavigationManager sharedNavigationManager] isNavigationEnabledInDirection:direction];
  [self.navigationBarButtonItems addObject:button];
  if (BoardPositionNavigationDirectionBackward == direction)
    [self.navigationBarButtonItemsBackward addObject:button];
  else
    [self.navigationBarButtonItemsForward addObject:button];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionViews
{
  [self.view addSubview:self.boardPositionListViewController.view];
  [self.view addSubview:self.currentBoardPositionViewController.view];

  self.boardPositionListViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.currentBoardPositionViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  int toolbarPaddingHorizontal = [AutoLayoutUtility horizontalSpacingSiblings];
  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.boardPositionListViewController.view, @"boardPositionListView",
                                   self.currentBoardPositionViewController.view, @"currentBoardPositionView",
                                   nil];
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            [NSString stringWithFormat:@"H:|-%d-[boardPositionListView]-[currentBoardPositionView]-%d-|", toolbarPaddingHorizontal, toolbarPaddingHorizontal],
                            // This works because currentBoardPositionView has
                            // an intrinsic content size
                            @"V:[boardPositionListView(==currentBoardPositionView)]",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];
  [AutoLayoutUtility alignFirstView:self.boardPositionListViewController.view
                     withSecondView:self.view
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
  [AutoLayoutUtility alignFirstView:self.currentBoardPositionViewController.view
                     withSecondView:self.view
                        onAttribute:NSLayoutAttributeCenterY
                   constraintHolder:self.view];
  
  // Add a fixed space equal to the width of the current board position element to
  // the toolbar so that the toolbar items can space evenly in the remaining space
  UIBarButtonItem* navigationBarFixedSpacer = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                             target:nil
                                                                                             action:nil] autorelease];
  navigationBarFixedSpacer.width = self.currentBoardPositionViewController.view.intrinsicContentSize.width;
  [self.navigationBarButtonItems addObject:navigationBarFixedSpacer];
}

#pragma mark - Updaters

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self populateToolbar];
}

// -----------------------------------------------------------------------------
/// @brief Populates the toolbar with bar button items.
// -----------------------------------------------------------------------------
- (void) populateToolbar
{
  if (! self.toolbarNeedsPopulation)
    return;
  self.toolbarNeedsPopulation = false;

  NSMutableArray* toolbarItems = [NSMutableArray arrayWithCapacity:0];
  if (self.boardPositionListViewIsVisible)
  {
    self.boardPositionListViewController.view.hidden = NO;
  }
  else
  {
    self.boardPositionListViewController.view.hidden = YES;
    [toolbarItems addObjectsFromArray:self.navigationBarButtonItems];
  }
  [self.toolbar setItems:toolbarItems animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Toggles the visible items in the toolbar between the board position
/// list view and the navigation buttons. The current board position view is
/// always visible.
// -----------------------------------------------------------------------------
- (void) toggleToolbarItems
{
  self.boardPositionListViewIsVisible = ! self.boardPositionListViewIsVisible;
  self.toolbarNeedsPopulation = true;
  [self delayedUpdate];
}

#pragma mark - BoardPositionNavigationManagerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief BoardPositionNavigationManagerDelegate method.
// -----------------------------------------------------------------------------
- (void) boardPositionNavigationManager:(BoardPositionNavigationManager*)manager
                       enableNavigation:(BOOL)enable
                            inDirection:(enum BoardPositionNavigationDirection)direction
{
  switch (direction)
  {
    case BoardPositionNavigationDirectionForward:
    {
      for (UIBarButtonItem* item in self.navigationBarButtonItemsForward)
        item.enabled = enable;
      break;
    }
    case BoardPositionNavigationDirectionBackward:
    {
      for (UIBarButtonItem* item in self.navigationBarButtonItemsBackward)
        item.enabled = enable;
      break;
    }
    case BoardPositionNavigationDirectionAll:
    {
      for (UIBarButtonItem* item in self.navigationBarButtonItems)
        item.enabled = enable;
      break;
    }
    default:
    {
      break;
    }
  }
}

#pragma mark - CurrentBoardPositionViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief CurrentBoardPositionViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didTapCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)controller
{
  [self toggleToolbarItems];
}

#pragma mark - UIBarPositioning overrides

// -----------------------------------------------------------------------------
/// @brief UIBarPositioning protocol method.
// -----------------------------------------------------------------------------
- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar
{
  if ([LayoutManager sharedManager].uiType != UITypePad)
    return UIBarPositionBottom;
  else
    return UIBarPositionTop;
}

@end
