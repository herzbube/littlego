// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewController.h"
#import "ActivityIndicatorController.h"
#import "DebugPlayViewController.h"
#import "PlayView.h"
#import "StatusLineController.h"
#import "ToolbarController.h"
#import "boardposition/BoardPositionListViewController.h"
#import "boardposition/BoardPositionModel.h"
#import "boardposition/BoardPositionTableListViewController.h"
#import "boardposition/BoardPositionToolbarController.h"
#import "boardposition/BoardPositionView.h"
#import "boardposition/BoardPositionViewMetrics.h"
#import "boardposition/CurrentBoardPositionViewController.h"
#import "gesture/TapGestureController.h"
#import "splitview/LeftPaneViewController.h"
#import "splitview/RightPaneViewController.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../command/CommandBase.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"

// System includes
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <math.h>

// Constants
NSString* associatedCommandObjectKey = @"AssociatedCommandObject";

// Enums
enum ActionType
{
  ActionTypePlay,
  ActionTypeDiscard
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewController.
// -----------------------------------------------------------------------------
@interface PlayViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) loadView;
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration;
//@}
/// @name ToolbarControllerDelegate protocol
//@{
- (void) toolbarController:(ToolbarController*)controller playOrAlertWithCommand:(CommandBase*)command;
- (void) toolbarController:(ToolbarController*)controller discardOrAlertWithCommand:(CommandBase*)command;
- (void) toolbarController:(ToolbarController*)controller makeVisible:(bool)makeVisible gameInfoView:(UIView*)gameInfoView;
//@}
/// @name PanGestureControllerDelegate protocol
//@{
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(CommandBase*)command;
//@}
/// @name CurrentBoardPositionViewControllerDelegate protocol
//@{
- (void) didTapCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)controller;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name Notification responders
//@{
- (void) applicationIsReadyForAction:(NSNotification*)notification;
//@}
/// @name Main view hierarchy setup
//@{
- (void) setupMainView;
- (CGRect) mainViewFrame;
- (void) setupSubviewsOfMainView;
- (CGRect) subviewFrame;
//@}
/// @name Front side view hierarchy setup
//@{
- (void) setupSplitView;
- (void) setupToolbarMain;
- (CGRect) toolbarMainFrame;
- (UIView*) toolbarMainSuperview;
- (void) setupToolbarBoardPositionNavigation;
- (CGRect) toolbarBoardPositionNavigationFrame;
- (UIView*) toolbarBoardPositionNavigationSuperview;
- (void) setupPlayView;
- (CGRect) playViewFrame;
- (UIView*) playViewSuperview;
- (void) setupStatusLineView;
- (CGRect) statusLineViewFrame;
- (UIView*) statusLineSuperview;
- (void) setupActivityIndicatorView;
- (CGRect) activityIndicatorViewFrame;
- (UIView*) activityIndicatorViewSuperview;
- (void) setupBoardPositionListView;
- (CGRect) boardPositionListViewFrame;
- (void) setupCurrentBoardPositionView;
- (CGRect) currentBoardPositionViewFrame;
- (void) setupBoardPositionListContainerView;
- (CGRect) boardPositionListContainerViewFrame;
- (UIView*) boardPositionListContainerViewSuperview;
- (void) setupDebugView;
//@}
/// @name Private helpers
//@{
- (void) makeControllerReadyForAction;
- (void) setupSubviewsOfFrontSideView;
- (void) setupSubcontrollers;
- (void) flipToFrontSideView:(bool)flipToFrontSideView;
- (void) alertOrAction:(enum ActionType)actionType withCommand:(CommandBase*)command;
//@}
/// @name Privately declared properties
//@{
/// @brief True if this controller has been set up is now "ready for action".
@property(nonatomic, assign) bool controllerReadyForAction;
/// @brief The frontside view. A superview of @e playView.
@property(nonatomic, retain) UIView* frontSideView;
/// @brief The backside view with information about the current game.
@property(nonatomic, retain) UIView* backSideView;
@property(nonatomic, retain) PlayView* playView;
@property(nonatomic, retain) UIToolbar* toolbarMain;
@property(nonatomic, retain) UIToolbar* toolbarBoardPositionNavigation;
@property(nonatomic, retain) ItemScrollView* boardPositionListView;
@property(nonatomic, retain) BoardPositionView* currentBoardPositionView;
@property(nonatomic, retain) UILabel* statusLine;
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicator;
@property(nonatomic, retain) UIView* boardPositionListContainerView;
@property(nonatomic, retain) BoardPositionViewMetrics* boardPositionViewMetrics;
@property(nonatomic, retain) UISplitViewController* splitViewController;
@property(nonatomic, retain) LeftPaneViewController* leftPaneViewController;
@property(nonatomic, retain) RightPaneViewController* rightPaneViewController;
@property(nonatomic, retain) ToolbarController* toolbarController;
@property(nonatomic, retain) StatusLineController* statusLineController;
@property(nonatomic, retain) ActivityIndicatorController* activityIndicatorController;
@property(nonatomic, retain) BoardPositionToolbarController* boardPositionToolbarController;
@property(nonatomic, retain) BoardPositionListViewController* boardPositionListViewController;
@property(nonatomic, retain) CurrentBoardPositionViewController* currentBoardPositionViewController;
@property(nonatomic, retain) BoardPositionTableListViewController* boardPositionTableListViewController;
@property(nonatomic, retain) PanGestureController* panGestureController;
@property(nonatomic, retain) TapGestureController* tapGestureController;
//@}
@end


