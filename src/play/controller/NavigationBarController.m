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
#import "NavigationBarController.h"
#import "StatusViewController.h"
#import "../model/ScoringModel.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../command/InterruptComputerCommand.h"
#import "../../command/boardposition/ChangeAndDiscardCommand.h"
#import "../../command/boardposition/DiscardAndPlayCommand.h"
#import "../../command/game/PauseGameCommand.h"
#import "../../shared/LongRunningActionCounter.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../utility/UIDeviceAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NavigationBarController.
// -----------------------------------------------------------------------------
@interface NavigationBarController()
@property(nonatomic, retain) UINavigationBar* navigationBar;
@property(nonatomic, retain) GameInfoViewController* gameInfoViewController;
@property(nonatomic, assign) bool navigationBarNeedsPopulation;
@property(nonatomic, assign) bool buttonStatesNeedUpdate;
@property(nonatomic, retain) UIBarButtonItem* computerPlayButton;
@property(nonatomic, retain) UIBarButtonItem* passButton;
@property(nonatomic, retain) UIBarButtonItem* discardBoardPositionButton;
@property(nonatomic, retain) UIBarButtonItem* pauseButton;
@property(nonatomic, retain) UIBarButtonItem* continueButton;
@property(nonatomic, retain) UIBarButtonItem* interruptButton;
@property(nonatomic, retain) UIBarButtonItem* flexibleSpaceButtonLeft;
@property(nonatomic, retain) UIBarButtonItem* flexibleSpaceButtonRight;
@property(nonatomic, assign) UIBarButtonItem* barButtonItemForShowingTheHiddenViewController;
@property(nonatomic, retain) UIBarButtonItem* gameInfoButton;
@property(nonatomic, retain) UIBarButtonItem* gameActionsButton;
@property(nonatomic, retain) UIBarButtonItem* doneButton;
@property(nonatomic, retain) UIBarButtonItem* statusViewButton;
@end


