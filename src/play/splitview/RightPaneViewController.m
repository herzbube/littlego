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
#import "RightPaneViewController.h"
#import "../annotationview/AnnotationViewController.h"
#import "../boardposition/BoardPositionButtonBoxDataSource.h"
#import "../boardview/BoardViewController.h"
#import "../controller/AutoLayoutConstraintHelper.h"
#import "../gameaction/GameActionButtonBoxDataSource.h"
#import "../gameaction/GameActionManager.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for RightPaneViewController.
// -----------------------------------------------------------------------------
@interface RightPaneViewController()
@property(nonatomic, retain) UIView* woodenBackgroundView;
@property(nonatomic, retain) UIView* leftColumnView;
@property(nonatomic, retain) OrientationChangeNotifyingView* middleColumnView;
@property(nonatomic, retain) UIView* rightColumnView;
@property(nonatomic, retain) UIView* boardPositionButtonBoxContainerView;
@property(nonatomic, retain) BoardViewController* boardViewController;
@property(nonatomic, retain) ButtonBoxController* boardPositionButtonBoxController;
@property(nonatomic, retain) BoardPositionButtonBoxDataSource* boardPositionButtonBoxDataSource;
@property(nonatomic, retain) AnnotationViewController* annotationViewController;
@property(nonatomic, retain) ButtonBoxController* gameActionButtonBoxController;
@property(nonatomic, retain) GameActionButtonBoxDataSource* gameActionButtonBoxDataSource;
@property(nonatomic, assign) UILayoutConstraintAxis boardViewSmallerDimension;
@property(nonatomic, retain) NSMutableArray* boardViewAutoLayoutConstraints;
@property(nonatomic, retain) NSArray* gameActionButtonBoxAutoLayoutConstraints;
@end


