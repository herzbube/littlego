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
#import "../go/GoGame.h"


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
- (void) resign:(id)sender;
- (void) playForMe:(id)sender;
- (void) undo:(id)sender;
- (void) pause:(id)sender;
- (void) continue:(id)sender;
- (void) newGame:(id)sender;
//@}
/// @name Handlers for recognized gestures
//@{
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer;
//@}
/// @name UIGestureRecognizerDelegate protocol
//@{
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name NewGameDelegate protocol
//@{
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
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
//@}
/// @name Helpers
//@{
- (void) doNewGame;
//@}
@end


@implementation PlayViewController

@synthesize playView;
@synthesize toolbar;
@synthesize playForMeButton;
@synthesize passButton;
@synthesize resignButton;
@synthesize undoButton;
@synthesize pauseButton;
@synthesize continueButton;
@synthesize flexibleSpaceButton;
@synthesize newGameButton;
@synthesize panRecognizer;
@synthesize interactionEnabled;

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

  self.interactionEnabled = true;

	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
	[self.playView addGestureRecognizer:self.panRecognizer];
  self.panRecognizer.delegate = self;
  self.panRecognizer.maximumNumberOfTouches = 1;
	[self.panRecognizer release];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  // TODO do we really need two notifications?
  [center addObserver:self selector:@selector(goGameNewCreated:) name:goGameNewCreated object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(goGameScoreChanged:) name:goGameScoreChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];

  [self populateToolbar];
  [self updateButtonStates];
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
  [[GoGame sharedGame] pass];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Resign" button. Generates a "Resign"
