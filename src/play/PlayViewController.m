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
#import "PlayViewModel.h"
#import "StatusLineController.h"
#import "ToolbarController.h"
#import "boardposition/BoardPositionListController.h"
#import "boardposition/BoardPositionModel.h"
#import "boardposition/BoardPositionViewMetrics.h"
#import "gesture/TapGestureController.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../command/boardposition/DiscardAndPlayCommand.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"

// System includes
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>


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
- (void) toolbarControllerAlertCannotPlayOnComputersTurn:(ToolbarController*)controller;
- (void) toolbarController:(ToolbarController*)controller playOrAlertWithCommand:(DiscardAndPlayCommand*)command;
- (void) toolbarController:(ToolbarController*)controller makeVisible:(bool)makeVisible gameInfoView:(UIView*)gameInfoView;
//@}
/// @name PanGestureControllerDelegate protocol
//@{
- (void) panGestureControllerAlertCannotPlayOnComputersTurn:(PanGestureController*)controller;
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(DiscardAndPlayCommand*)command;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name Notification responders
//@{
- (void) applicationIsReadyForAction:(NSNotification*)notification;
//@}
/// @name Private helpers
//@{
- (void) makeControllerReadyForAction;
- (void) setupMainView;
- (void) setupSubviews;
- (void) setupToolbar;
- (void) setupPlayView;
- (void) setupActivityIndicatorView;
- (void) setupStatusLineView;
- (void) setupBoardPositionListView;
- (void) setupDebugView;
- (CGRect) mainViewFrame;
- (CGRect) subviewFrame;
- (CGRect) toolbarFrame;
- (CGRect) playViewFrame;
- (CGPoint) boardPositionListViewPosition;
- (CGRect) statusLineViewFrame;
- (CGRect) activityIndicatorViewFrame;
- (void) flipToFrontSideView:(bool)flipToFrontSideView;
- (void) playOrAlertWithCommand:(DiscardAndPlayCommand*)command;
- (void) alertCannotPlayOnComputersTurn;
//@}
/// @name Privately declared properties
//@{
/// @brief True if this controller has been set up is now "ready for action".
@property(nonatomic, assign) bool controllerReadyForAction;
/// @brief The frontside view. A superview of @e playView.
@property(nonatomic, retain) UIView* frontSideView;
/// @brief The backside view with information about the current game.
@property(nonatomic, retain) UIView* backSideView;
/// @brief The view that PlayViewController is responsible for.
@property(nonatomic, retain) PlayView* playView;
/// @brief The toolbar that displays action buttons.
@property(nonatomic, retain) UIToolbar* toolbar;
/// @brief The view that displays the list of board positions in the current
/// game.
@property(nonatomic, retain) ItemScrollView* boardPositionListView;
/// @brief The status line that displays messages to the user.
@property(nonatomic, retain) UILabel* statusLine;
/// @brief The activity indicator that is animated for long running operations.
@property(nonatomic, retain) UIActivityIndicatorView* activityIndicator;
/// @brief The controller that manages the toolbar.
@property(nonatomic, retain) ToolbarController* toolbarController;
/// @brief The controller that manages the board position list.
@property(nonatomic, retain) BoardPositionListController* boardPositionListController;
/// @brief The controller that manages the status line.
@property(nonatomic, retain) StatusLineController* statusLineController;
/// @brief The controller that manages the activity indicator.
@property(nonatomic, retain) ActivityIndicatorController* activityIndicatorController;
/// @brief The controller that manages panning gestures.
@property(nonatomic, retain) PanGestureController* panGestureController;
/// @brief The controller that manages tapping gestures.
@property(nonatomic, retain) TapGestureController* tapGestureController;
//@}
@end


@implementation PlayViewController