@implementation RightPaneViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a RightPaneViewController object.
///
/// @note This is the designated initializer of RightPaneViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  self.woodenBackgroundView = nil;
  self.leftColumnView = nil;
  self.middleColumnView = nil;
  self.rightColumnView = nil;
  self.boardPositionButtonBoxContainerView = nil;
  self.boardViewSmallerDimension = UILayoutConstraintAxisVertical;
  self.boardViewAutoLayoutConstraints = [NSMutableArray array];
  self.gameActionButtonBoxAutoLayoutConstraints = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this RightPaneViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.leftColumnView = nil;
  self.middleColumnView = nil;
  self.rightColumnView = nil;
  self.boardPositionButtonBoxController = nil;
  self.boardPositionButtonBoxDataSource = nil;
  self.annotationViewController = nil;
  self.gameActionButtonBoxController = nil;
  self.gameActionButtonBoxDataSource = nil;
  self.gameActionButtonBoxAutoLayoutConstraints = nil;

  self.woodenBackgroundView = nil;
  self.boardViewController = nil;
  self.boardViewAutoLayoutConstraints = nil;
  
  [super dealloc];
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.annotationViewController = [AnnotationViewController annotationViewController];
  self.boardPositionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionVertical] autorelease];
  self.gameActionButtonBoxController = [[[ButtonBoxController alloc] initWithScrollDirection:UICollectionViewScrollDirectionVertical] autorelease];

  self.boardViewController = [[[BoardViewController alloc] init] autorelease];

  self.boardPositionButtonBoxDataSource = [[[BoardPositionButtonBoxDataSource alloc] init] autorelease];
  self.boardPositionButtonBoxController.buttonBoxControllerDataSource = self.boardPositionButtonBoxDataSource;
  self.gameActionButtonBoxDataSource = [[[GameActionButtonBoxDataSource alloc] init] autorelease];
  self.gameActionButtonBoxDataSource.buttonBoxController = self.gameActionButtonBoxController;
  self.gameActionButtonBoxController.buttonBoxControllerDataSource = self.gameActionButtonBoxDataSource;
  self.gameActionButtonBoxController.buttonBoxControllerDelegate = self;
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setAnnotationViewController:(AnnotationViewController*)annotationViewController
{
  if (_annotationViewController == annotationViewController)
    return;
  if (_annotationViewController)
  {
    [_annotationViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_annotationViewController removeFromParentViewController];
    [_annotationViewController release];
    _annotationViewController = nil;
  }
  if (annotationViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:annotationViewController];
    [annotationViewController didMoveToParentViewController:self];
    [annotationViewController retain];
    _annotationViewController = annotationViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardViewController:(BoardViewController*)boardViewController
{
  if (_boardViewController == boardViewController)
    return;
  if (_boardViewController)
  {
    [_boardViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardViewController removeFromParentViewController];
    [_boardViewController release];
    _boardViewController = nil;
  }
  if (boardViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardViewController];
    [boardViewController didMoveToParentViewController:self];
    [boardViewController retain];
    _boardViewController = boardViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setBoardPositionButtonBoxController:(ButtonBoxController*)boardPositionButtonBoxController
{
  if (_boardPositionButtonBoxController == boardPositionButtonBoxController)
    return;
  if (_boardPositionButtonBoxController)
  {
    [_boardPositionButtonBoxController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_boardPositionButtonBoxController removeFromParentViewController];
    [_boardPositionButtonBoxController release];
    _boardPositionButtonBoxController = nil;
  }
  if (boardPositionButtonBoxController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:boardPositionButtonBoxController];
    [boardPositionButtonBoxController didMoveToParentViewController:self];
    [boardPositionButtonBoxController retain];
    _boardPositionButtonBoxController = boardPositionButtonBoxController;
  }
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setGameActionButtonBoxController:(ButtonBoxController*)gameActionButtonBoxController
{
  if (_gameActionButtonBoxController == gameActionButtonBoxController)
    return;
  if (_gameActionButtonBoxController)
  {
    [_gameActionButtonBoxController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_gameActionButtonBoxController removeFromParentViewController];
    [_gameActionButtonBoxController release];
    _gameActionButtonBoxController = nil;
  }
  if (gameActionButtonBoxController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:gameActionButtonBoxController];
    [gameActionButtonBoxController didMoveToParentViewController:self];
    [gameActionButtonBoxController retain];
    _gameActionButtonBoxController = gameActionButtonBoxController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self configureViews];
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  self.woodenBackgroundView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.view addSubview:self.woodenBackgroundView];

  self.leftColumnView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.boardPositionButtonBoxContainerView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.woodenBackgroundView addSubview:self.leftColumnView];
  [self.leftColumnView addSubview:self.annotationViewController.view];
  [self.leftColumnView addSubview:self.boardPositionButtonBoxContainerView];
  [self.boardPositionButtonBoxContainerView addSubview:self.boardPositionButtonBoxController.view];

  self.middleColumnView = [[[OrientationChangeNotifyingView alloc] initWithFrame:CGRectZero] autorelease];
  self.middleColumnView.delegate = self;
  [self.woodenBackgroundView addSubview:self.middleColumnView];
  [self.middleColumnView addSubview:self.boardViewController.view];

  self.rightColumnView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  [self.woodenBackgroundView addSubview:self.rightColumnView];
  [self.rightColumnView addSubview:self.gameActionButtonBoxController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  CGFloat annotationViewWidthMultiplier;
  enum UIType uiType = [LayoutManager sharedManager].uiType;
  if (uiType == UITypePhone)
    annotationViewWidthMultiplier = 1.75;
  else
    annotationViewWidthMultiplier = 2.00;

  self.boardViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                              ofBoardView:self.boardViewController.view
                                                  forAxis:self.boardViewSmallerDimension
                                         constraintHolder:self.boardViewController.view.superview];

  int horizontalSpacingButtonBox = [AutoLayoutUtility horizontalSpacingSiblings];
  int verticalSpacingButtonBox = [AutoLayoutUtility verticalSpacingSiblings];

  self.woodenBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.woodenBackgroundView];

  self.leftColumnView.translatesAutoresizingMaskIntoConstraints = NO;
  self.middleColumnView.translatesAutoresizingMaskIntoConstraints = NO;
  self.rightColumnView.translatesAutoresizingMaskIntoConstraints = NO;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];
  // Here we define the width of the middle column. The width of the left and
  // right columns are defined further down (by defining the width of the
  // subviews they contain), the middle column gets the remaining width.
  [viewsDictionary setObject:self.leftColumnView forKey:@"leftColumnView"];
  [viewsDictionary setObject:self.middleColumnView forKey:@"middleColumnView"];
  [viewsDictionary setObject:self.rightColumnView forKey:@"rightColumnView"];
  [visualFormats addObject:@"H:[leftColumnView]-0-[middleColumnView]-0-[rightColumnView]"];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.woodenBackgroundView];

  // Here we anchor the column views' edges. This defines the height of all
  // of the columns, and the left/right position of the left/right column
  // view.
  UIView* anchorView = self.woodenBackgroundView;
  NSLayoutXAxisAnchor* leftAnchor;
  NSLayoutXAxisAnchor* rightAnchor;
  NSLayoutYAxisAnchor* topAnchor;
  NSLayoutYAxisAnchor* bottomAnchor;
  if (@available(iOS 11.0, *))
  {
    UILayoutGuide* layoutGuide = anchorView.safeAreaLayoutGuide;
    leftAnchor = layoutGuide.leftAnchor;
    rightAnchor = layoutGuide.rightAnchor;
    topAnchor = layoutGuide.topAnchor;
    bottomAnchor = layoutGuide.bottomAnchor;
  }
  else
  {
    leftAnchor = anchorView.leftAnchor;
    rightAnchor = anchorView.rightAnchor;
    topAnchor = anchorView.topAnchor;
    bottomAnchor = anchorView.bottomAnchor;
  }
  [self.leftColumnView.leftAnchor constraintEqualToAnchor:leftAnchor].active = YES;
  [self.leftColumnView.topAnchor constraintEqualToAnchor:topAnchor].active = YES;
  [self.leftColumnView.bottomAnchor constraintEqualToAnchor:bottomAnchor].active = YES;
  [self.middleColumnView.topAnchor constraintEqualToAnchor:topAnchor].active = YES;
  [self.middleColumnView.bottomAnchor constraintEqualToAnchor:bottomAnchor].active = YES;
  [self.rightColumnView.topAnchor constraintEqualToAnchor:topAnchor].active = YES;
  [self.rightColumnView.bottomAnchor constraintEqualToAnchor:bottomAnchor].active = YES;
  [self.rightColumnView.rightAnchor constraintEqualToAnchor:rightAnchor].active = YES;

  // Here we define the width of the left column view. The height of the button
  // box in the left column view is defined further down, the annotation view
  // gets the remaining height.
  CGSize buttonBoxSize = self.boardPositionButtonBoxController.buttonBoxSize;
  // The annotation view should be wide enough to display most description
  // texts without scrolling. It can't be arbitrarily wide because it must
  // leave enough space for the board view.
  int annotationViewWidth = buttonBoxSize.width * annotationViewWidthMultiplier;
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.annotationViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
  self.boardPositionButtonBoxContainerView.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"annotationView"] = self.annotationViewController.view;
  viewsDictionary[@"boardPositionButtonBoxContainerView"] = self.boardPositionButtonBoxContainerView;
  [visualFormats addObject:@"H:|-[annotationView]-|"];
  [visualFormats addObject:@"H:|-[boardPositionButtonBoxContainerView]-|"];
  [visualFormats addObject:@"V:|-[annotationView]-[boardPositionButtonBoxContainerView]-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[annotationView(==%d)]", annotationViewWidth]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.leftColumnView];

  // Here we define the height of the button box in the left column view
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.boardPositionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
  viewsDictionary[@"boardPositionButtonBox"] = self.boardPositionButtonBoxController.view;
  [visualFormats addObject:@"V:|-0-[boardPositionButtonBox]-0-|"];
  [visualFormats addObject:[NSString stringWithFormat:@"H:[boardPositionButtonBox(==%f)]", buttonBoxSize.width]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[boardPositionButtonBox(==%f)]", buttonBoxSize.height]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.boardPositionButtonBoxController.view.superview];
  [AutoLayoutUtility alignFirstView:self.boardPositionButtonBoxController.view
                     withSecondView:self.boardPositionButtonBoxController.view.superview
                        onAttribute:NSLayoutAttributeCenterX
                   constraintHolder:self.boardPositionButtonBoxController.view.superview];

  // Here we define the width and positioning of the button box in the right
  // column view, as well as the width of the right column view itself.
  [viewsDictionary removeAllObjects];
  [visualFormats removeAllObjects];
  self.gameActionButtonBoxController.view.translatesAutoresizingMaskIntoConstraints = NO;
  [viewsDictionary setObject:self.gameActionButtonBoxController.view forKey:@"gameActionButtonBox"];
  [visualFormats addObject:[NSString stringWithFormat:@"H:|-%d-[gameActionButtonBox]-%d-|", horizontalSpacingButtonBox, horizontalSpacingButtonBox]];
  [visualFormats addObject:[NSString stringWithFormat:@"V:[gameActionButtonBox]-%d-|", verticalSpacingButtonBox]];
  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:self.rightColumnView];

  // Size (specifically height) of gameActionButtonBox is variable,
  // constraints are managed dynamically
  [self updateGameActionButtonBoxAutoLayoutConstraints];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  // This view provides a wooden texture background not only for the Go board,
  // but for the entire area in which the Go board resides
  self.woodenBackgroundView.backgroundColor = [UIColor woodenBackgroundColor];

  [UiUtilities applyTransparentStyleToView:self.annotationViewController.view];
  [UiUtilities applyTransparentStyleToView:self.boardPositionButtonBoxContainerView];
  [UiUtilities applyTransparentStyleToView:self.gameActionButtonBoxController.view];
}

