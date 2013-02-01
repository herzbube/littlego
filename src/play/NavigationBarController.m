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
#import "ScoringModel.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"
#import "../command/InterruptComputerCommand.h"
#import "../command/boardposition/ChangeAndDiscardCommand.h"
#import "../command/boardposition/DiscardAndPlayCommand.h"
#import "../command/game/PauseGameCommand.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for NavigationBarController.
// -----------------------------------------------------------------------------
@interface NavigationBarController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Action methods for toolbar items
//@{
- (void) pass:(id)sender;
- (void) computerPlay:(id)sender;
- (void) pause:(id)sender;
- (void) continue:(id)sender;
- (void) interrupt:(id)sender;
- (void) gameInfo:(id)sender;
- (void) gameActions:(id)sender;
- (void) done:(id)sender;
//@}
/// @name GameInfoViewControllerDelegate protocol
//@{
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller;
//@}
/// @name PlayViewActionSheetDelegate protocol
//@{
- (void) playViewActionSheetControllerDidFinish:(PlayViewActionSheetController*)controller;
//@}
/// @name UISplitViewControllerDelegate protocol
//@{
- (void) splitViewController:(UISplitViewController*)svc willHideViewController:(UIViewController*)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController:(UIPopoverController*)pc;
- (void) splitViewController:(UISplitViewController*)svc willShowViewController:(UIViewController*)aViewController invalidatingBarButtonItem:(UIBarButtonItem*)button;
//@}
/// @name Notification responders
//@{
- (void) goGameWillCreate:(NSNotification*)notification;
- (void) goGameDidCreate:(NSNotification*)notification;
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goScoreScoringModeEnabled:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
- (void) longRunningActionStarts:(NSNotification*)notification;
- (void) longRunningActionEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Updaters
//@{
- (void) delayedUpdate;
- (void) populateNavigationBar;
- (void) populateNavigationBarLeft;
- (void) populateNavigationBarRight;
- (void) updateButtonStates;
- (void) updateComputerPlayButtonState;
- (void) updatePassButtonState;
- (void) updatePauseButtonState;
- (void) updateContinueButtonState;
- (void) updateInterruptButtonState;
- (void) updateGameInfoButtonState;
- (void) updateGameActionsButtonState;
- (void) updateDoneButtonState;
//@}
/// @name Private helpers
//@{
- (void) setupNavigationItem;
- (void) setupButtons;
- (void) setupNotificationResponders;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) ScoringModel* scoringModel;
@property(nonatomic, assign) id<NavigationBarControllerDelegate> delegate;
/// @brief The parent view controller of this subcontroller.
@property(nonatomic, assign) UIViewController* parentViewController;
@property(nonatomic, retain) GameInfoViewController* gameInfoViewController;
/// @brief GoScore object used while the game info view is displayed and scoring
/// mode is NOT enabled. If scoring mode is enabled, the GoScore object is
/// obtained from elsewhere.
@property(nonatomic, retain) GoScore* gameInfoScore;
/// @brief Updates are delayed as long as this is above zero.
@property(nonatomic, assign) int actionsInProgress;
@property(nonatomic, assign) bool navigationBarNeedsPopulation;
@property(nonatomic, assign) bool buttonStatesNeedUpdate;
@property(nonatomic, retain) UINavigationItem* navigationItem;
@property(nonatomic, retain) UIBarButtonItem* computerPlayButton;
@property(nonatomic, retain) UIBarButtonItem* passButton;
@property(nonatomic, retain) UIBarButtonItem* discardBoardPositionButton;
@property(nonatomic, retain) UIBarButtonItem* pauseButton;
@property(nonatomic, retain) UIBarButtonItem* continueButton;
@property(nonatomic, retain) UIBarButtonItem* interruptButton;
@property(nonatomic, retain) UIBarButtonItem* flexibleSpaceButton;
@property(nonatomic, assign) UIBarButtonItem* barButtonItemForShowingTheHiddenViewController;
@property(nonatomic, retain) UIBarButtonItem* gameInfoButton;
@property(nonatomic, retain) UIBarButtonItem* gameActionsButton;
@property(nonatomic, retain) UIBarButtonItem* doneButton;
//@}
@end


@implementation NavigationBarController

@synthesize navigationBar;
@synthesize scoringModel;
@synthesize delegate;
@synthesize parentViewController;
@synthesize gameInfoViewController;
@synthesize gameInfoScore;
@synthesize actionsInProgress;
@synthesize navigationBarNeedsPopulation;
@synthesize buttonStatesNeedUpdate;
@synthesize navigationItem;
@synthesize computerPlayButton;
@synthesize passButton;
@synthesize discardBoardPositionButton;
@synthesize pauseButton;
@synthesize continueButton;
@synthesize interruptButton;
@synthesize flexibleSpaceButton;
@synthesize barButtonItemForShowingTheHiddenViewController;
@synthesize gameInfoButton;
@synthesize gameActionsButton;
@synthesize doneButton;


