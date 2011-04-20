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


// System includes
#import <UIKit/UIKit.h>

// Forward declarations
@class PlayView;


// -----------------------------------------------------------------------------
/// @brief The PlayViewController class is responsible for managing user
/// interaction on the "Play" view.
///
/// PlayViewController reacts to the following user input:
/// - Dragging, or panning, gesture in the view's Go board area
///   This is used to place a stone on the board.
/// - Tapping gesture on several buttons
// -----------------------------------------------------------------------------
@interface PlayViewController : UIViewController <UIGestureRecognizerDelegate, UIAlertViewDelegate>
{
}

/// @brief The view that PlayViewController is responsible for.
@property(nonatomic, retain) IBOutlet PlayView* playView;
/// @brief The "Play for me" button. Tapping this button causes the computer
/// player to generate a move for the human player whose turn it currently is.
@property(nonatomic, retain) IBOutlet UIBarButtonItem* playForMeButton;
/// @brief The "Pass" button. Tapping this button generates a "Pass" move for
/// the human player whose turn it currently is.
@property(nonatomic, retain) IBOutlet UIBarButtonItem* passButton;
/// @brief The "Resign" button. Tapping this button generates a "Resign" move
/// for the human player whose turn it currently is.
@property(nonatomic, retain) IBOutlet UIBarButtonItem* resignButton;
/// @brief The "Undo" button. Tapping this button takes back the last move made
/// by a human player, including any computer player moves that were made in
/// response.
@property(nonatomic, retain) IBOutlet UIBarButtonItem* undoButton;
/// @brief The "New" button. Tapping this button starts a new game, discarding
/// the current game.
@property(nonatomic, retain) IBOutlet UIBarButtonItem* newGameButton;
/// @brief The gesture recognizer used to detect the dragging, or panning,
/// gesture.
@property(nonatomic, retain) UIPanGestureRecognizer* panRecognizer;
/// @brief True if user interaction is currently enabled, false if not. User
/// interaction is usually disabled while the computer player is thinking about
/// its move.
@property(getter=isInteractionEnabled) bool interactionEnabled;

@end
