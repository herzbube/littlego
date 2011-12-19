// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayView.h"
#import "ScoringModel.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoPlayer.h"
#import "../go/GoScore.h"
#import "../go/GoPoint.h"
#import "../player/Player.h"
#import "../command/move/ComputerPlayMoveCommand.h"
#import "../command/move/PlayMoveCommand.h"
#import "../command/move/UndoMoveCommand.h"
#import "../command/game/PauseGameCommand.h"
#import "../command/game/ContinueGameCommand.h"


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
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Action methods for toolbar items
//@{
- (void) pass:(id)sender;
- (void) playForMe:(id)sender;
- (void) undo:(id)sender;
- (void) pause:(id)sender;
- (void) continue:(id)sender;
- (void) gameInfo:(id)sender;
- (void) gameActions:(id)sender;
- (void) done:(id)sender;
//@}
/// @name Handlers for recognized gestures
//@{
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer;
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer;
//@}
/// @name UIGestureRecognizerDelegate protocol
//@{
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer;
//@}
/// @name GameInfoViewControllerDelegate protocol
//@{
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller;
//@}
/// @name PlayViewActionSheetDelegate protocol
//@{
- (void) playViewActionSheetControllerDidFinish:(PlayViewActionSheetController*)controller;
//@}
/// @name Notification responders
//@{
- (void) applicationIsReadyForAction:(NSNotification*)notification;
- (void) goGameNewCreated:(NSNotification*)notification;
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goGameLastMoveChanged:(NSNotification*)notification;
- (void) goScoreScoringModeEnabled:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
//@}
/// @name Updaters
//@{
- (void) populateToolbar;
- (void) updateButtonStates;
- (void) updatePlayForMeButtonState;
- (void) updatePassButtonState;
- (void) updateUndoButtonState;
- (void) updatePauseButtonState;
- (void) updateContinueButtonState;
- (void) updateGameInfoButtonState;
- (void) updateGameActionsButtonState;
- (void) updateDoneButtonState;
- (void) updatePanningEnabled;
- (void) updateTappingEnabled;
//@}
/// @name Private helpers
//@{
- (void) makeControllerReadyForAction;
- (void) flipToFrontSideView:(bool)flipToFrontSideView;
//@}
/// @name Privately declared properties
//@{
/// @brief True if this controller has been set up is now "ready for action".
@property(nonatomic, assign) bool controllerReadyForAction;
/// @brief The model that manages scoring-related data.
@property(nonatomic, assign) ScoringModel* scoringModel;
/// @brief The gesture recognizer used to detect the long-press gesture.
@property(nonatomic, retain) UILongPressGestureRecognizer* longPressRecognizer;
/// @brief The gesture recognizer used to detect the tap gesture.
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
/// @brief True if a panning gesture is currently allowed, false if not (e.g.
/// while a computer player is thinking).
@property(nonatomic, assign, getter=isPanningEnabled) bool panningEnabled;
/// @brief True if a tapping gesture is currently allowed, false if not (e.g.
/// if scoring mode is not enabled).
@property(nonatomic, assign, getter=isTappingEnabled) bool tappingEnabled;
/// @brief GoScore object used while the game info view is displayed scoring
/// mode is NOT enabled. If scoring mode is enabled, the GoScore object is
/// obtained from elsewhere.
@property(nonatomic, retain) GoScore* gameInfoScore;
//@}
@end


@implementation PlayViewController

