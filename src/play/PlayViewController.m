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

// System includes
#import <UIKit/UIKit.h>


// Class extension
@interface PlayViewController()
/// @name Action methods for toolbar items
//@{
- (void) pass:(id)sender;
- (void) resign:(id)sender;
- (void) playForMe:(id)sender;
- (void) undo:(id)sender;
- (void) newGame:(id)sender;
//@}
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer;
/// @name UIGestureRecognizerDelegate protocol
//@{
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer;
//@}
// Notification responders
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) goGameScoreChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
// Updaters
- (void) updateButtonStates;
@end


@implementation PlayViewController

@synthesize playView;
@synthesize playForMeButton;
@synthesize passButton;
@synthesize resignButton;
@synthesize undoButton;
@synthesize newGameButton;
@synthesize panRecognizer;
@synthesize interactionEnabled;

- (void) dealloc
{
  self.playView = nil;
  self.panRecognizer = nil;
  [super dealloc];
}

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
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(goGameScoreChanged:) name:goGameScoreChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];

  [self updateButtonStates];
}

- (void) viewDidUnload
{
  [super viewDidUnload];

  self.playView = nil;
  self.panRecognizer = nil;
}

- (void) pass:(id)sender
{
  [[GoGame sharedGame] pass];
}

- (void) resign:(id)sender
{
  // TODO ask user for confirmation because this action cannot be undone
  [[GoGame sharedGame] resign];
}

- (void) playForMe:(id)sender
{
  [[GoGame sharedGame] computerPlay];
}

- (void) undo:(id)sender
{
  [[GoGame sharedGame] undo];
}

- (void) newGame:(id)sender
{
  // TODO implement this
}

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

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return self.isInteractionEnabled;
}

- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateButtonStates];
}

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

- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  self.interactionEnabled = ! [[GoGame sharedGame] isComputerThinking];
  [self updateButtonStates];
}

- (void) updateButtonStates
{
  BOOL playForMeButtonEnabled = NO;
  BOOL passButtonEnabled = NO;
  BOOL resignButtonEnabled = NO;
  BOOL undoButtonEnabled = NO;
  BOOL newGameButtonEnabled = NO;

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
        undoButtonEnabled = NO; // TODO should be YES;
        newGameButtonEnabled = NO; // TODO should be YES;
        break;
      case GameHasEnded:
        playForMeButtonEnabled = NO;
        passButtonEnabled = NO;
        resignButtonEnabled = NO;
        undoButtonEnabled = NO;
        newGameButtonEnabled = NO; // TODO should be YES;
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

  self.playForMeButton.enabled = playForMeButtonEnabled;
  self.passButton.enabled = passButtonEnabled;
  self.resignButton.enabled = resignButtonEnabled;
  self.undoButton.enabled = undoButtonEnabled;
  self.newGameButton.enabled = newGameButtonEnabled;
}

@end
