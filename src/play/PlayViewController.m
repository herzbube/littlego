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
- (void) play:(id)sender;
- (void) pass:(id)sender;
- (void) resign:(id)sender;
- (void) playForMe:(id)sender;
- (void) undo:(id)sender;
- (void) new:(id)sender;
//@}
- (void) handlePanFrom:(UIPanGestureRecognizer*)gestureRecognizer;
@end


@implementation PlayViewController

@synthesize playView;
@synthesize panRecognizer;

- (void) dealloc
{
  self.playView = nil;
  self.panRecognizer = nil;
  [super dealloc];
}

- (void) viewDidLoad
{
  [super viewDidLoad];

	self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
	[self.playView addGestureRecognizer:self.panRecognizer];
  self.panRecognizer.delegate = self;
  self.panRecognizer.maximumNumberOfTouches = 1;
	[self.panRecognizer release];
}

- (void) viewDidUnload
{
  self.playView = nil;
  self.panRecognizer = nil;
}

- (void) play:(id)sender
{
  // todo before actual playing, ask GoGame whether the move would be legal
  // -> GoGame queries Fuego with the "is_legal" GTP command
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
  [[GoGame sharedGame] playForMe];
}

- (void) undo:(id)sender
{
  [[GoGame sharedGame] undo];
}

- (void) new:(id)sender
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
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
      break;
    case UIGestureRecognizerStateChanged:
      break;
    case UIGestureRecognizerStateEnded:
      break;
    case UIGestureRecognizerStateCancelled:
      break;
    default:
      return;
  }
  CGPoint coordinateLocation = [gestureRecognizer locationInView:self.playView];
  [self.playView moveCrossHairTo:coordinateLocation];
}

@end
