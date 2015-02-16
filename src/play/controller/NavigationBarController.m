// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "NavigationBarController.h"
#import "GameInfoViewController.h"
#import "StatusViewController.h"
#import "../model/BoardViewModel.h"
#import "../model/ScoringModel.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../command/gtp/InterruptComputerCommand.h"
#import "../../command/boardposition/ChangeAndDiscardCommand.h"
#import "../../command/boardposition/DiscardAndPlayCommand.h"
#import "../../command/game/PauseGameCommand.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LayoutManager.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../ui/AutoLayoutUtility.h"
#import "../../utility/UIDeviceAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NavigationBarController.
// -----------------------------------------------------------------------------
@interface NavigationBarController()
@property(nonatomic, retain) UINavigationBar* leftNavigationBar;
@property(nonatomic, retain) UINavigationBar* centerNavigationBar;
@property(nonatomic, retain) UINavigationBar* rightNavigationBar;
@property(nonatomic, retain) NSLayoutConstraint* leftNavigationBarWidthConstraint;
@property(nonatomic, retain) NSLayoutConstraint* rightNavigationBarWidthConstraint;
@property(nonatomic, assign) GameInfoViewController* gameInfoViewController;
@property(nonatomic, retain) GameActionsActionSheetController* gameActionsActionSheetController;
@property(nonatomic, assign) bool navigationBarsNeedsPopulation;
@property(nonatomic, assign) bool buttonStatesNeedUpdate;
@property(nonatomic, retain) UIBarButtonItem* computerPlayButton;
@property(nonatomic, retain) UIBarButtonItem* passButton;
@property(nonatomic, retain) UIBarButtonItem* discardBoardPositionButton;
@property(nonatomic, retain) UIBarButtonItem* pauseButton;
@property(nonatomic, retain) UIBarButtonItem* continueButton;
@property(nonatomic, retain) UIBarButtonItem* interruptButton;
@property(nonatomic, assign) UIBarButtonItem* barButtonItemForShowingTheHiddenViewController;
@property(nonatomic, retain) UIBarButtonItem* gameInfoButton;
@property(nonatomic, retain) UIBarButtonItem* gameActionsButton;
@property(nonatomic, retain) UIBarButtonItem* doneButton;
@end


@implementation NavigationBarController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NavigationBarController object.
///
/// @note This is the designated initializer of NavigationBarController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self releaseObjects];
  [self setupChildControllers];
  self.navigationBarsNeedsPopulation = false;
  self.buttonStatesNeedUpdate = false;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  [self releaseObjects];
  self.statusViewController = nil;
  self.delegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.leftNavigationBar = nil;
  self.centerNavigationBar = nil;
  self.rightNavigationBar = nil;
  self.leftNavigationBarWidthConstraint = nil;
  self.rightNavigationBarWidthConstraint = nil;
  self.gameInfoViewController = nil;
  self.gameActionsActionSheetController = nil;
  self.computerPlayButton = nil;
  self.passButton = nil;
  self.discardBoardPositionButton = nil;
  self.pauseButton = nil;
  self.continueButton = nil;
  self.interruptButton = nil;
  self.barButtonItemForShowingTheHiddenViewController = nil;
  self.gameInfoButton = nil;
  self.gameActionsButton = nil;
  self.doneButton = nil;
}