@synthesize controllerReadyForAction;
@synthesize frontSideView;
@synthesize backSideView;
@synthesize playView;
@synthesize toolbar;
@synthesize playForMeButton;
@synthesize passButton;
@synthesize undoButton;
@synthesize pauseButton;
@synthesize continueButton;
@synthesize flexibleSpaceButton;
@synthesize gameInfoButton;
@synthesize gameActionsButton;
@synthesize doneButton;
@synthesize scoringModel;
@synthesize longPressRecognizer;
@synthesize tapRecognizer;
@synthesize panningEnabled;
@synthesize tappingEnabled;
@synthesize gameInfoScore;


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.frontSideView = nil;
  self.backSideView = nil;
  self.playView = nil;
  self.scoringModel = nil;
  self.longPressRecognizer = nil;
  self.tapRecognizer = nil;
  self.gameInfoScore = nil;
  [super dealloc];
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
  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.scoringModel = delegate.scoringModel;
  if (! self.scoringModel)
  {
    DDLogError(@"PlayViewController::makeControllerReadyForAction(): Unable to find the ScoringModel object");
    assert(0);
  }

  [self.view addSubview:self.frontSideView];

  self.panningEnabled = false;
  self.tappingEnabled = false;

  self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
	[self.longPressRecognizer release];
	[self.playView addGestureRecognizer:self.longPressRecognizer];
  self.longPressRecognizer.delegate = self;
  self.longPressRecognizer.minimumPressDuration = 0;  // place stone immediately
  CGFloat infiniteMovement = CGFLOAT_MAX;
  self.longPressRecognizer.allowableMovement = infiniteMovement;  // let the user pan as long as he wants

  self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
	[self.tapRecognizer release];
	[self.playView addGestureRecognizer:self.tapRecognizer];
  self.tapRecognizer.delegate = self;

  self.gameInfoScore = nil;
  self.gameInfoButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabular.png"]
                                                          style:UIBarButtonItemStyleBordered
                                                         target:self
                                                         action:@selector(gameInfo:)] autorelease];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameNewCreated:) name:goGameNewCreated object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeEnabled:) name:goScoreScoringModeEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];

  // We invoke this to set up initial state because we did not get
  // get goGameNewCreated for the initial game (viewDidLoad gets called too
  // late)
  [self goGameNewCreated:nil];
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
  self.scoringModel = nil;
  self.longPressRecognizer = nil;
  self.tapRecognizer = nil;
  self.gameInfoScore = nil;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pass" button. Generates a "Pass"