#pragma mark - Dynamic Auto Layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Updates Auto Layout constraints that manage the size of the
/// Game Action button box. The new constraints use the current size values
/// provided by the button box controller.
// -----------------------------------------------------------------------------
- (void) updateGameActionButtonBoxAutoLayoutConstraints
{
  if (self.gameActionButtonBoxAutoLayoutConstraints)
    [self.rightColumnView removeConstraints:self.gameActionButtonBoxAutoLayoutConstraints];

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.gameActionButtonBoxController.view, @"gameActionButtonBox",
                                   nil];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithObjects:
                                   [NSString stringWithFormat:@"H:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.width],
                                   [NSString stringWithFormat:@"V:[gameActionButtonBox(==%f)]", self.gameActionButtonBoxController.buttonBoxSize.height],
                                   nil];
  self.gameActionButtonBoxAutoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                                withViews:viewsDictionary
                                                                                   inView:self.rightColumnView];
}

#pragma mark - ButtonBoxControllerDataDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ButtonBoxControllerDataDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) buttonBoxButtonsWillChange
{
  [self updateGameActionButtonBoxAutoLayoutConstraints];
}

#pragma mark - OrientationChangeNotifyingViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief OrientationChangeNotifyingViewDelegate protocol method.
///
/// This delegate method is important for finding out which is the smaller
/// dimension of the board view after layouting has finished, so that in a final
/// round of layouting the board view can be constrained to be square for that
/// dimension.
///
/// This delegate method handles interface orientation changes while this
/// controller's view hierarchy is visible, and changes that occurred while this
/// controller's view hierarchy was not visible (this method is invoked when the
/// controller's view becomes visible again). Typically an override of
/// the UIViewController method viewWillLayoutSubviews could also be used for
/// this.
///
/// The reason why viewWillLayoutSubviews is not overridden is that UIKit does
/// not invoke viewWillLayoutSubviews every time that the bounds of
/// self.middleColumnView change, so it can't be relied on to find out the
/// board view's smaller dimension.
// -----------------------------------------------------------------------------
- (void) orientationChangeNotifyingView:(OrientationChangeNotifyingView*)orientationChangeNotifyingView
             didChangeToLargerDimension:(UILayoutConstraintAxis)largerDimension
                       smallerDimension:(UILayoutConstraintAxis)smallerDimension
{
  if (self.boardViewSmallerDimension != smallerDimension)
  {
    self.boardViewSmallerDimension = smallerDimension;

    [AutoLayoutConstraintHelper updateAutoLayoutConstraints:self.boardViewAutoLayoutConstraints
                                                ofBoardView:self.boardViewController.view
                                                    forAxis:self.boardViewSmallerDimension
                                           constraintHolder:self.boardViewController.view.superview];
  }
}

@end