#pragma mark - Container view controller handling

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.statusViewController = [[[StatusViewController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setStatusViewController:(StatusViewController*)statusViewController
{
  if (_statusViewController == statusViewController)
    return;
  if (_statusViewController)
  {
    [_statusViewController willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [_statusViewController removeFromParentViewController];
    [_statusViewController release];
    _statusViewController = nil;
  }
  if (statusViewController)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:statusViewController];
    [statusViewController didMoveToParentViewController:self];
    [statusViewController retain];
    _statusViewController = statusViewController;
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [self createViews];
  [self setupViewHierarchy];
  [self setupAutoLayoutConstraints];
  [self setupNotificationResponders];

  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];

  // We need to be the Play tab navigation controller's delegate so that we
  // can properly push/pop the "Game Info" view controller
  self.navigationController.delegate = self;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  if ([LayoutManager sharedManager].uiType != UITypePhonePortraitOnly)
  {
    if (self.gameActionsActionSheetController)
    {
      // Dismiss the popover that displays the action sheet because the popover
      // will be wrongly positioned after the interface has rotated
      [self.gameActionsActionSheetController cancelActionSheet];
    }
  }
}

#pragma mark - Private helpers for loadView

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) createViews
{
  [super loadView];
  self.leftNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  self.centerNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  self.rightNavigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  [self.leftNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                    animated:NO];
  [self.centerNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                      animated:NO];
  [self.rightNavigationBar pushNavigationItem:[[[UINavigationItem alloc] initWithTitle:@""] autorelease]
                                     animated:NO];
  [self createButtons];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupViewHierarchy
{
  [self.view addSubview:self.leftNavigationBar];
  [self.view addSubview:self.centerNavigationBar];
  [self.view addSubview:self.rightNavigationBar];
  [self.view addSubview:self.statusViewController.view];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.leftNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.centerNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.rightNavigationBar.translatesAutoresizingMaskIntoConstraints = NO;
  self.statusViewController.view.translatesAutoresizingMaskIntoConstraints = NO;

  NSDictionary* viewsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                   self.leftNavigationBar, @"leftNavigationBar",
                                   self.centerNavigationBar, @"centerNavigationBar",
                                   self.rightNavigationBar, @"rightNavigationBar",
                                   self.statusViewController.view, @"statusView",
                                   nil];
  // Some notes:
  // - On the iPad we simply give each navigation bar the same width.
  // - On the iPhone there is not enough horizontal space to do the same, so
  //   further down we set up some width constraints, which will then be managed
  //   dynamically each time after the navigation bars are populated with
  //   buttons.
  // - Furthermore, we only need the center navigation bar to get the same
  //   translucent background for the status view, so we set up the status view
  //   to "hover" over the center navigation bar. In iOS 8 it would be possible
  //   achieve this simply by making the status view a subview of the center
  //   navigation bar and fill up the entirety of its superview. But in iOS 7
  //   the Auto Layout engine can't handle this for some reason. Since we still
  //   support iOS 7 we must therefore fall back to the solution of making the
  //   status view a subview of the main view and provide constraints that let
  //   the status view use the exact same position and size as the navigation
  //   bar over which it must "hover".
  NSArray* visualFormats = [NSArray arrayWithObjects:
                            (([LayoutManager sharedManager].uiType == UITypePhonePortraitOnly)
                             ? @"H:|-0-[leftNavigationBar]-0-[centerNavigationBar]-0-[rightNavigationBar]-0-|"
                             : @"H:|-0-[leftNavigationBar]-0-[centerNavigationBar(==leftNavigationBar)]-0-[rightNavigationBar(==leftNavigationBar)]-0-|"),
                            @"H:[leftNavigationBar]-0-[statusView(==centerNavigationBar)]",
                            @"V:|-0-[leftNavigationBar]-0-|",
                            @"V:|-0-[centerNavigationBar]-0-|",
                            @"V:|-0-[rightNavigationBar]-0-|",
                            @"V:|-0-[statusView]-0-|",
                            nil];
  [AutoLayoutUtility installVisualFormats:visualFormats
                                withViews:viewsDictionary
                                   inView:self.view];

  if ([LayoutManager sharedManager].uiType == UITypePhonePortraitOnly)
  {
    self.leftNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.leftNavigationBar
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:0.0f
                                                                          constant:0.0f];
    [self.view addConstraint:self.leftNavigationBarWidthConstraint];
    self.rightNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.rightNavigationBar
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:0.0f
                                                                           constant:0.0f];
    [self.view addConstraint:self.rightNavigationBarWidthConstraint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) createButtons
{
  self.computerPlayButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:computerPlayButtonIconResource]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(computerPlay:)] autorelease];
  self.passButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:passButtonIconResource]
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(pass:)] autorelease];
  self.discardBoardPositionButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:discardButtonIconResource]
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(discardBoardPosition:)] autorelease];
  self.pauseButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:pauseButtonIconResource]
                                                       style:UIBarButtonItemStyleBordered
                                                      target:self
                                                      action:@selector(pause:)] autorelease];
  self.continueButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:continueButtonIconResource]
                                                          style:UIBarButtonItemStyleBordered
                                                         target:self
                                                         action:@selector(continue:)] autorelease];
  self.interruptButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:interruptButtonIconResource]
                                                           style:UIBarButtonItemStyleBordered
                                                          target:self
                                                          action:@selector(interrupt:)] autorelease];
  self.gameInfoButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:gameInfoButtonIconResource]
                                                          style:UIBarButtonItemStyleBordered
                                                         target:self
                                                         action:@selector(gameInfo:)] autorelease];
  self.gameActionsButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                          target:self
                                                                          action:@selector(gameActions:)] autorelease];
  self.gameActionsButton.style = UIBarButtonItemStyleBordered;
  self.doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                   target:self
                                                                   action:@selector(done:)] autorelease];
  self.doneButton.style = UIBarButtonItemStyleBordered;
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreScoringEnabled:) name:goScoreScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringDisabled:) name:goScoreScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(boardViewWillDisplayCrossHair:) name:boardViewWillDisplayCrossHair object:nil];
  [center addObserver:self selector:@selector(boardViewWillHideCrossHair:) name:boardViewWillHideCrossHair object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pass" button. Generates a "Pass"
/// move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) pass:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring tap on pass button", self);
    return;
  }
  DiscardAndPlayCommand* command = [[[DiscardAndPlayCommand alloc] initPass] autorelease];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Delete" button. Discards the current