// -----------------------------------------------------------------------------
/// @brief Initializes a NavigationBarController object.
///
/// @note This is the designated initializer of NavigationBarController.
// -----------------------------------------------------------------------------
- (id) initWithScoringModel:(ScoringModel*)aScoringModel
              delegate:(id<NavigationBarControllerDelegate>)aDelegate
  parentViewController:(UIViewController*)aParentViewController
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.navigationBar = nil;
  self.scoringModel = aScoringModel;
  self.delegate = aDelegate;
  self.parentViewController = aParentViewController;
  self.gameInfoViewController = nil;
  self.gameInfoScore = nil;
  self.actionsInProgress = 0;
  self.barButtonItemForShowingTheHiddenViewController = nil;
  [self setupNavigationItem];
  [self setupButtons];
  [self setupNotificationResponders];

  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NavigationBarController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
  self.navigationBar = nil;
  self.scoringModel = nil;
  self.delegate = nil;
  self.parentViewController = nil;
  self.gameInfoViewController = nil;
  self.gameInfoScore = nil;
  self.navigationItem = nil;
  self.computerPlayButton = nil;
  self.passButton = nil;
  self.discardBoardPositionButton = nil;
  self.pauseButton = nil;
  self.continueButton = nil;
  self.interruptButton = nil;
  self.flexibleSpaceButton = nil;
  self.barButtonItemForShowingTheHiddenViewController = nil;
  self.gameInfoButton = nil;
  self.gameActionsButton = nil;
  self.doneButton = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNavigationItem
{
  self.navigationItem = [[[UINavigationItem alloc] initWithTitle:@""] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
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
  self.flexibleSpaceButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                            target:nil
                                                                            action:nil] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameWillCreate:) name:goGameWillCreate object:nil];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeEnabled:) name:goScoreScoringModeEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(longRunningActionStarts:) name:longRunningActionStarts object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Setting of navigation bar occurs delayed (i.e. not during
/// initialization of the controller object) due to timing needs of the parent
/// view controller.
// -----------------------------------------------------------------------------
- (void) setNavigationBar:(UINavigationBar*)aNavigationBar
{
  navigationBar = aNavigationBar;
  [self.navigationBar pushNavigationItem:self.navigationItem animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pass" button. Generates a "Pass"
/// move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) pass:(id)sender
{
  DiscardAndPlayCommand* command = [[DiscardAndPlayCommand alloc] initPass];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Delete" button. Discards the current
/// board position and all positions that follow afterwards.
// -----------------------------------------------------------------------------
- (void) discardBoardPosition:(id)sender
{
  ChangeAndDiscardCommand* command = [[ChangeAndDiscardCommand alloc] init];
  [self.delegate navigationBarController:self discardOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Computer play" button. Causes the
/// computer player to generate a move, either for itself or on behalf of the
/// human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) computerPlay:(id)sender
{
  DiscardAndPlayCommand* command = [[DiscardAndPlayCommand alloc] initComputerPlay];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pause" button. Pauses the game if
/// two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) pause:(id)sender
{
  PauseGameCommand* command = [[PauseGameCommand alloc] init];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Continue" button. Continues the game
/// if it is paused while two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) continue:(id)sender
{
  DiscardAndPlayCommand* command = [[DiscardAndPlayCommand alloc] initContinue];
  [self.delegate navigationBarController:self playOrAlertWithCommand:command];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Interrupt" button. Interrupts the
/// computer while it is thinking.
// -----------------------------------------------------------------------------
- (void) interrupt:(id)sender
{
  InterruptComputerCommand* command = [[InterruptComputerCommand alloc] init];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info" button. Displays the
/// "Game Info" view with information about the game in progress.
// -----------------------------------------------------------------------------
- (void) gameInfo:(id)sender
{
  GoScore* score;
  if (self.scoringModel.scoringMode)
    score = self.scoringModel.score;
  else
  {
    assert(! self.gameInfoScore);
    if (! self.gameInfoScore)
    {
      self.gameInfoScore = [GoScore scoreForGame:[GoGame sharedGame] withTerritoryScores:false];
      [self.gameInfoScore calculateWaitUntilDone:true];
    }
    score = self.gameInfoScore;
  }
  self.gameInfoViewController = [GameInfoViewController controllerWithDelegate:self score:score];
  [self.delegate navigationBarController:self
                             makeVisible:true
                  gameInfoViewController:self.gameInfoViewController];
}

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller
{
  [self.delegate navigationBarController:self
                             makeVisible:false
            gameInfoViewController:controller];
  assert(self.gameInfoViewController == controller);
  self.gameInfoViewController = nil;
  // Get rid of temporary scoring object
  if (! self.scoringModel.scoringMode)
  {
    assert(self.gameInfoScore);
    self.gameInfoScore = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Game Actions" button. Displays an
/// action sheet with actions that related to Go games as a whole.
// -----------------------------------------------------------------------------
- (void) gameActions:(id)sender
{
  PlayViewActionSheetController* controller = [[PlayViewActionSheetController alloc] initWithModalMaster:self.parentViewController delegate:self];
  [controller showActionSheetFromView:[ApplicationDelegate sharedDelegate].window];
}

// -----------------------------------------------------------------------------
/// @brief PlayViewActionSheetDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) playViewActionSheetControllerDidFinish:(PlayViewActionSheetController*)controller
{
  [controller release];
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
  self.scoringModel.scoringMode = false;  // triggers notification to which this controller reacts
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
  self.scoringModel.scoringMode = false;
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
  GoGame* game = [GoGame sharedGame];
  if (GoGameTypeComputerVsComputer == game.type)
    self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
  if (GoGameStateGameHasEnded == game.state)
  {
    self.scoringModel.scoringMode = true;
    [self.scoringModel.score calculateWaitUntilDone:false];
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
/// @brief Responds to the #goScoreScoringModeEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeEnabled:(NSNotification*)notification
{
  self.navigationBarNeedsPopulation = true;
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
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
  self.buttonStatesNeedUpdate = true;
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionStarts notifications.
///
/// Increases @e actionsInProgress by 1.
// -----------------------------------------------------------------------------
- (void) longRunningActionStarts:(NSNotification*)notification
{
  self.actionsInProgress++;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notifications.
///
/// Decreases @e actionsInProgress by 1. Triggers a view update if
/// @e actionsInProgress becomes 0 and @e updatesWereDelayed is true.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  self.actionsInProgress--;
  if (0 == self.actionsInProgress)
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
  if (self.actionsInProgress > 0)
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

  [self populateNavigationBarLeft];
  [self populateNavigationBarRight];
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateNavigationBarLeft
{
  NSMutableArray* leftBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  if (self.scoringModel.scoringMode)
  {
    if (GoGameStateGameHasEnded != game.state)
    {
      [leftBarButtonItems addObject:self.discardBoardPositionButton];
      [leftBarButtonItems addObject:self.doneButton];  // cannot get out of scoring mode if game has ended
    }
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
          [leftBarButtonItems addObject:self.pauseButton];
        if (game.isComputerThinking)
          [leftBarButtonItems addObject:self.interruptButton];
        else
          [leftBarButtonItems addObject:self.discardBoardPositionButton];
        break;
      }
      default:
      {
        if (game.isComputerThinking)
          [leftBarButtonItems addObject:self.interruptButton];
        else
        {
          [leftBarButtonItems addObject:self.computerPlayButton];
          [leftBarButtonItems addObject:self.passButton];
          if (boardPosition.numberOfBoardPositions > 1)
            [leftBarButtonItems addObject:self.discardBoardPositionButton];
        }
        break;
      }
    }
  }
  self.navigationItem.leftBarButtonItems = leftBarButtonItems;
}

// -----------------------------------------------------------------------------
/// @brief This is an internal helper invoked by populateNavigationBar().
// -----------------------------------------------------------------------------
- (void) populateNavigationBarRight
{
  NSMutableArray* rightBarButtonItems = [NSMutableArray arrayWithCapacity:0];
  [rightBarButtonItems addObject:self.gameActionsButton];
  [rightBarButtonItems addObject:self.gameInfoButton];
  if (self.barButtonItemForShowingTheHiddenViewController)
    [rightBarButtonItems addObject:self.barButtonItemForShowingTheHiddenViewController];
  self.navigationItem.rightBarButtonItems = rightBarButtonItems;
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
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
        {
          case GoGameStateGameHasNotYetStarted:
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
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case GoGameTypeComputerVsComputer:
        break;
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
        {
          case GoGameStateGameHasNotYetStarted:
          case GoGameStateGameHasStarted:
          {
            GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
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
/// @brief Updates the enabled state of the "Pause" button.
// -----------------------------------------------------------------------------
- (void) updatePauseButtonState
{
  BOOL enabled = NO;
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch ([GoGame sharedGame].state)
        {
          case GoGameStateGameHasNotYetStarted:
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
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch ([GoGame sharedGame].state)
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
  if (self.scoringModel.scoringMode)
  {
    if (self.scoringModel.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    if ([GoGame sharedGame].isComputerThinking)
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
  if (self.scoringModel.scoringMode)
  {
    if (! self.scoringModel.score.scoringInProgress)
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
  if (self.scoringModel.scoringMode)
  {
    if (! self.scoringModel.score.scoringInProgress)
      enabled = YES;
  }
  else
  {
    switch ([GoGame sharedGame].type)
    {
      case GoGameTypeComputerVsComputer:
      {
        switch ([GoGame sharedGame].state)
        {
          case GoGameStateGameHasNotYetStarted:
          case GoGameStateGameHasEnded:
            enabled = YES;
          case GoGameStateGameIsPaused:
            // Computer may still be thinking
            enabled = ! [GoGame sharedGame].isComputerThinking;
            break;
          default:
            break;
        }
        break;
      }
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
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
  if (self.scoringModel.scoringMode)
  {
    if (! self.scoringModel.score.scoringInProgress)
      enabled = YES;
  }
  self.doneButton.enabled = enabled;
}

@end