@implementation PlayViewController

@synthesize controllerReadyForAction;
@synthesize frontSideView;
@synthesize backSideView;
@synthesize playView;
@synthesize toolbarMain;
@synthesize toolbarBoardPositionNavigation;
@synthesize boardPositionListView;
@synthesize currentBoardPositionView;
@synthesize statusLine;
@synthesize activityIndicator;
@synthesize boardPositionListContainerView;
@synthesize boardPositionViewMetrics;
@synthesize splitViewController;
@synthesize leftPaneViewController;
@synthesize rightPaneViewController;
@synthesize toolbarController;
@synthesize statusLineController;
@synthesize activityIndicatorController;
@synthesize boardPositionToolbarController;
@synthesize boardPositionListViewController;
@synthesize currentBoardPositionViewController;
@synthesize boardPositionTableListViewController;
@synthesize panGestureController;
@synthesize tapGestureController;


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.frontSideView = nil;
  self.backSideView = nil;
  self.playView = nil;
  self.toolbarMain = nil;
  self.toolbarBoardPositionNavigation = nil;
  self.boardPositionListView = nil;
  self.currentBoardPositionView = nil;
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.boardPositionListContainerView = nil;
  self.boardPositionViewMetrics = nil;
  self.splitViewController = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  self.toolbarController = nil;
  self.statusLineController = nil;
  self.activityIndicatorController = nil;
  self.boardPositionToolbarController = nil;
  self.boardPositionListViewController = nil;
  self.currentBoardPositionViewController = nil;
  self.boardPositionTableListViewController = nil;
  self.panGestureController = nil;
  self.tapGestureController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self setupMainView];

  // Add frontside view to the main view already here, do not wait until
  // makeControllerReadyForAction is invoked. Reason: If the user is holding the
  // device in landscape orientation while the application is starting up, iOS
  // will first start up in portrait orientation and then initiate an
  // auto-rotation to landscape orientation. If the frontside view has not yet
  // been added as a subview at this time, it will not be auto-resized, and all
  // size calculations for the play view during auto-rotation will miserably
  // fail. Because startup auto-rotation happens before
  // makeControllerReadyForAction is called, we must add the frontside view
  // to the main view here.
  [self setupSubviewsOfMainView];

  // Setup of remaining views is delayed to makeControllerReadyForAction()
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by loadView().
// -----------------------------------------------------------------------------
- (void) setupMainView
{
  CGRect mainViewFrame = [self mainViewFrame];
  self.view = [[[UIView alloc] initWithFrame:mainViewFrame] autorelease];
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupMainView().
// -----------------------------------------------------------------------------
- (CGRect) mainViewFrame
{
  int mainViewX = 0;
  int mainViewY = 0;
  int mainViewWidth = [UiElementMetrics screenWidth];
  int mainViewHeight = ([UiElementMetrics screenHeight]
                        - [UiElementMetrics tabBarHeight]
                        - [UiElementMetrics statusBarHeight]);
  return CGRectMake(mainViewX, mainViewY, mainViewWidth, mainViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by loadView().
// -----------------------------------------------------------------------------
- (void) setupSubviewsOfMainView
{
  CGRect subViewFrame = [self subviewFrame];
  self.frontSideView = [[[UIView alloc] initWithFrame:subViewFrame] autorelease];
  self.backSideView = [[[UIView alloc] initWithFrame:subViewFrame] autorelease];
  [self.view addSubview:self.frontSideView];
  self.frontSideView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.backSideView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  // Set common background color for all elements on the frontside view
  [UiUtilities addGroupTableViewBackgroundToView:self.frontSideView];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupSubviewsOfMainView().
// -----------------------------------------------------------------------------
- (CGRect) subviewFrame
{
  CGSize superViewSize = self.view.bounds.size;
  int subViewX = 0;
  int subViewY = 0;
  int subViewWidth = superViewSize.width;
  int subViewHeight = superViewSize.height;
  return CGRectMake(subViewX, subViewY, subViewWidth, subViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupSplitView
{
  self.splitViewController = [[[UISplitViewController alloc] init] autorelease];
  self.leftPaneViewController = [[[LeftPaneViewController alloc] init] autorelease];
  self.rightPaneViewController = [[[RightPaneViewController alloc] init] autorelease];
  // Assign view controllers before first use of self.splitViewController.view
  // (if we do it the other way round, a message is printed in the debug area in
  // Xcode that warns us about the mistake; we should heed this warning,
  // although no bad things [tm] could actually be observed)
  self.splitViewController.viewControllers = [NSArray arrayWithObjects:self.leftPaneViewController, self.rightPaneViewController, nil];
  // The following statement is essential so that the split view controller
  // properly receives rotation events in iOS 5. In iOS6 rotation seems to work
  // even if the statement is missing. Behaviour of iOS 5 tested in simulator
  // only.
  [self addChildViewController:self.splitViewController];
  CGRect splitViewControllerViewFrame = self.frontSideView.bounds;
  self.splitViewController.view.frame = splitViewControllerViewFrame;
  [self.frontSideView addSubview:self.splitViewController.view];
  // Set left/right panes to use the same height as the split view
  CGRect leftPaneViewFrame = self.leftPaneViewController.view.frame;
  leftPaneViewFrame.size.height = splitViewControllerViewFrame.size.height;
  self.leftPaneViewController.view.frame = leftPaneViewFrame;
  CGRect rightPaneViewFrame = self.rightPaneViewController.view.frame;
  rightPaneViewFrame.size.height = splitViewControllerViewFrame.size.height;
  self.rightPaneViewController.view.frame = rightPaneViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupToolbarMain
{
  CGRect toolbarFrame = [self toolbarMainFrame];
  self.toolbarMain = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
  UIView* superView = [self toolbarMainSuperview];
  [superView addSubview:self.toolbarMain];
  
  self.toolbarMain.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) toolbarMainFrame
{
  UIView* superView = [self toolbarMainSuperview];
  int toolbarViewX = 0;
  int toolbarViewY = 0;
  int toolbarViewWidth = superView.bounds.size.width;
  int toolbarViewHeight = [UiElementMetrics toolbarHeight];
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) toolbarMainSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.frontSideView;
  else
    return self.rightPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupToolbarBoardPositionNavigation
{
  CGRect toolbarFrame = [self toolbarBoardPositionNavigationFrame];
  self.toolbarBoardPositionNavigation = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
  UIView* superView = [self toolbarBoardPositionNavigationSuperview];
  [superView addSubview:self.toolbarBoardPositionNavigation];
  
  self.toolbarBoardPositionNavigation.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) toolbarBoardPositionNavigationFrame
{
  UIView* superView = [self toolbarBoardPositionNavigationSuperview];
  int toolbarViewX = 0;
  int toolbarViewWidth = superView.bounds.size.width;
  int toolbarViewHeight = [UiElementMetrics toolbarHeight];
  int toolbarViewY;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    toolbarViewY = superView.bounds.size.height - toolbarViewHeight;
  else
    toolbarViewY = 0;
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) toolbarBoardPositionNavigationSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.frontSideView;
  else
    return self.leftPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupPlayView
{
  CGRect playViewFrame = [self playViewFrame];
  self.playView = [[[PlayView alloc] initWithFrame:playViewFrame] autorelease];
  UIView* superView = [self playViewSuperview];
  [superView addSubview:self.playView];

  self.playView.backgroundColor = [UIColor clearColor];
  self.playView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) playViewFrame
{
  UIView* superView = [self playViewSuperview];
  CGSize superViewSize = superView.bounds.size;
  int playViewX = 0;
  int playViewY = CGRectGetMaxY(self.toolbarMain.frame);
  int playViewWidth = superViewSize.width;
  int playViewHeight;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    playViewHeight = (superViewSize.height
                      - self.toolbarMain.frame.size.height
                      - self.toolbarBoardPositionNavigation.frame.size.height);
  }
  else
  {
    playViewHeight = (superViewSize.height
                      - self.toolbarMain.frame.size.height);
  }
  return CGRectMake(playViewX, playViewY, playViewWidth, playViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) playViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.frontSideView;
  else
    return self.rightPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupStatusLineView
{
  CGRect statusLineViewFrame = [self statusLineViewFrame];
  self.statusLine = [[[UILabel alloc] initWithFrame:statusLineViewFrame] autorelease];
  UIView* superView = [self statusLineSuperview];
  [superView addSubview:self.statusLine];

  self.statusLine.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
  self.statusLine.backgroundColor = [UIColor clearColor];
  self.statusLine.lineBreakMode = UILineBreakModeWordWrap;
  self.statusLine.numberOfLines = 1;
  self.statusLine.font = [UIFont systemFontOfSize:self.boardPositionViewMetrics.boardPositionViewFontSize];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) statusLineViewFrame
{
  CGRect boardFrame = self.playView.boardFrame;
  CGRect activityIndicatorFrame = self.activityIndicator.frame;
  int statusLineViewX = boardFrame.origin.x;
  int statusLineViewWidth = (activityIndicatorFrame.origin.x
                             - statusLineViewX
                             - [UiElementMetrics spacingHorizontal]);
  UIFont* statusLineViewFont = [UIFont systemFontOfSize:self.boardPositionViewMetrics.boardPositionViewFontSize];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize statusLineTextSize = [@"A" sizeWithFont:statusLineViewFont
                               constrainedToSize:constraintSize
                                   lineBreakMode:UILineBreakModeWordWrap];
  int statusLineViewHeight = statusLineTextSize.height;

  int statusLineViewY;
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    // [UiElementMetrics spacingVertical] is too much, we are too constrained
    // on the iPhone screen. Instead we choose 2 points as an arbitrary spacing
    // value
    int statusLineSpacingVertical = 2;
    statusLineViewY = (self.toolbarBoardPositionNavigation.frame.origin.y
                           - statusLineViewHeight
                           - statusLineSpacingVertical);
    return CGRectMake(statusLineViewX, statusLineViewY, statusLineViewWidth, statusLineViewHeight);
  }
  else
  {
      statusLineViewY = (self.frontSideView.frame.size.height - statusLineViewHeight);
  }
  return CGRectMake(statusLineViewX, statusLineViewY, statusLineViewWidth, statusLineViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) statusLineSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.frontSideView;
  else
    return self.rightPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupActivityIndicatorView
{
  CGRect activityIndicatorFrame = [self activityIndicatorViewFrame];
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorFrame] autorelease];
  UIView* superView = [self activityIndicatorViewSuperview];
  [superView addSubview:self.activityIndicator];
  self.activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin);
  self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) activityIndicatorViewFrame
{
  int activityIndicatorViewWidth = [UiElementMetrics activityIndicatorWidthAndHeight];
  int activityIndicatorViewHeight = [UiElementMetrics activityIndicatorWidthAndHeight];
  int activityIndicatorViewX = CGRectGetMaxX(self.playView.boardFrame) - activityIndicatorViewWidth;
  int activityIndicatorViewY = CGRectGetMaxY(self.playView.frame) - activityIndicatorViewHeight;
  return CGRectMake(activityIndicatorViewX, activityIndicatorViewY, activityIndicatorViewWidth, activityIndicatorViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) activityIndicatorViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return self.frontSideView;
  else
    return self.rightPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListView
{
  self.boardPositionListView = [[ItemScrollView alloc] initWithFrame:[self boardPositionListViewFrame]
                                                         orientation:ItemScrollViewOrientationHorizontal];
  self.boardPositionListView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  self.boardPositionListView.backgroundColor = [UIColor clearColor];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) boardPositionListViewFrame
{
  int listViewX = 0;
  int listViewY = 0;
  int listViewWidth = (self.toolbarBoardPositionNavigation.frame.size.width
                       - (2 * [UiElementMetrics toolbarPaddingHorizontal])
                       - self.boardPositionViewMetrics.boardPositionViewWidth
                       - (2 * [UiElementMetrics toolbarSpacing]));
  int listViewHeight = self.boardPositionViewMetrics.boardPositionViewHeight;
  return CGRectMake(listViewX, listViewY, listViewWidth, listViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupCurrentBoardPositionView
{
  self.currentBoardPositionView = [[[BoardPositionView alloc] initWithBoardPosition:-1
                                                                        viewMetrics:self.boardPositionViewMetrics] autorelease];
  self.currentBoardPositionView.frame = [self currentBoardPositionViewFrame];
  self.currentBoardPositionView.currentBoardPosition = true;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) currentBoardPositionViewFrame
{
  int boardPositionViewX = 0;
  int boardPositionViewY = 0;
  int boardPositionViewWidth = self.boardPositionViewMetrics.boardPositionViewWidth;
  int boardPositionViewHeight = self.boardPositionViewMetrics.boardPositionViewHeight;
  return CGRectMake(boardPositionViewX, boardPositionViewY, boardPositionViewWidth, boardPositionViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListContainerView
{
  CGRect boardPositionListContainerViewFrame = [self boardPositionListContainerViewFrame];
  self.boardPositionListContainerView = [[[UIView alloc] initWithFrame:boardPositionListContainerViewFrame] autorelease];
  UIView* superView = [self boardPositionListContainerViewSuperview];
  [superView addSubview:self.boardPositionListContainerView];

  self.boardPositionListContainerView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (CGRect) boardPositionListContainerViewFrame
{
  UIView* superView = [self boardPositionListContainerViewSuperview];
  int listViewX = 0;
  int listViewY = CGRectGetMaxY(self.toolbarBoardPositionNavigation.frame);
  int listViewWidth = [UiElementMetrics splitViewLeftPaneWidth];
  int listViewHeight = (superView.frame.size.height - listViewY);
  return CGRectMake(listViewX, listViewY, listViewWidth, listViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (UIView*) boardPositionListContainerViewSuperview
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return nil;
  else
    return self.leftPaneViewController.view;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked when the front side view
/// hierarchy is created.
// -----------------------------------------------------------------------------
- (void) setupDebugView
{
  DebugPlayViewController* debugPlayViewController = [[DebugPlayViewController alloc] init];
  [self.frontSideView addSubview:debugPlayViewController.view];
  CGRect debugPlayViewFrame = debugPlayViewController.view.frame;
  debugPlayViewFrame.origin.y += self.toolbarMain.frame.size.height;
  debugPlayViewController.view.frame = debugPlayViewFrame;
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  if (! delegate.applicationReadyForAction)
  {
    self.controllerReadyForAction = false;
    NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(applicationIsReadyForAction:) name:applicationIsReadyForAction object:nil];
  }
  else
  {
    [self makeControllerReadyForAction];
    self.controllerReadyForAction = true;
  }
}

// -----------------------------------------------------------------------------
/// @brief Sets up this controller and makes it "ready for action".
// -----------------------------------------------------------------------------
- (void) makeControllerReadyForAction
{
  [self setupSubviewsOfFrontSideView];
  [self setupSubcontrollers];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupSubviewsOfFrontSideView
{
  self.boardPositionViewMetrics = [[[BoardPositionViewMetrics alloc] init] autorelease];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    [self setupToolbarMain];
    [self setupToolbarBoardPositionNavigation];
    [self setupPlayView];
    [self setupActivityIndicatorView];
    [self setupStatusLineView];
    [self setupBoardPositionListView];
    [self setupCurrentBoardPositionView];
  }
  else
  {
    [self setupSplitView];
    [self setupToolbarMain];
    [self setupToolbarBoardPositionNavigation];
    [self setupPlayView];
    [self setupActivityIndicatorView];
    [self setupStatusLineView];
    [self setupBoardPositionListContainerView];
  }
  // Activate the following code to display controls that you can use to change
  // Play view drawing parameters that are normally immutable at runtime. This
  // is nice for debugging changes to the drawing system.
  //  [self setupDebugView];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupSubcontrollers
{
  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  if (! scoringModel)
  {
    DDLogError(@"PlayViewController::makeControllerReadyForAction(): Unable to find the ScoringModel object");
    assert(0);
  }

  self.toolbarController = [[[ToolbarController alloc] initWithToolbar:self.toolbarMain
                                                          scoringModel:scoringModel
                                                              delegate:self
                                                  parentViewController:self] autorelease];
  self.statusLineController = [StatusLineController controllerWithStatusLine:self.statusLine];
  self.activityIndicatorController = [ActivityIndicatorController controllerWithActivityIndicator:self.activityIndicator];

  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] initWithToolbar:self.toolbarBoardPositionNavigation
                                                                             boardPositionListView:self.boardPositionListView
                                                                          currentBoardPositionView:self.currentBoardPositionView] autorelease];
  }
  else
  {
    self.boardPositionToolbarController = [[[BoardPositionToolbarController alloc] initWithToolbar:self.toolbarBoardPositionNavigation] autorelease];
  }

  self.boardPositionListViewController = [[[BoardPositionListViewController alloc] initWithBoardPositionListView:self.boardPositionListView
                                                                                                     viewMetrics:self.boardPositionViewMetrics] autorelease];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    self.currentBoardPositionViewController = [[[CurrentBoardPositionViewController alloc] initWithCurrentBoardPositionView:self.currentBoardPositionView] autorelease];
    self.currentBoardPositionViewController.delegate = self;
  }
  else
  {
    self.boardPositionTableListViewController = [[[BoardPositionTableListViewController alloc] initWithContainerView:self.boardPositionListContainerView] autorelease];
  }
  self.panGestureController = [[[PanGestureController alloc] initWithPlayView:self.playView scoringModel:scoringModel delegate:self] autorelease];
  self.tapGestureController = [[[TapGestureController alloc] initWithPlayView:self.playView scoringModel:scoringModel] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  self.frontSideView = nil;
  self.backSideView = nil;
  self.playView = nil;
  self.toolbarMain = nil;
  self.toolbarBoardPositionNavigation = nil;
  self.boardPositionViewMetrics = nil;
  self.boardPositionListView = nil;
  self.currentBoardPositionView = nil;
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.boardPositionListContainerView = nil;
  self.splitViewController = nil;
  self.leftPaneViewController = nil;
  self.rightPaneViewController = nil;
  self.toolbarController = nil;
  self.statusLineController = nil;
  self.activityIndicatorController = nil;
  self.boardPositionToolbarController = nil;
  self.boardPositionListViewController = nil;
  self.currentBoardPositionViewController = nil;
  self.boardPositionTableListViewController = nil;
  self.panGestureController = nil;
  self.tapGestureController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit when the view is about to made visible.
// -----------------------------------------------------------------------------
- (void) viewWillAppear:(BOOL)animated
{
  // Default does nothing, we don't have to invoke [super viewWillAppear]

  // If an interface orientation change occurred while the "Play" tab was not
  // visible, this controller's roation handling in
  // willAnimateRotationToInterfaceOrientation:duration:() was never executed.
  // We therefore provide some additional handling here.

  // Either the frontside or the backside view is currently not part of the
  // view hierarchy, so we must update it manually. The other one who *IS* part
  // of the view hierarchy has already been automatically updated by UIKit.
  if (! self.frontSideView.superview)
    self.frontSideView.frame = self.view.bounds;
  else
    self.backSideView.frame = self.view.bounds;
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit from within an animation block, before performing a
/// one-step user interface rotation.
///
/// By the time this method is invoked, the controller's interfaceOrientation
/// property already has the new orientation.
// -----------------------------------------------------------------------------
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
  if (self.frontSideView.superview)
  {
    // Manually update backside view because it is currently not part of the
    // view hierarchy
    self.backSideView.frame = self.view.bounds;
  }
  else
  {
    // Manually update frontside view because it is currently not part of the
    // view hierarchy
    self.frontSideView.frame = self.view.bounds;
  }
}

// -----------------------------------------------------------------------------
/// @brief ToolbarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) toolbarController:(ToolbarController*)controller playOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypePlay withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief ToolbarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) toolbarController:(ToolbarController*)controller discardOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypeDiscard withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief ToolbarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) toolbarController:(ToolbarController*)controller makeVisible:(bool)makeVisible gameInfoView:(UIView*)gameInfoView
{
  if (makeVisible)
  {
    [self.backSideView addSubview:gameInfoView];
    bool flipToFrontSideView = false;
    [self flipToFrontSideView:flipToFrontSideView];
  }
  else
  {
    [gameInfoView removeFromSuperview];
    bool flipToFrontSideView = true;
    [self flipToFrontSideView:flipToFrontSideView];
  }
}

// -----------------------------------------------------------------------------
/// @brief Flips the main play view (on the frontside) over to the game info
/// view (on the backside), and vice versa.
// -----------------------------------------------------------------------------
- (void) flipToFrontSideView:(bool)flipToFrontSideView
{
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.75];
  
  if (flipToFrontSideView)
  {
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.view cache:YES];
    [backSideView removeFromSuperview];
    [self.view addSubview:frontSideView];
  }
  else
  {
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:self.view cache:YES];
    [frontSideView removeFromSuperview];
    [self.view addSubview:backSideView];
  }
  [UIView commitAnimations];
}

// -----------------------------------------------------------------------------
/// @brief PanGestureControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(CommandBase*)command
{
  [self alertOrAction:ActionTypePlay withCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief CurrentBoardPositionViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didTapCurrentBoardPositionViewController:(CurrentBoardPositionViewController*)controller
{
  [self.boardPositionToolbarController toggleToolbarItems];
}

// -----------------------------------------------------------------------------
/// @brief UIAlertViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  CommandBase* command = objc_getAssociatedObject(alertView, associatedCommandObjectKey);
  objc_setAssociatedObject(alertView, associatedCommandObjectKey, nil, OBJC_ASSOCIATION_ASSIGN);
  switch (buttonIndex)
  {
    case AlertViewButtonTypeNo:
    {
      [command release];
      command = nil;
    }
    case AlertViewButtonTypeYes:
    {
      [command submit];  // deallocates the command
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #applicationIsReadyForAction notification.
// -----------------------------------------------------------------------------
- (void) applicationIsReadyForAction:(NSNotification*)notification
{
  // We only need this notification once
  [[NSNotificationCenter defaultCenter] removeObserver:self name:applicationIsReadyForAction object:nil];
  
  [self makeControllerReadyForAction];
  self.controllerReadyForAction = true;
}

// -----------------------------------------------------------------------------
/// @brief Executes @a command, or displays an alert and delays execution until
/// the alert is dismissed by the user.
///
/// @a actionType is used to tweak the alert message so that contains a useful
/// description of what the user tries to do.
///
/// @a command must have a retain count of 1 so that the command's submit()
/// method can be invoked.
///
/// If the Play view currently displays the last board position of the game,
/// @a command is executed immediately.
///
/// If the Play view displays a board position in the middle of the game, an
/// alert is shown that warns the user that discarding now will discard all
/// future board positions. If the user confirms that this is OK, @a command is
/// executed. If the user cancels the operation, @a command is not executed.
/// Handling of the user's response happens in
/// alertView:didDismissWithButtonIndex:().
///
/// The user can suppress the alert in the user preferences. In this case
/// @a command is immediately executed.
// -----------------------------------------------------------------------------
- (void) alertOrAction:(enum ActionType)actionType withCommand:(CommandBase*)command
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPosition.isLastPosition || ! boardPositionModel.discardFutureMovesAlert)
  {
    [command submit];  // deallocates the command
  }
  else
  {
    NSString* actionDescription;
    if (ActionTypePlay == actionType)
    {
      if (GoGameTypeComputerVsComputer == [GoGame sharedGame].type)
        actionDescription = @"If you let the computer play now,";
      else
      {
        // Use a generic expression because we don't know which user interaction
        // triggered the alert (could be a pass move, a play move (via panning),
        // or the "computer play" function).
        actionDescription = @"If you play now,";
      }
    }
    else
    {
      if (boardPosition.isFirstPosition)
        actionDescription = @"If you proceed,";
      else
        actionDescription = @"If you proceed not only this move, but";
    }
    NSString* formatString;
    if (boardPosition.isFirstPosition)
      formatString = @"You are looking at the board position at the beginning of the game. %@ all moves of the entire game will be discarded.\n\nDo you want to continue?";
    else
      formatString = @"You are looking at a board position in the middle of the game. %@ all moves that have been made after this position will be discarded.\n\nDo you want to continue?";
    NSString* messageString = [NSString stringWithFormat:formatString, actionDescription];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Future moves will be discarded"
                                                    message:messageString
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = AlertViewTypeActionWillDiscardAllFutureMoves;
    [alert show];
    // Store command object for later use by the alert handler
    objc_setAssociatedObject(alert, associatedCommandObjectKey, command, OBJC_ASSOCIATION_ASSIGN);
  }
}

@end
