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
#import "PlayViewActionSheetController.h"
#import "PlayView.h"
#import "../go/GoGame.h"
#import "../go/GoMove.h"
#import "../go/GoPlayer.h"
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
- (void) gameActions:(id)sender;
//@}
/// @name Handlers for recognized gestures
//@{
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer;
//@}
/// @name UIGestureRecognizerDelegate protocol
//@{
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer;
//@}
/// @name Notification responders
//@{
- (void) goGameNewCreated:(NSNotification*)notification;
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) goGameScoreChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goGameLastMoveChanged:(NSNotification*)notification;
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
- (void) updateGameActionsButtonState;
- (void) updatePanningEnabled;
//@}
@end


@implementation PlayViewController

@synthesize playView;
@synthesize toolbar;
@synthesize playForMeButton;
@synthesize passButton;
@synthesize undoButton;
@synthesize pauseButton;
@synthesize continueButton;
@synthesize flexibleSpaceButton;
@synthesize gameActionsButton;
@synthesize panRecognizer;
@synthesize panningEnabled;


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.playView = nil;
  self.panRecognizer = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.panningEnabled = false;

	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
	[self.panRecognizer release];
	[self.playView addGestureRecognizer:self.panRecognizer];
  self.panRecognizer.delegate = self;
  self.panRecognizer.maximumNumberOfTouches = 1;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameNewCreated:) name:goGameNewCreated object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(goGameScoreChanged:) name:goGameScoreChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];

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

  self.playView = nil;
  self.panRecognizer = nil;
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
/// @brief Reacts to a tap gesture on the "Game Actions" button. Displays an
/// action sheet with actions that related to Go games as a whole.
// -----------------------------------------------------------------------------
- (void) gameActions:(id)sender
{
  PlayViewActionSheetController* controller = [[PlayViewActionSheetController alloc] initWithModalMaster:self];
  [controller showActionSheetFromBarButtonItem:self.gameActionsButton];
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
/// @brief UIGestureRecognizerDelegate protocol method. Disables gesture
/// recognition while interactionEnabled() is false.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return self.isPanningEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameNewCreated:(NSNotification*)notification
{
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
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameScoreChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameScoreChanged:(NSNotification*)notification
{
  if ([GoGame sharedGame].state == GameHasEnded)
  {
    NSString* score = [GoGame sharedGame].score;
    NSString* message = [@"Score = " stringByAppendingString:score];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game has ended"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    alert.tag = GameHasEndedAlertView;
    [alert show];
  }
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
/// @brief Populates the toolbar with toolbar items that are appropriate for
/// the #GoGameType currently in progress.
// -----------------------------------------------------------------------------
- (void) populateToolbar
{
  NSMutableArray* toolbarItems = [NSMutableArray arrayWithCapacity:0];
  switch ([GoGame sharedGame].type)
  {
    case ComputerVsComputerGame:
      [toolbarItems addObject:self.pauseButton];
      [toolbarItems addObject:self.continueButton];
      [toolbarItems addObject:self.flexibleSpaceButton];
      [toolbarItems addObject:self.gameActionsButton];
      break;
    default:
      [toolbarItems addObject:self.playForMeButton];
      [toolbarItems addObject:self.passButton];
      [toolbarItems addObject:self.undoButton];
      [toolbarItems addObject:self.flexibleSpaceButton];
      [toolbarItems addObject:self.gameActionsButton];
      break;
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
  [self updateGameActionsButtonState];
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Play for me" button.
// -----------------------------------------------------------------------------
- (void) updatePlayForMeButtonState
{
  BOOL enabled = NO;
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
  self.playForMeButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Pass" button.
// -----------------------------------------------------------------------------
- (void) updatePassButtonState
{
  BOOL enabled = NO;
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
  self.passButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Undo" button.
// -----------------------------------------------------------------------------
- (void) updateUndoButtonState
{
  BOOL enabled = NO;
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
  self.undoButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Pause" button.
// -----------------------------------------------------------------------------
- (void) updatePauseButtonState
{
  BOOL enabled = NO;
  switch ([GoGame sharedGame].type)
  {
    case ComputerVsComputerGame:
    {
      switch ([GoGame sharedGame].state)
      {
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
  self.pauseButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Continue" button.
// -----------------------------------------------------------------------------
- (void) updateContinueButtonState
{
  BOOL enabled = NO;
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
  self.continueButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "Game Actions" button.
// -----------------------------------------------------------------------------
- (void) updateGameActionsButtonState
{
  BOOL enabled = NO;
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
  self.gameActionsButton.enabled = enabled;
}

// -----------------------------------------------------------------------------
/// @brief Updates whether panning is enabled.
// -----------------------------------------------------------------------------
- (void) updatePanningEnabled
{
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

@end