/// move for the human player whose turn it currently is.
// -----------------------------------------------------------------------------
- (void) resign:(id)sender
{
  // TODO ask user for confirmation because this action cannot be undone
  [[GoGame sharedGame] resign];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Play for me" button. Causes the
/// computer player to generate a move for the human player whose turn it
/// currently is.
// -----------------------------------------------------------------------------
- (void) playForMe:(id)sender
{
  [[GoGame sharedGame] computerPlay];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Undo" button. Takes back the last
/// move made by a human player, including any computer player moves that were
/// made in response.
// -----------------------------------------------------------------------------
- (void) undo:(id)sender
{
  [[GoGame sharedGame] undo];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Pause" button. Pauses the game if
/// two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) pause:(id)sender
{
  [[GoGame sharedGame] pause];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Undo" button. Continues the game if
/// it is paused while two computer players play against each other.
// -----------------------------------------------------------------------------
- (void) continue:(id)sender
{
  [[GoGame sharedGame] continue];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "New" button. Starts a new game,
/// discarding the current game.
// -----------------------------------------------------------------------------
- (void) newGame:(id)sender
{
  GoGame* game = [GoGame sharedGame];
  switch (game.state)
  {
    case GameHasStarted:
    case GameIsPaused:
    {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"New game"
                                                      message:@"Are you sure you want to start a new game and discard the game in progress?"
                                                     delegate:self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
      [alert show];
      break;
    }
    default:
    {
      [self doNewGame];
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case 0:
      // "No" button clicked
      break;
    case 1:
      // "Yes" button clicked
      [self doNewGame];
      break;
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a dragging, or panning, gesture in the view's Go board
/// area.
// -----------------------------------------------------------------------------
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer
{
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


  // TODO Prevent panning and other actions (e.g. pass) while the computer
  // player is thinking

  CGPoint panningLocation = [gestureRecognizer locationInView:self.playView];
  GoPoint* crossHairPoint = [self.playView crossHairPointAt:panningLocation];

  // TODO If the move is not legal, determine the reason (another stone is
  // already placed on the point; suicide move; guarded by Ko rule)
  bool isLegalMove = false;
  if (crossHairPoint)
    isLegalMove = [[GoGame sharedGame] isLegalNextMove:crossHairPoint];

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
        [[GoGame sharedGame] play:crossHairPoint];
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
  return self.isInteractionEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameNewCreated:(NSNotification*)notification
{
  [self populateToolbar];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateButtonStates];
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
    [alert show];
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.interactionEnabled = ! [[GoGame sharedGame] isComputerThinking];
  [self updateButtonStates];
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
      [toolbarItems addObject:self.newGameButton];
      break;
    default:
      [toolbarItems addObject:self.playForMeButton];
      [toolbarItems addObject:self.passButton];
      [toolbarItems addObject:self.resignButton];
      [toolbarItems addObject:self.undoButton];
      [toolbarItems addObject:self.flexibleSpaceButton];
      [toolbarItems addObject:self.newGameButton];
      break;
  }
  self.toolbar.items = toolbarItems;
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of all toolbar items.
// -----------------------------------------------------------------------------
- (void) updateButtonStates
{
  BOOL playForMeButtonEnabled = NO;
  BOOL passButtonEnabled = NO;
  BOOL resignButtonEnabled = NO;
  BOOL undoButtonEnabled = NO;
  BOOL pauseButtonEnabled = NO;
  BOOL continueButtonEnabled = NO;
  BOOL newGameButtonEnabled = NO;

  switch ([GoGame sharedGame].type)
  {
    case ComputerVsComputerGame:
      switch ([GoGame sharedGame].state)
      {
        case GameHasNotYetStarted:
          pauseButtonEnabled = NO;
          continueButtonEnabled = NO;
          newGameButtonEnabled = YES;
          break;
        case GameHasStarted:
          pauseButtonEnabled = YES;
          continueButtonEnabled = NO;
          newGameButtonEnabled = NO;
          break;
        case GameIsPaused:
          pauseButtonEnabled = NO;
          continueButtonEnabled = YES;
          // New game is only allowed if the computer player has finished
          // thinking
          newGameButtonEnabled = ! [GoGame sharedGame].isComputerThinking;
          break;
        case GameHasEnded:
          pauseButtonEnabled = NO;
          continueButtonEnabled = NO;
          newGameButtonEnabled = YES;
          break;
        default:
          break;
      }
      break;
    default:
      if (self.isInteractionEnabled)
      {
        switch ([GoGame sharedGame].state)
        {
          case GameHasNotYetStarted:
            playForMeButtonEnabled = YES;
            passButtonEnabled = YES;
            resignButtonEnabled = NO;
            undoButtonEnabled = NO;
            newGameButtonEnabled = YES;
            break;
          case GameHasStarted:
            playForMeButtonEnabled = YES;
            passButtonEnabled = YES;
            resignButtonEnabled = YES;
            if ([GoGame sharedGame].lastMove != nil)
              undoButtonEnabled = YES;
            else
              undoButtonEnabled = NO;
            newGameButtonEnabled = YES;
            break;
          case GameIsPaused:
            assert(false);  // should never happen if a human player is involved
            break;
          case GameHasEnded:
            playForMeButtonEnabled = NO;
            passButtonEnabled = NO;
            resignButtonEnabled = NO;
            undoButtonEnabled = NO;
            newGameButtonEnabled = YES;
            break;
          default:
            break;
        }
      }
      else
      {
        playForMeButtonEnabled = NO;
        passButtonEnabled = NO;
        resignButtonEnabled = NO;
        undoButtonEnabled = NO;
        newGameButtonEnabled = NO;
      }
      break;
  }

  self.playForMeButton.enabled = playForMeButtonEnabled;
  self.passButton.enabled = passButtonEnabled;
  self.resignButton.enabled = resignButtonEnabled;
  self.undoButton.enabled = undoButtonEnabled;
  self.pauseButton.enabled = pauseButtonEnabled;
  self.continueButton.enabled = continueButtonEnabled;
  self.newGameButton.enabled = newGameButtonEnabled;
}

// -----------------------------------------------------------------------------
/// @brief Displays NewGameController as a modal view controller to gather
/// information required to start a new game.
// -----------------------------------------------------------------------------
- (void) doNewGame;
{
  // This controller manages the actual "New Game" view
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self] retain];

  // This controller provides a navigation bar at the top of the screen where
  // it will display the navigation item that represents the "new game"
  // controller. The "new game" controller internally configures this
  // navigation item according to its needs.
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  // Present the navigation controller, not the "new game" controller.
  navigationController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
  [self presentModalViewController:navigationController animated:YES];
  // Cleanup
  [navigationController release];
  [newGameController release];
}

// -----------------------------------------------------------------------------
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didStartNewGame is true, the user has requested starting a new game.
/// If @a didStartNewGame is false, the user has cancelled starting a new game.
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  [self dismissModalViewControllerAnimated:YES];
}

@end