@implementation NavigationBarController

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
  self.navigationBarNeedsPopulation = false;
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
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.statusViewController = [[[StatusViewController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.navigationBar = nil;
  self.gameInfoViewController = nil;
  self.computerPlayButton = nil;
  self.passButton = nil;
  self.discardBoardPositionButton = nil;
  self.pauseButton = nil;
  self.continueButton = nil;
  self.interruptButton = nil;
  self.flexibleSpaceButtonLeft = nil;
  self.flexibleSpaceButtonRight = nil;
  self.barButtonItemForShowingTheHiddenViewController = nil;
  self.gameInfoButton = nil;
  self.gameActionsButton = nil;
  self.doneButton = nil;
  self.statusViewButton = nil;
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
    [_statusViewController didMoveToParentViewController:self];
    [statusViewController retain];
    _statusViewController = statusViewController;
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.navigationBar = [[[UINavigationBar alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.navigationBar;
  self.navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

  UINavigationItem* navigationItem = [[[UINavigationItem alloc] initWithTitle:@""] autorelease];
  [self.navigationBar pushNavigationItem:navigationItem animated:NO];

  [self setupButtons];
  [self setupNotificationResponders];

  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewWillUnload
{
  [super viewWillUnload];
  [self removeNotificationResponders];
  [self releaseObjects];
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
    // Do not release anything in iOS 6 and later (as opposed to iOS 5 where we
    // are forced to release stuff in viewDidUnload). A run through Instruments
    // shows that releasing objects here frees between 100-300 KB. Since the
    // user is expected to switch back to the Play tab anyway, this gain is
    // only temporary.
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) setupButtons
{
  self.computerPlayButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:computerPlayButtonIconResource]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(computerPlay:)] autorelease];
  self.passButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:passButtonIconResource]
                                                      style:UIBarButtonItemStyleBordered
                                                     target:self
                                                     action:@selector(pass:)] autorelease];
  self.discardBoardPositionButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delete-to-left.png"]
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
  self.flexibleSpaceButtonLeft = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:nil
                                                                                action:nil] autorelease];
  self.flexibleSpaceButtonRight = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                 target:nil
                                                                                 action:nil] autorelease];
  self.statusViewButton = [[[UIBarButtonItem alloc] initWithCustomView:self.statusViewController.view] autorelease];
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
  [center addObserver:self selector:@selector(goScoreTerritoryScoringEnabled:) name:goScoreTerritoryScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreTerritoryScoringDisabled:) name:goScoreTerritoryScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
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

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pass" button. Generates a "Pass"
/// move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) pass:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
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
    DDLogWarn(@"%@: Ignoring board position change", self);
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
    DDLogWarn(@"%@: Ignoring board position change", self);
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
  if (! score.territoryScoringEnabled)
    [score calculateWaitUntilDone:true];
  self.gameInfoViewController = [GameInfoViewController controllerWithDelegate:self];
  [self.navigationController pushViewController:self.gameInfoViewController animated:YES];
  if (5 == [UIDevice systemVersionMajor])
  {
    // We are the GameInfoViewController delegate, so we must not be
    // deallocated when the parent's viewDidUnload is invoked while
    // GameInfoViewController does its thing.
    [self retain];
  }
}

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller
{
  [self.navigationController popViewControllerAnimated:YES];
  self.gameInfoViewController = nil;
  if (5 == [UIDevice systemVersionMajor])
  {
    // Balance the retain message that we send to this controller before
    // we display GameInfoViewController
    [self autorelease];
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Game Actions" button. Displays an
/// action sheet with actions that related to Go games as a whole.
// -----------------------------------------------------------------------------
- (void) gameActions:(id)sender
{
  if ([self shouldIgnoreTaps])
  {
    DDLogWarn(@"%@: Ignoring board position change", self);
    return;
  }
  PlayViewActionSheetController* controller = [[PlayViewActionSheetController alloc] initWithModalMaster:self.parentViewController delegate:self];
  [controller showActionSheetFromView:[ApplicationDelegate sharedDelegate].window];
  if (5 == [UIDevice systemVersionMajor])
  {
    // We are the PlayViewActionSheetController's delegate, so we must not be
    // deallocated when the parent's viewDidUnload is invoked while
    // PlayViewActionSheetDelegate does its thing.
    [self retain];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns true if taps on bar button items should currently be
/// ignored.
// -----------------------------------------------------------------------------
- (bool) shouldIgnoreTaps
{
  return [GoGame sharedGame].isComputerThinking;
}

// -----------------------------------------------------------------------------
/// @brief PlayViewActionSheetDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) playViewActionSheetControllerDidFinish:(PlayViewActionSheetController*)controller
{
  [controller release];
  if (5 == [UIDevice systemVersionMajor])
  {
    // Balance the retain message that we send to this controller before
    // we display PlayViewActionSheetController
    [self autorelease];
  }
}

// -----------------------------------------------------------------------------
/// @brief UISplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController*)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc
{
  self.barButtonItemForShowingTheHiddenViewController = barButtonItem;
  barButtonItem.title = @"Moves";
  self.navigationBarNeedsPopulation = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief UISplitViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController*)aViewController invalidatingBarButtonItem:(UIBarButtonItem*)button
{
  self.barButtonItemForShowingTheHiddenViewController = nil;
  self.navigationBarNeedsPopulation = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Done" button. Ends the currently
/// active mode and returns to normal play mode.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [GoGame sharedGame].score.territoryScoringEnabled = false;  // triggers notification to which this controller reacts
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* boardPosition = oldGame.boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
  // Disable scoring mode while the old GoGame is still around
  oldGame.score.territoryScoringEnabled = false;
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
  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
  GoGame* game = [GoGame sharedGame];
  if (GoGameStateGameHasEnded == game.state)
  {
    if ([ApplicationDelegate sharedDelegate].scoringModel.scoreWhenGameEnds)
    {
      if (GoGameHasEndedReasonTwoPasses == game.reasonForGameHasEnded)
      {
        game.score.territoryScoringEnabled = true;
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
  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringEnabled:(NSNotification*)notification
{
  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringDisabled:(NSNotification*)notification
{
  [[ApplicationStateManager sharedManager] applicationStateDidChange];
  self.navigationBarNeedsPopulation = true;
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
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  [self delayedUpdate];
}

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
      self.navigationBarNeedsPopulation = true;
    }
    [self delayedUpdate];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. See class
/// documentation for details.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    return;
  [self populateNavigationBar];
  [self updateButtonStates];
}

// -----------------------------------------------------------------------------
/// @brief Populates the navigation bar with buttons that are appropriate for
/// the #GoGameType currently in progress.
// -----------------------------------------------------------------------------
- (void) populateNavigationBar
{
  if (! self.navigationBarNeedsPopulation)
    return;
  self.navigationBarNeedsPopulation = false;

  NSArray* leftBarButtonItems = [self leftBarButtonItems];
  NSArray* rightBarButtonItems = [self rightBarButtonItems];

  NSMutableArray* barButtonItems = [NSMutableArray arrayWithCapacity:0];
  [barButtonItems addObjectsFromArray:leftBarButtonItems];
  if (self.statusViewController)
  {
    int maximumNumberOfButtons = 5;
    if (self.barButtonItemForShowingTheHiddenViewController)
      maximumNumberOfButtons++;
    int numberOfUnusedButtons = maximumNumberOfButtons - leftBarButtonItems.count - rightBarButtonItems.count;
    int statusViewMinimumWidth;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
      statusViewMinimumWidth = 60;
    else
      statusViewMinimumWidth = 100;
    int widthPerUnusedButton = 20;
    int statusViewWidth = (statusViewMinimumWidth
                           + (widthPerUnusedButton * numberOfUnusedButtons));
    self.statusViewController.statusViewWidth = statusViewWidth;

    [barButtonItems addObject:self.flexibleSpaceButtonLeft];
    [barButtonItems addObject:self.statusViewButton];
    [barButtonItems addObject:self.flexibleSpaceButtonRight];
  }
  else
  {
    [barButtonItems addObject:self.flexibleSpaceButtonLeft];  // need only one spacer
  }
  [barButtonItems addObjectsFromArray:rightBarButtonItems];
  self.navigationBar.topItem.leftBarButtonItems = barButtonItems;
  self.navigationBar.topItem.rightBarButtonItems = nil;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (NSArray*) leftBarButtonItems
{
  NSMutableArray* leftBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  if (game.score.territoryScoringEnabled)
  {
    [leftBarButtonItems addObject:self.doneButton];
    [leftBarButtonItems addObject:self.discardBoardPositionButton];
  }
  else
  {
    switch (game.type)
    {
      case GoGameTypeComputerVsComputer:
      {
        if (GoGameStateGameIsPaused == game.state)
          [leftBarButtonItems addObject:self.continueButton];
        else
        {
          if (GoGameStateGameHasEnded != game.state)
            [leftBarButtonItems addObject:self.pauseButton];
        }
        if (game.isComputerThinking)
          [leftBarButtonItems addObject:self.interruptButton];
        else
        {
          if (boardPosition.numberOfBoardPositions > 1)
            [leftBarButtonItems addObject:self.discardBoardPositionButton];
        }
        break;
      }
      default:
      {
        if (game.isComputerThinking)
          [leftBarButtonItems addObject:self.interruptButton];
        else
        {
          if (GoGameStateGameHasEnded != game.state)
          {
            [leftBarButtonItems addObject:self.computerPlayButton];
            [leftBarButtonItems addObject:self.passButton];
          }
          if (boardPosition.numberOfBoardPositions > 1)
            [leftBarButtonItems addObject:self.discardBoardPositionButton];
        }
        break;
      }
    }
  }
  return leftBarButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (NSArray*) rightBarButtonItems
{
  NSMutableArray* rightBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  if (self.barButtonItemForShowingTheHiddenViewController)
    [rightBarButtonItems addObject:self.barButtonItemForShowingTheHiddenViewController];
  [rightBarButtonItems addObject:self.gameInfoButton];
  [rightBarButtonItems addObject:self.gameActionsButton];
  return rightBarButtonItems;
}

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
  if (! game.score.territoryScoringEnabled)
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
  if (! game.score.territoryScoringEnabled)
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
  if (game.score.territoryScoringEnabled)
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
  if (! game.score.territoryScoringEnabled)
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
  if (! game.score.territoryScoringEnabled)
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
  if (game.score.territoryScoringEnabled)
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
  if (game.score.territoryScoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
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
  if (game.score.territoryScoringEnabled)
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
  if (game.score.territoryScoringEnabled)
  {
    if (! game.score.scoringInProgress)
      enabled = YES;
  }
  self.doneButton.enabled = enabled;
}

@end
