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
#import "GameInfoViewController.h"
#import "PlayViewActionSheetController.h"

// Forward declarations
@class ToolbarController;
@class DiscardAndPlayCommand;
@class ScoringModel;


// -----------------------------------------------------------------------------
/// @brief The ToolbarControllerDelegate protocol must be implemented by the
/// delegate of ToolbarController.
// -----------------------------------------------------------------------------
@protocol ToolbarControllerDelegate
/// @brief This method is invoked when the user attempts a play a move while
/// she views a board position where it is the computer's turn to play.
///
/// The delegate may display an alert that this is not possible.
- (void) toolbarControllerAlertCannotPlayOnComputersTurn:(ToolbarController*)controller;
/// @brief This method is invoked when the user attempts to play a move while
/// she views an old board position and playing would result in all future moves
/// being discarded.
///
/// The delegate may display an alert that warns the user of the fact. The user
/// may accept or decline to play the move. If she decides to play, @a command
/// must be executed to play the move.
- (void) toolbarController:(ToolbarController*)controller playOrAlertWithCommand:(DiscardAndPlayCommand*)command;
/// @brief This method is invoked when the user calls up or dismisses the Game
/// Info view. The delegate is responsible for making the view visible, or
/// hiding the view (@a makeVisible indicates which).
- (void) toolbarController:(ToolbarController*)controller makeVisible:(bool)makeVisible gameInfoView:(UIView*)gameInfoView;
@end


// -----------------------------------------------------------------------------
/// @brief The ToolbarController class is responsible for managing the toolbar
/// on the Play tab.
///
/// The responsibilities of ToolbarController include:
/// - Populate the toolbar with buttons that are appropriate for the current
///   game state
/// - Enable/disable buttons in the toolbar
/// - Reacting to the user tapping on buttons in the toolbar
// -----------------------------------------------------------------------------
@interface ToolbarController : NSObject <GameInfoViewControllerDelegate, PlayViewActionSheetDelegate, UIAlertViewDelegate>
{
}

- (id) initWithToolbar:(UIToolbar*)toolbar
          scoringModel:(ScoringModel*)scoringModel
              delegate:(id<ToolbarControllerDelegate>)delegate
  parentViewController:(UIViewController*)parentViewController;

@end