/// board position and all positions that follow afterwards.
// -----------------------------------------------------------------------------
- (void) discardBoardPosition:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring tap on discard button", self);
    return;
  }
  ChangeAndDiscardCommand* command = [[[ChangeAndDiscardCommand alloc] init] autorelease];
  [self.delegate navigationBarController:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Computer play" button. Causes the
/// computer player to generate a move, either for itself or on behalf of the
/// human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) computerPlay:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring tap on computer play button", self);
    return;
  }
  DiscardAndPlayCommand* command = [[[DiscardAndPlayCommand alloc] initComputerPlay] autorelease];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pause" button. Pauses the game if
/// two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) pause:(id)sender
{
  [[[[PauseGameCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Continue" button. Continues the game
/// if it is paused while two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) continue:(id)sender
{
  DiscardAndPlayCommand* command = [[[DiscardAndPlayCommand alloc] initContinue] autorelease];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Interrupt" button. Interrupts the
/// computer while it is thinking.
// -----------------------------------------------------------------------------
- (void) interrupt:(id)sender
{
  [[[[InterruptComputerCommand alloc] init] autorelease] submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info" button. Displays the
/// "Game Info" view with information about the game in progress.
// -----------------------------------------------------------------------------
- (void) gameInfo:(id)sender
{
  GoScore* score = [GoGame sharedGame].score;
  if (! score.scoringEnabled)
    [score calculateWaitUntilDone:true];
  self.gameInfoViewController = [[[GameInfoViewController alloc] init] autorelease];
  // We are the navigation controller's delegate. When
  // self.gameInfoViewController is pushed/popped we show the navigation
  // controller's navigation bar.
  [self.navigationController pushViewController:self.gameInfoViewController animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Game Actions" button. Displays an
/// action sheet with actions that related to Go games as a whole.
// -----------------------------------------------------------------------------
- (void) gameActions:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring tap on game actions button", self);
    return;
  }

  // We need the view that represents the "Game Actions" bar button item in the
  // navigation bar so that we can present an action sheet originating from that
  // view. There is no official API that lets us find the view, but we know that
  // the button is at the right-most end of the navigation bar, so we can find
  // the representing view by examining the frames of all navigation bar
  // subviews.
  UIView* rightMostSubview = nil;
  for (UIView* subview in self.rightNavigationBar.subviews)
  {
    if (rightMostSubview)
    {
      if (subview.frame.origin.x > rightMostSubview.frame.origin.x)
        rightMostSubview = subview;
    }
    else
    {
      rightMostSubview = subview;
    }
  }
  if (rightMostSubview)
  {
    self.gameActionsActionSheetController = [[[GameActionsActionSheetController alloc] initWithModalMaster:self.parentViewController delegate:self] autorelease];
    [self.gameActionsActionSheetController showActionSheetFromRect:rightMostSubview.bounds inView:rightMostSubview];
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Done" button. Ends the currently
/// active mode and returns to normal play mode.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [GoGame sharedGame].score.scoringEnabled = false;  // triggers notification to which this controller reacts
}

// -----------------------------------------------------------------------------
/// @brief Returns true if taps on bar button items should currently be
/// ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return [GoGame sharedGame].isComputerThinking;
}

#pragma mark - UINavigationControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UINavigationControllerDelegate protocol method.
///
/// We are the delegate of the navigation controller on the Play tab. Here we
/// make sure to show/hide the navigation bar when the "Game Info" view
/// controller is pushed/popped.
///
/// @note One interaction that is not obvious is that if the user taps on the
/// "Play" tab bar icon, the navigation controller will pop the "Game Info" view
/// controller!
// -----------------------------------------------------------------------------
- (void) navigationController:(UINavigationController*)navigationController
       willShowViewController:(UIViewController*)viewController
                     animated:(BOOL)animated
{
  if (viewController == self.gameInfoViewController)
  {
    self.navigationController.navigationBarHidden = NO;
  }
  else
  {
    self.navigationController.navigationBarHidden = YES;
    self.gameInfoViewController = nil;
  }
}

#pragma mark - GameActionsActionSheetDelegate overrides

// -----------------------------------------------------------------------------
/// @brief GameActionsActionSheetDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameActionsActionSheetControllerDidFinish:(GameActionsActionSheetController*)controller
{
  self.gameActionsActionSheetController = nil;
}

#pragma mark - SplitViewControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief SplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(SplitViewController*)svc
      willHideViewController:(UIViewController*)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem
{
  self.barButtonItemForShowingTheHiddenViewController = barButtonItem;
  barButtonItem.title = @"Moves";
  self.navigationBarsNeedsPopulation = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief SplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(SplitViewController*)svc
      willShowViewController:(UIViewController*)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem*)button
{
  self.barButtonItemForShowingTheHiddenViewController = nil;
  self.navigationBarsNeedsPopulation = true;
  [self delayedUpdate];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  // Dismiss the "Game Info" view when a new game is about to be started. This
  // typically occurs when a saved game is loaded from the archive.
  if (self.gameInfoViewController)
    [self.navigationController popViewControllerAnimated:YES];
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* boardPosition = newGame.boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded == game.state)
  {
    if ([ApplicationDelegate sharedDelegate].scoringModel.scoreWhenGameEnds)
    {
      // Only trigger scoring if it makes sense to do so. It specifically does
      // not make sense if a player resigned - that player has lost the game
      // by his own explicit action, so we don't need to calculate a score.
      if (GoGameHasEndedReasonTwoPasses == game.reasonForGameHasEnded)
      {
        game.score.scoringEnabled = true;
        [game.score calculateWaitUntilDone:false];
      }
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringEnabled:(NSNotification*)notification
{
  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringDisabled:(NSNotification*)notification
{
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
  self.navigationBarsNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillDisplayCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillDisplayCrossHair:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #boardViewWillHideCrossHair notifications.
// -----------------------------------------------------------------------------
- (void) boardViewWillHideCrossHair:(NSNotification*)notification
{
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == [GoGame sharedGame].boardPosition)
  {
    if ([keyPath isEqualToString:@"currentBoardPosition"])
    {
      // It's annoying to have buttons appear and disappear all the time, so
      // we try to minimize this by keeping the same buttons in the navigation
      // bar while the user is browsing board positions.
      self.buttonStatesNeedUpdate = true;
    }
    else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
    {
      self.navigationBarsNeedsPopulation = true;
    }
    [self delayedUpdate];
  }
}

#pragma mark - Delayed updating

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self populateNavigationBars];
  [self updateButtonStates];
}

#pragma mark - Navigation bar population

// -----------------------------------------------------------------------------
/// @brief Populates the navigation bars with buttons that are appropriate for
/// the #GoGameType currently in progress.
// -----------------------------------------------------------------------------
- (void) populateNavigationBars
{
  if (! self.navigationBarsNeedsPopulation)
    return;
  self.navigationBarsNeedsPopulation = false;

  [self populateLeftNavigationBar];
  [self populateRightNavigationBar];
  if ([LayoutManager sharedManager].uiType == UITypePhonePortraitOnly)
    [self updateNavigationBarWidths];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) populateLeftNavigationBar
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  if (game.score.scoringEnabled)
  {
    [barButtonItems addObject:self.doneButton];
    [barButtonItems addObject:self.discardBoardPositionButton];
  }
  else
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        if (GoGameStateGameIsPaused == game.state)
        {
          if (GoGameComputerIsThinkingReasonPlayerInfluence != game.reasonForComputerIsThinking)
            [barButtonItems addObject:self.continueButton];
        }
        else
        {
          if (GoGameStateGameHasEnded != game.state)
            [barButtonItems addObject:self.pauseButton];
        }
        if (game.isComputerThinking)
          [barButtonItems addObject:self.interruptButton];
        else
        {
          if (boardPosition.numberOfBoardPositions > 1)
            [barButtonItems addObject:self.discardBoardPositionButton];
        }
        break;
      }
      default:
      {
        if (game.isComputerThinking)
          [barButtonItems addObject:self.interruptButton];
        else
        {
          if (GoGameStateGameHasEnded != game.state)
          {
            [barButtonItems addObject:self.computerPlayButton];
            [barButtonItems addObject:self.passButton];
          }
          if (boardPosition.numberOfBoardPositions > 1)
            [barButtonItems addObject:self.discardBoardPositionButton];
        }
        break;
      }
    }
  }
  self.leftNavigationBar.topItem.leftBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) populateRightNavigationBar
{
  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  [barButtonItems addObject:self.gameActionsButton];
  [barButtonItems addObject:self.gameInfoButton];
  if (self.barButtonItemForShowingTheHiddenViewController)
    [barButtonItems addObject:self.barButtonItemForShowingTheHiddenViewController];
  self.rightNavigationBar.topItem.rightBarButtonItems = barButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBars().
// -----------------------------------------------------------------------------
- (void) updateNavigationBarWidths
{
  // This method is only called on the iPhone. We know that on the iPhone we can
  // never have more than 5 buttons that are simultaneously shown. With 16% per
  // button the following calculations leave 100 - (5 * 16) = 20% width for the
  // status view. This has has been experimentally determined to be sufficient
  // for all texts that can appear in the 5-button scenario.
  CGFloat widthPercentagePerButton = 0.16f;
  CGFloat leftNavigationBarWidthPercentage = (self.leftNavigationBar.topItem.leftBarButtonItems.count
                                              * widthPercentagePerButton);
  CGFloat rightNavigationBarWidthPercentage = (self.rightNavigationBar.topItem.rightBarButtonItems.count
                                               * widthPercentagePerButton);

  NSMutableArray* constraintsToRemove = [NSMutableArray array];
  NSMutableArray* constraintsToAdd = [NSMutableArray array];
  if (self.leftNavigationBarWidthConstraint.multiplier != leftNavigationBarWidthPercentage)
  {
    [constraintsToRemove addObject:self.leftNavigationBarWidthConstraint];
    self.leftNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.leftNavigationBar
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.view
                                                                         attribute:NSLayoutAttributeWidth
                                                                        multiplier:leftNavigationBarWidthPercentage
                                                                          constant:0.0f];
    [constraintsToAdd addObject:self.leftNavigationBarWidthConstraint];
  }
  if (self.rightNavigationBarWidthConstraint.multiplier != rightNavigationBarWidthPercentage)
  {
    [constraintsToRemove addObject:self.rightNavigationBarWidthConstraint];
    self.rightNavigationBarWidthConstraint = [NSLayoutConstraint constraintWithItem:self.rightNavigationBar
                                                                          attribute:NSLayoutAttributeWidth
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeWidth
                                                                         multiplier:rightNavigationBarWidthPercentage
                                                                           constant:0.0f];
    [constraintsToAdd addObject:self.rightNavigationBarWidthConstraint];
  }
  [self.view removeConstraints:constraintsToRemove];
  [self.view addConstraints:constraintsToAdd];
}

#pragma mark - Button state updating

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of all buttons in the navigation bar.
// -----------------------------------------------------------------------------
- (void) updateButtonStates
{
  if (! self.buttonStatesNeedUpdate)
    return;
  self.buttonStatesNeedUpdate = false;

  [self updateComputerPlayButtonState];
  [self updatePassButtonState];
  [self updateDiscardBoardPositionButtonState];
  [self updatePauseButtonState];
  [self updateContinueButtonState];
  [self updateInterruptButtonState];
  [self updateGameInfoButtonState];
  [self updateGameActionsButtonState];
  [self updateDoneButtonState];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Computer play" button.
// -----------------------------------------------------------------------------
- (void) updateComputerPlayButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled &&
      ! [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if (game.isComputerThinking)
          break;
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
          {
            enabled = YES;
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  self.computerPlayButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Pass" button.
// -----------------------------------------------------------------------------
- (void) updatePassButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled &&
      ! [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if (game.isComputerThinking)
          break;
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
          {
            GoBoardPosition* boardPosition = game.boardPosition;
            if (boardPosition.isComputerPlayersTurn)
              enabled = NO;
            else
              enabled = YES;
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  self.passButton.enabled = enabled;
}


// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Discard board position" button.
// -----------------------------------------------------------------------------
- (void) updateDiscardBoardPositionButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if ([ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    // always disabled
  }
  else if (game.score.scoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    if (! game.isComputerThinking)
      enabled = YES;
  }
  self.discardBoardPositionButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Pause" button.
// -----------------------------------------------------------------------------
- (void) updatePauseButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled &&
      ! [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch (game.state)
        {
          case GoGameStateGameHasStarted:
            enabled = YES;
            break;
          default:
            break;
        }
        break;
      }
      default:
        break;
    }
  }
  self.pauseButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Continue" button.
// -----------------------------------------------------------------------------
- (void) updateContinueButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if (! game.score.scoringEnabled &&
      ! [ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch (game.state)
        {
          case GoGameStateGameIsPaused:
            enabled = YES;
            break;
          default:
            break;
        }
        break;
      }
      default:
        break;
    }
  }
  self.continueButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Interrupt" button.
// -----------------------------------------------------------------------------
- (void) updateInterruptButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if ([ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    // always disabled
  }
  else if (game.score.scoringEnabled)
  {
    if (game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    if (game.isComputerThinking)
      enabled = YES;
  }
  self.interruptButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Info" button.
// -----------------------------------------------------------------------------
- (void) updateGameInfoButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if ([ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    // always disabled
  }
  else if (game.score.scoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    // It is important that the Game Info view cannot be displayed if the
    // computer is still thinking. Reason: When the computer has finished
    // thinking, some piece of game state will change. GameInfoViewController,
    // however, is not equipped to update its information dynamically. At best,
    // the Game Info view will display outdated information. At worst, the app
    // will crash - an actual case was issue #226, where the app crashed because
    // - The game ended while the Game Info view was visible
    // - GameInfoViewController reloaded some table view rows in reaction to
    //   user input on the Game Info view
    // - An unrelated table view section suddenly had a different number of
    //   rows (because the game had ended), causing UITableView to throw an
    //   exception
    if (! game.computerThinks)
      enabled = YES;
  }
  self.gameInfoButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Game Actions" button.
// -----------------------------------------------------------------------------
- (void) updateGameActionsButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if ([ApplicationDelegate sharedDelegate].boardViewModel.boardViewDisplaysCrossHair)
  {
    // always disabled
  }
  else if (game.score.scoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch (game.state)
        {
          case GoGameStateGameHasEnded:
            enabled = YES;
            break;
          case GoGameStateGameIsPaused:
            // Computer may still be thinking
            enabled = ! game.isComputerThinking;
            break;
          default:
            break;
        }
        break;
      }
      default:
      {
        if (game.isComputerThinking)
          break;
        switch (game.state)
        {
          default:
            enabled = YES;
            break;
        }
        break;
      }
    }
  }
  self.gameActionsButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Done" button.
// -----------------------------------------------------------------------------
- (void) updateDoneButtonState
{
  BOOL enabled = NO;
  GoGame* game = [GoGame sharedGame];
  if (game.score.scoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  self.doneButton.enabled = enabled;
}

@end