/// move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) pass:(id)sender
{
  PlayMoveCommand* command = [[PlayMoveCommand alloc] initPass];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Play for me" button. Causes the
/// computer player to generate a move for the human player whose turn it
/// currently is.
// -----------------------------------------------------------------------------
- (void) playForMe:(id)sender
{
  ComputerPlayMoveCommand* command = [[ComputerPlayMoveCommand alloc] init];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Undo" button. Takes back the last
/// move made by a human player, including any computer player moves that were
/// made in response.
// -----------------------------------------------------------------------------
- (void) undo:(id)sender
{
  UndoMoveCommand* command = [[UndoMoveCommand alloc] init];
  [command submit];
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
/// @brief Reacts to a tap gesture on the "Undo" button. Continues the game if
/// it is paused while two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) continue:(id)sender
{
  ContinueGameCommand* command = [[ContinueGameCommand alloc] init];
  [command submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info" button. Flips the game view to
/// display an alternate view with information about the game in progress.
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
  GameInfoViewController* controller = [[GameInfoViewController controllerWithDelegate:self score:score] retain];
  [self.backSideView addSubview:controller.view];
  bool flipToFrontSideView = false;
  [self flipToFrontSideView:flipToFrontSideView];
}

// -----------------------------------------------------------------------------
/// @brief GameInfoViewControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gameInfoViewControllerDidFinish:(GameInfoViewController*)controller
{
  bool flipToFrontSideView = true;
  [self flipToFrontSideView:flipToFrontSideView];
  [controller.view removeFromSuperview];
  [controller release];
  // Get rid of temporary scoring object
  if (! self.scoringModel.scoringMode)
  {
    assert(self.gameInfoScore);
    self.gameInfoScore = nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief PlayViewActionSheetDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) playViewActionSheetControllerDidFinish:(PlayViewActionSheetController*)controller
{
  [controller release];
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
/// @brief Reacts to a tap gesture on the "Game Actions" button. Displays an
/// action sheet with actions that related to Go games as a whole.
// -----------------------------------------------------------------------------
- (void) gameActions:(id)sender
{
  PlayViewActionSheetController* controller = [[PlayViewActionSheetController alloc] initWithModalMaster:self delegate:self];
  [controller showActionSheetFromView:self.playView];
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
/// @brief Reacts to a dragging, or panning, gesture in the view's Go board
/// area.
// -----------------------------------------------------------------------------
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer
{
  // TODO move the following summary somewhere else where it is not buried in
  // code and forgotten...
  // 1. Touching the screen starts stone placement
  // 2. Stone is placed when finger leaves the screen and the stone is placed
  //    in a valid location
  // 3. Stone placement can be cancelled by placing in an invalid location
  // 4. Invalid locations are: Another stone is already placed on the point;
  //    placing the stone would be suicide; the point is guarded by a Ko; the
  //    point is outside the board
  // 5. While panning/dragging, provide continuous feedback on the current
  //    stone location
  //    - Display a stone of the correct color at the current location
  //    - Mark up the stone differently from already placed stones
  //    - Mark up the stone differently if it is in a valid location, and if
  //      it is in an invalid location
  //    - Display in the status line the vertex of the current location
  //    - If the location is invalid, display the reason in the status line
  //    - If placing a stone would capture other stones, mark up those stones
  //      and display in the status line how many stones would be captured
  //    - If placing a stone would set a group (your own or an enemy group) to
  //      atari, mark up that group
  // 6. Place the stone with an offset to the fingertip position so that the
  //    user can see the stone location

  CGPoint panningLocation = [gestureRecognizer locationInView:self.playView];
  GoPoint* crossHairPoint = [self.playView crossHairPointAt:panningLocation];

  // TODO If the move is not legal, determine the reason (another stone is
  // already placed on the point; suicide move; guarded by Ko rule)
  bool isLegalMove = false;
  if (crossHairPoint)
    isLegalMove = [[GoGame sharedGame] isLegalMove:crossHairPoint];

  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
      // fall-through intentional
    case UIGestureRecognizerStateChanged:
      [self.playView moveCrossHairTo:crossHairPoint isLegalMove:isLegalMove];
      break;
    case UIGestureRecognizerStateEnded:
      [self.playView moveCrossHairTo:nil isLegalMove:true];
      if (isLegalMove)
      {
        PlayMoveCommand* command = [[PlayMoveCommand alloc] initWithPoint:crossHairPoint];
        [command submit];
      }
      break;
    case UIGestureRecognizerStateCancelled:
      // TODO Phone call? How to test this?
      [self.playView moveCrossHairTo:nil isLegalMove:true];
      break;
    default:
      return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture in the view's Go board area.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGPoint tappingLocation = [gestureRecognizer locationInView:self.playView];
  GoPoint* deadStonePoint = [self.playView pointAt:tappingLocation];
  if (! deadStonePoint || ! [deadStonePoint hasStone])
    return;
  [self.scoringModel.score toggleDeadStoneStateOfGroup:deadStonePoint.region];
  [self.scoringModel.score calculateWaitUntilDone:false];
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method. Disables gesture
/// recognition while interactionEnabled() is false.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  if (gestureRecognizer == self.longPressRecognizer)
    return self.isPanningEnabled;
  else if (gestureRecognizer == self.tapRecognizer)
    return self.isTappingEnabled;
  else
    return false;
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
/// @brief Responds to the #goGameNewCreated notification.
// -----------------------------------------------------------------------------
- (void) goGameNewCreated:(NSNotification*)notification
{
  self.scoringModel.scoringMode = false;
  [self populateToolbar];
  [self updateButtonStates];
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateButtonStates];
  [self updatePanningEnabled];
  if (GameHasEnded == [GoGame sharedGame].state)
    self.scoringModel.scoringMode = true;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateButtonStates];
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameLastMoveChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameLastMoveChanged:(NSNotification*)notification
{
  // Mainly here for updating the "undo" button
  [self updateButtonStates];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeEnabled:(NSNotification*)notification
{
  [self populateToolbar];
  [self updateButtonStates];
  [self updatePanningEnabled];  // disable panning
  [self updateTappingEnabled];
  [self.scoringModel.score calculateWaitUntilDone:false];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
  [self populateToolbar];
  [self updateButtonStates];
  [self updatePanningEnabled];  // enable panning
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  [self updateButtonStates];
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notification.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self updateButtonStates];
  [self updateTappingEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Populates the toolbar with toolbar items that are appropriate for
/// the #GoGameType currently in progress.
// -----------------------------------------------------------------------------
- (void) populateToolbar
{
  NSMutableArray* toolbarItems = [NSMutableArray arrayWithCapacity:0];
  if (self.scoringModel.scoringMode)
  {
    if (GameHasEnded != [GoGame sharedGame].state)
      [toolbarItems addObject:self.doneButton];  // cannot get out of scoring mode if game has ended
    [toolbarItems addObject:self.flexibleSpaceButton];
    [toolbarItems addObject:self.gameInfoButton];
    [toolbarItems addObject:self.gameActionsButton];
  }
  else
  {
    switch ([GoGame sharedGame].type)
    {
      case ComputerVsComputerGame:
        [toolbarItems addObject:self.pauseButton];
        [toolbarItems addObject:self.continueButton];
        [toolbarItems addObject:self.flexibleSpaceButton];
        [toolbarItems addObject:self.gameInfoButton];
        [toolbarItems addObject:self.gameActionsButton];
        break;
      default:
        [toolbarItems addObject:self.playForMeButton];
        [toolbarItems addObject:self.passButton];
        [toolbarItems addObject:self.undoButton];
        [toolbarItems addObject:self.flexibleSpaceButton];
        [toolbarItems addObject:self.gameInfoButton];
        [toolbarItems addObject:self.gameActionsButton];
        break;
    }
  }
  self.toolbar.items = toolbarItems;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of all toolbar items.
// -----------------------------------------------------------------------------
- (void) updateButtonStates
{
  [self updatePlayForMeButtonState];
  [self updatePassButtonState];
  [self updateUndoButtonState];
  [self updatePauseButtonState];
  [self updateContinueButtonState];
  [self updateGameInfoButtonState];
  [self updateGameActionsButtonState];
  [self updateDoneButtonState];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Play for me" button.
// -----------------------------------------------------------------------------
- (void) updatePlayForMeButtonState
{
  BOOL enabled = NO;
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case ComputerVsComputerGame:
        break;
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
        {
          case GameHasNotYetStarted:
          case GameHasStarted:
            enabled = YES;
            break;
          default:
            break;
        }
        break;
      }
    }
  }
  self.playForMeButton.enabled = enabled;
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
      case ComputerVsComputerGame:
        break;
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
        {
          case GameHasNotYetStarted:
          case GameHasStarted:
            enabled = YES;
            break;
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
/// @brief Updates the enabled state of the "Undo" button.
// -----------------------------------------------------------------------------
- (void) updateUndoButtonState
{
  BOOL enabled = NO;
  if (! self.scoringModel.scoringMode)
  {
    switch ([GoGame sharedGame].type)
    {
      case ComputerVsComputerGame:
        break;
      default:
      {
        if ([GoGame sharedGame].isComputerThinking)
          break;
        switch ([GoGame sharedGame].state)
        {
          case GameHasStarted:
          {
            GoMove* lastMove = [GoGame sharedGame].lastMove;
            if (lastMove == nil)
              enabled = NO;                         // no move yet
            else if (lastMove.player.player.human)
              enabled = YES;                        // last move by human player
            else if (lastMove.previous == nil)
              enabled = NO;                         // last move by computer, but no other move before that
            else
              enabled = YES;                        // last move by computer, and another move before that
            // -> assume it's by a human player because game type has been checked before
            break;
          }
          default:
            break;
        }
        break;
      }
    }
  }
  self.undoButton.enabled = enabled;
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
      case ComputerVsComputerGame:
      {
        switch ([GoGame sharedGame].state)
        {
          case GameHasNotYetStarted:
          case GameHasStarted:
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
      case ComputerVsComputerGame:
      {
        switch ([GoGame sharedGame].state)
        {
          case GameIsPaused:
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
      case ComputerVsComputerGame:
      {
        switch ([GoGame sharedGame].state)
        {
          case GameHasNotYetStarted:
          case GameHasEnded:
            enabled = YES;
          case GameIsPaused:
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

// -----------------------------------------------------------------------------
/// @brief Updates whether panning is enabled.
// -----------------------------------------------------------------------------
- (void) updatePanningEnabled
{
  if (self.scoringModel.scoringMode)
  {
    self.panningEnabled = false;
    return;
  }

  GoGame* game = [GoGame sharedGame];
  if (! game)
  {
    self.panningEnabled = false;
    return;
  }

  if (ComputerVsComputerGame == game.type)
  {
    self.panningEnabled = false;
    return;
  }

  switch (game.state)
  {
    case GameHasNotYetStarted:
    case GameHasStarted:
      self.panningEnabled = ! [game isComputerThinking];
      break;
    default:  // specifically GameHasEnded
      self.panningEnabled = false;
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates whether tapping is enabled.
// -----------------------------------------------------------------------------
- (void) updateTappingEnabled
{
  if (self.scoringModel.scoringMode)
    self.tappingEnabled = ! self.scoringModel.score.scoringInProgress;
  else
    self.tappingEnabled = false;
}

@end
