// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PanGestureController.h"
#import "../playview/PlayView.h"
#import "../../command/boardposition/DiscardAndPlayCommand.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PanGestureController.
// -----------------------------------------------------------------------------
@interface PanGestureController()
@property(nonatomic, retain) UILongPressGestureRecognizer* longPressRecognizer;
@property(nonatomic, assign, getter=isPanningEnabled) bool panningEnabled;
@end


@implementation PanGestureController

// -----------------------------------------------------------------------------
/// @brief Initializes a PanGestureController object.
///
/// @note This is the designated initializer of PanGestureController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.playView = nil;
  self.delegate = nil;
  [self setupLongPressGestureRecognizer];
  [self setupNotificationResponders];
  [self updatePanningEnabled];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PanGestureController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[GoGame sharedGame].boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  self.playView = nil;
  self.longPressRecognizer = nil;
  self.delegate = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupLongPressGestureRecognizer
{
  self.longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)] autorelease];
  self.longPressRecognizer.delegate = self;
  CGFloat infiniteMovement = CGFLOAT_MAX;
  self.longPressRecognizer.allowableMovement = infiniteMovement;  // let the user pan as long as he wants
  self.longPressRecognizer.minimumPressDuration = gPlayViewLongPressDelay;
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
  [center addObserver:self selector:@selector(goScoreTerritoryScoringEnabled:) name:goScoreTerritoryScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreTerritoryScoringDisabled:) name:goScoreTerritoryScoringDisabled object:nil];
  // KVO observing
  [[GoGame sharedGame].boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private setter implementation.
// -----------------------------------------------------------------------------
- (void) setPlayView:(PlayView*)playView
{
  if (_playView == playView)
    return;
  if (_playView && self.longPressRecognizer)
    [_playView removeGestureRecognizer:self.longPressRecognizer];
  _playView = playView;
  if (_playView && self.longPressRecognizer)
    [_playView addGestureRecognizer:self.longPressRecognizer];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a dragging, or panning, gesture in the view's Go board
/// area.
// -----------------------------------------------------------------------------
- (void) handlePanFrom:(UILongPressGestureRecognizer*)gestureRecognizer
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
  GoPoint* crossHairPoint = [self.playView crossHairPointNear:panningLocation];

  // TODO If the move is not legal, determine the reason (another stone is
  // already placed on the point; suicide move; guarded by Ko rule)
  bool isLegalMove = false;
  if (crossHairPoint)
    isLegalMove = [[GoGame sharedGame] isLegalMove:crossHairPoint];

  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
    {
      [self.playView moveCrossHairTo:crossHairPoint isLegalMove:isLegalMove];
      break;
    }
    case UIGestureRecognizerStateChanged:
    {
      [self.playView moveCrossHairTo:crossHairPoint isLegalMove:isLegalMove];
      break;
    }
    case UIGestureRecognizerStateEnded:
    {
      [self.playView moveCrossHairTo:nil isLegalMove:true];
      if (isLegalMove)
      {
        DiscardAndPlayCommand* command = [[[DiscardAndPlayCommand alloc] initWithPoint:crossHairPoint] autorelease];
        [self.delegate panGestureController:self playOrAlertWithCommand:command];
      }
      break;
    }
    case UIGestureRecognizerStateCancelled:
    {
      // Occurs, for instance, if an alert is displayed while a gesture is
      // being handled.
      [self.playView moveCrossHairTo:nil isLegalMove:true];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return (self.isPanningEnabled ? YES : NO);
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameWillCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  [oldGame.boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [newGame.boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringEnabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringEnabled:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreTerritoryScoringDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreTerritoryScoringDisabled:(NSNotification*)notification
{
  [self updatePanningEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == [GoGame sharedGame].boardPosition)
  {
    [self updatePanningEnabled];
  }
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

  if (game.score.territoryScoringEnabled)
  {
    self.panningEnabled = false;
    return;
  }

  if (GoGameTypeComputerVsComputer == game.type)
  {
    self.panningEnabled = false;
    return;
  }

  switch (game.state)
  {
    case GoGameStateGameHasStarted:
      if (game.isComputerThinking)
        self.panningEnabled = false;
      else
      {
        GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
        if (boardPosition.isComputerPlayersTurn)
          self.panningEnabled = false;
        else
          self.panningEnabled = true;
      }
      break;
    default:  // specifically GoGameStateGameHasEnded
      self.panningEnabled = false;
      break;
  }
}

@end
