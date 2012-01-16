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
#import "GameInfoViewController.h"
#import "PlayViewActionSheetController.h"

// Forward declarations
@class PlayView;


// -----------------------------------------------------------------------------
/// @brief The PlayViewController class is responsible for managing user
/// interaction on the "Play" view.
///
/// PlayViewController reacts to the following user input:
/// - Dragging, or panning, gesture in the view's Go board area
///   This is used to place a stone on the board.
/// - Tapping gesture on buttons that trigger a Go move
/// - Tapping gesture on the "Game Actions" button
///
/// In addition, PlayViewController manages the transition to and from the
/// "backside" view which displays information about the current game (including
/// scoring information). The transition is usually triggered by the user
/// tapping on a dedicated button. When the user wants to dismiss the game info
/// view, PlayViewController transitions back to the "frontside" view, which is
/// the main play view.
// -----------------------------------------------------------------------------
@interface PlayViewController : UIViewController <UIGestureRecognizerDelegate, GameInfoViewControllerDelegate, PlayViewActionSheetDelegate>
{
}

@end