@synthesize controllerReadyForAction;
@synthesize frontSideView;
@synthesize backSideView;
@synthesize playView;
@synthesize toolbar;
@synthesize boardPositionListView;
@synthesize statusLine;
@synthesize activityIndicator;
@synthesize toolbarController;
@synthesize boardPositionListController;
@synthesize statusLineController;
@synthesize activityIndicatorController;
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
  self.toolbar = nil;
  self.boardPositionListView = nil;
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.toolbarController = nil;
  self.boardPositionListController = nil;
  self.statusLineController = nil;
  self.activityIndicatorController = nil;
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
  [self setupSubviews];

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
- (void) setupSubviews
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
/// @brief This is an internal helper invoked by setupSubviews().
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
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupToolbar
{
  CGRect toolbarFrame = [self toolbarFrame];
  self.toolbar = [[[UIToolbar alloc] initWithFrame:toolbarFrame] autorelease];
  [self.frontSideView addSubview:self.toolbar];
  self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupToolbar().
// -----------------------------------------------------------------------------
- (CGRect) toolbarFrame
{
  CGSize superViewSize = self.frontSideView.bounds.size;
  int toolbarViewX = 0;
  int toolbarViewY = 0;
  int toolbarViewWidth = superViewSize.width;
  int toolbarViewHeight = [UiElementMetrics toolbarHeight];
  return CGRectMake(toolbarViewX, toolbarViewY, toolbarViewWidth, toolbarViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupPlayView
{
  CGRect playViewFrame = [self playViewFrame];
  self.playView = [[[PlayView alloc] initWithFrame:playViewFrame] autorelease];
  [self.frontSideView addSubview:self.playView];
  self.playView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin);
  self.playView.backgroundColor = [UIColor clearColor];
  // If the view is resized, the Go board needs to be redrawn (occurs during
  // rotation animation)
  self.playView.contentMode = UIViewContentModeRedraw;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupPlayView().
// -----------------------------------------------------------------------------
- (CGRect) playViewFrame
{
  // Dimensions if all the available space were used. The result would be a
  // rectangle.
  CGSize superViewSize = self.frontSideView.bounds.size;
  int playViewFullWidth = superViewSize.width;
  int playViewFullHeight = superViewSize.height - self.toolbar.frame.size.height;

  // Now make the view square so that auto-rotation on orientation change does
  // not cause the view to be squashed or stretched. This is possibly not
  // necessary anymore, because now there is a custom animation going on during
  // auto-rotation that resizes the view to its proper dimensions.
  // Note: There's already a small bit of code in PlayView that lets it handle
  // rectangular frames.
  int playViewSideLength;
  if (playViewFullHeight >= playViewFullWidth)
    playViewSideLength = playViewFullWidth;
  else
    playViewSideLength = playViewFullHeight;

  // Calculate the final values
  int playViewX = floor((superViewSize.width - playViewSideLength) / 2);  // center horizontally
  int playViewY = (self.toolbar.frame.origin.y
                   + self.toolbar.frame.size.height);
  int playViewWidth = playViewSideLength;
  int playViewHeight = playViewSideLength;
  return CGRectMake(playViewX, playViewY, playViewWidth, playViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupActivityIndicatorView
{
  CGRect activityIndicatorFrame = [self activityIndicatorViewFrame];
  self.activityIndicator = [[[UIActivityIndicatorView alloc] initWithFrame:activityIndicatorFrame] autorelease];
  [self.frontSideView addSubview:self.activityIndicator];
  self.activityIndicator.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin);
  self.activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupActivityIndicatorView().
// -----------------------------------------------------------------------------
- (CGRect) activityIndicatorViewFrame
{
  CGRect boardFrame = self.playView.boardFrame;
  int activityIndicatorViewX = (boardFrame.origin.x
                                + boardFrame.size.width
                                - [UiElementMetrics activityIndicatorWidthAndHeight]);
  int activityIndicatorViewY = boardFrame.origin.y + boardFrame.size.height;
  int activityIndicatorViewWidth = [UiElementMetrics activityIndicatorWidthAndHeight];
  int activityIndicatorViewHeight = [UiElementMetrics activityIndicatorWidthAndHeight];
  return CGRectMake(activityIndicatorViewX, activityIndicatorViewY, activityIndicatorViewWidth, activityIndicatorViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupStatusLineView
{
  CGRect statusLineViewFrame = [self statusLineViewFrame];
  self.statusLine = [[[UILabel alloc] initWithFrame:statusLineViewFrame] autorelease];
  [self.frontSideView addSubview:self.statusLine];
  self.statusLine.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth);
  self.statusLine.backgroundColor = [UIColor clearColor];
  self.statusLine.lineBreakMode = UILineBreakModeWordWrap;
  self.statusLine.numberOfLines = 1;
  self.statusLine.font = [UIFont systemFontOfSize:[BoardPositionViewMetrics boardPositionViewFontSize]];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupStatusLineView().
// -----------------------------------------------------------------------------
- (CGRect) statusLineViewFrame
{
  CGRect boardFrame = self.playView.boardFrame;
  CGRect activityIndicatorFrame = self.activityIndicator.frame;
  int statusLineViewX = boardFrame.origin.x;
  int statusLineViewWidth = (boardFrame.size.width
                             - [UiElementMetrics spacingHorizontal]
                             - activityIndicatorFrame.size.width);
  UIFont* statusLineViewFont = [UIFont systemFontOfSize:[BoardPositionViewMetrics boardPositionViewFontSize]];
  CGSize constraintSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
  CGSize statusLineTextSize = [@"A" sizeWithFont:statusLineViewFont
                               constrainedToSize:constraintSize
                                   lineBreakMode:UILineBreakModeWordWrap];
  int statusLineViewHeight = statusLineTextSize.height;
  int statusLineViewY = (boardFrame.origin.y
                         + boardFrame.size.height
                         + floor((activityIndicatorFrame.size.height - statusLineViewHeight) / 2));
  return CGRectMake(statusLineViewX, statusLineViewY, statusLineViewWidth, statusLineViewHeight);
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupBoardPositionListView
{
  self.boardPositionListController = [[[BoardPositionListController alloc] init] autorelease];
  self.boardPositionListView = self.boardPositionListController.boardPositionListView;
  CGRect boardPositionListViewFrame = self.boardPositionListView.frame;
  boardPositionListViewFrame.origin = [self boardPositionListViewPosition];
  self.boardPositionListView.frame = boardPositionListViewFrame;
  [self.frontSideView addSubview:self.boardPositionListView];
  self.boardPositionListView.backgroundColor = [UIColor clearColor];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by setupBoardPositionListView().
// -----------------------------------------------------------------------------
- (CGPoint) boardPositionListViewPosition
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
  {
    // TODO xxx either let controller do this, or do it all here
    CGRect activityIndicatorFrame = self.activityIndicator.frame;
    int boardPositionListViewX = self.playView.boardFrame.origin.x;
    int boardPositionListViewY = (activityIndicatorFrame.origin.y
                                  + activityIndicatorFrame.size.height);
    return CGPointMake(boardPositionListViewX, boardPositionListViewY);
  }
  else
  {
    // TODO xxx implement for iPad; take orientation into account
    NSException* exception = [NSException exceptionWithName:NSGenericException
                                                     reason:@"Not implemented yet"
                                                   userInfo:nil];
    @throw exception;
  }
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by makeControllerReadyForAction().
// -----------------------------------------------------------------------------
- (void) setupDebugView
{
  DebugPlayViewController* debugPlayViewController = [[DebugPlayViewController alloc] init];
  [self.frontSideView addSubview:debugPlayViewController.view];
  CGRect debugPlayViewFrame = debugPlayViewController.view.frame;
  debugPlayViewFrame.origin.y += self.toolbar.frame.size.height;
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
  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  if (! scoringModel)
  {
    DDLogError(@"PlayViewController::makeControllerReadyForAction(): Unable to find the ScoringModel object");
    assert(0);
  }

  [self setupToolbar];
  [self setupPlayView];
  [self setupActivityIndicatorView];
  [self setupStatusLineView];
  [self setupBoardPositionListView];
  // Activate the following code to display controls that you can use to change
  // Play view drawing parameters that are normally immutable at runtime. This
  // is nice for debugging changes to the drawing system.
//  [self setupDebugView];
  
  self.toolbarController = [[[ToolbarController alloc] initWithToolbar:self.toolbar
                                                          scoringModel:scoringModel
                                                              delegate:self
                                                  parentViewController:self] autorelease];
  self.statusLineController = [StatusLineController controllerWithStatusLine:self.statusLine];
  self.activityIndicatorController = [ActivityIndicatorController controllerWithActivityIndicator:self.activityIndicator];
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
  self.toolbar = nil;
  self.boardPositionListView = nil;
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.toolbarController = nil;
  self.boardPositionListController = nil;
  self.statusLineController = nil;
  self.activityIndicatorController = nil;
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
  // Calculate the PlayView frame only after we can be sure that the superview's
  // bounds are correct (either by the manual update above, or by an automatic
  // update by UIKit).
  CGRect currentPlayViewFrame = self.playView.frame;
  CGRect newPlayViewFrame = [self playViewFrame];
  if (! CGRectEqualToRect(currentPlayViewFrame, newPlayViewFrame))
  {
    // Apparently UIKit invokes viewWillAppear:() while an animation is running.
    // This usage of CATransaction prevents the size change from being animated.
    // If we don't do this, a shrinking animation will take place when an
    // interface rotation to landscape occurred.
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.playView.frame = newPlayViewFrame;
    [self.playView frameChanged];
    [CATransaction commit];
  }
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
/// @brief Called by UIKit before performing a one-step user interface
/// rotation.
// -----------------------------------------------------------------------------
- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
  if (self.frontSideView.superview)
  {
    // Manually update backside view because it is currently not part of the
    // view hierarchy
    self.backSideView.frame = self.view.bounds;
    // The frontside view is part of the view hierarchy, so its bounds have
    // been automatically changed and we can safely calculate the new PlayView
    // frame
    CGRect playViewFrame = [self playViewFrame];
    // Because we don't allow the Play view to autoresize we need to perform its
    // animation ourselves.
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationCurveEaseOut
                     animations:^{
                       self.playView.frame = playViewFrame;
                       [self.playView frameChanged];
                     }
                     completion:NULL];
  }
  else
  {
    // Manually update frontside view because it is currently not part of the
    // view hierarchy
    self.frontSideView.frame = self.view.bounds;
    // Calculate the PlayView frame only after the manual change of its
    // superview's bounds
    CGRect playViewFrame = [self playViewFrame];
    // The PlayView is not visible, so no need to animate the frame size change
    self.playView.frame = playViewFrame;
    [self.playView frameChanged];
  }
}

// -----------------------------------------------------------------------------
/// @brief ToolbarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) toolbarControllerAlertCannotPlayOnComputersTurn:(ToolbarController*)controller
{
  [self alertCannotPlayOnComputersTurn];
}

// -----------------------------------------------------------------------------
/// @brief ToolbarControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) toolbarController:(ToolbarController*)controller playOrAlertWithCommand:(DiscardAndPlayCommand*)command
{
  [self playOrAlertWithCommand:command];
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
- (void) panGestureControllerAlertCannotPlayOnComputersTurn:(PanGestureController*)controller
{
  [self alertCannotPlayOnComputersTurn];
}

// -----------------------------------------------------------------------------
/// @brief PanGestureControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) panGestureController:(PanGestureController*)controller playOrAlertWithCommand:(DiscardAndPlayCommand*)command
{
  [self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (AlertViewTypePlayingNowWillDiscardAllFutureMoves != alertView.tag)
    return;
  DiscardAndPlayCommand* discardAndPlayCommand = objc_getAssociatedObject(alertView, "discardAndPlayCommand");
  objc_setAssociatedObject(alertView, "discardAndPlayCommand", nil, OBJC_ASSOCIATION_ASSIGN);
  switch (buttonIndex)
  {
    case AlertViewButtonTypeNo:
    {
      [discardAndPlayCommand release];
      discardAndPlayCommand = nil;
    }
    case AlertViewButtonTypeYes:
    {
      [discardAndPlayCommand submit];  // deallocates the command
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
/// @a command is set up so that it knows what type of move it should generate.
/// See the class documentation of DiscardAndPlayCommand for details about which
/// types of moves are supported. @a command must have a retain count of 1 so
/// that the command's submit() method can be invoked.
///
/// If the Play view currently displays the board position after the most recent
/// move, @a command is executed immediately.
///
/// If a board position in the middle of the game is displayed, an alert is
/// displayed that warns the user that playing now will discard all future
/// moves. If the user confirms that this is OK, @a command is executed. If the
/// user cancels the operation, @a command is not executed. Handling of the
/// user's response happens in alertView:didDismissWithButtonIndex:().
///
/// The user can suppress the alert in the user preferences. In this case
/// @a command is immediately executed.
// -----------------------------------------------------------------------------
- (void) playOrAlertWithCommand:(DiscardAndPlayCommand*)command
{
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPosition.isLastPosition || ! boardPositionModel.discardFutureMovesAlert)
  {
    [command submit];  // deallocates the command
  }
  else
  {
    NSString* messageString;
    NSString* formatString = @"You are looking at a board position in the middle of the game. %@, all moves that have been made after this position will be discarded.\n\nDo you want to continue?";
    if (GoGameTypeComputerVsComputer == [GoGame sharedGame].type)
      messageString = [NSString stringWithFormat:formatString, @"If you let the computer play now"];
    else
      messageString = [NSString stringWithFormat:formatString, @"If you play now"];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Future moves will be discarded"
                                                    message:messageString
                                                   delegate:self
                                          cancelButtonTitle:@"No"
                                          otherButtonTitles:@"Yes", nil];
    alert.tag = AlertViewTypePlayingNowWillDiscardAllFutureMoves;
    [alert show];
    // Store command object for later use by the alert handler
    objc_setAssociatedObject(alert, "discardAndPlayCommand", command, OBJC_ASSOCIATION_ASSIGN);
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays the alert #AlertViewTypeCannotPlayOnComputersTurn.
///
/// The user can suppress the alert in the user preferences.
// -----------------------------------------------------------------------------
- (void) alertCannotPlayOnComputersTurn
{
  BoardPositionModel* boardPositionModel = [ApplicationDelegate sharedDelegate].boardPositionModel;
  if (boardPositionModel.playOnComputersTurnAlert)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Cannot play during computer's turn"
                                                    message:@"You are looking at a board position where it is the computer's turn to play. To make a move you must first view a position where it is your turn to play.\n\nNote: You can disable this alert in the board position settings."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeCannotPlayOnComputersTurn;
    // Displaying an alert cancels this round of gesture recognizing (i.e.
    // the gesture recognizer sends UIGestureRecognizerStateCancelled)
    [alert show];
  }
}

@end
