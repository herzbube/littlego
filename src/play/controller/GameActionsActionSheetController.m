// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameActionsActionSheetController.h"
#import "../gameaction/GameActionManager.h"
#import "../../main/ApplicationDelegate.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../archive/ArchiveUtility.h"
#import "../../archive/ArchiveViewModel.h"
#import "../../command/backup/BackupGameToSgfCommand.h"
#import "../../command/backup/CleanBackupSgfCommand.h"
#import "../../command/game/SaveGameCommand.h"
#import "../../command/game/NewGameCommand.h"
#import "../../command/playerinfluence/GenerateTerritoryStatisticsCommand.h"
#import "../../play/model/BoardViewModel.h"
#import "../../play/model/ScoringModel.h"
#import "../../shared/ApplicationStateManager.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates buttons that are displayed when the user taps the
/// "Game Actions" button in #UIAreaPlay.
///
/// The order in which buttons are enumerated also defines the order in which
/// they appear in the UIActionSheet.
// -----------------------------------------------------------------------------
enum ActionSheetButton
{
  ScoreButton,
  MarkModeButton,
  UpdatePlayerInfluenceButton,
  ResignButton,
  UndoResignButton,
  SaveGameButton,
  NewGameButton,
  MaxButton     ///< @brief Pseudo enum value, used to iterate over the other enum values
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// GameActionsActionSheetController.
// -----------------------------------------------------------------------------
@interface GameActionsActionSheetController()
@property(nonatomic, assign) UIActionSheet* actionSheet;
@property(nonatomic, retain) NSString* saveGameName;
@end


@implementation GameActionsActionSheetController

// -----------------------------------------------------------------------------
/// @brief Initializes a GameActionsActionSheetController object.
///
/// @a aController refers to a view controller based on which modal view
/// controllers can be displayed.
///
/// @a delegate is the delegate object that will be informed when this
/// controller has finished its task.
///
/// @note This is the designated initializer of
/// GameActionsActionSheetController.
// -----------------------------------------------------------------------------
- (id) initWithModalMaster:(UIViewController*)aController delegate:(id<GameActionsActionSheetDelegate>)aDelegate
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  self.delegate = aDelegate;
  self.actionSheet = nil;
  self.saveGameName = nil;
  self.modalMaster = aController;
  self.buttonIndexes = [NSMutableDictionary dictionaryWithCapacity:MaxButton];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameActionsActionSheetController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.actionSheet = nil;
  self.saveGameName = nil;
  self.modalMaster = nil;
  self.buttonIndexes = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Action" button. Displays an action
/// sheet with actions that are not used very often during a game.
// -----------------------------------------------------------------------------
- (void) showActionSheetFromRect:(CGRect)rect inView:(UIView*)view
{
  self.actionSheet = [[UIActionSheet alloc] initWithTitle:@"Game actions"
                                                 delegate:self
                                        cancelButtonTitle:nil
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:nil];

  // Add buttons in the order that they appear in the ActionSheetButton enum
  GoGame* game = [GoGame sharedGame];
  for (int iterButtonIndex = 0; iterButtonIndex < MaxButton; ++iterButtonIndex)
  {
    NSString* title = nil;
    switch (iterButtonIndex)
    {
      case ScoreButton:
      {
        if (game.score.scoringEnabled || GoGameStateGameHasEnded == game.state)
          continue;
        title = @"Score";
        break;
      }
      case MarkModeButton:
      {
        if (! game.score.scoringEnabled)
          continue;
        ScoringModel* model = [ApplicationDelegate sharedDelegate].scoringModel;
        switch (model.scoreMarkMode)
        {
          case GoScoreMarkModeDead:
          {
            title = @"Start marking as seki";
            break;
          }
          case GoScoreMarkModeSeki:
          {
            title = @"Start marking as dead";
            break;
          }
          default:
          {
            assert(0);
            return;
          }
        }
        break;
      }
      case UpdatePlayerInfluenceButton:
      {
        BoardViewModel* model = [ApplicationDelegate sharedDelegate].boardViewModel;
        if (! model.displayPlayerInfluence)
          continue;
        if (game.score.scoringEnabled)
          continue;
        title = @"Update player influence";
        break;
      }
      case ResignButton:
      {
        if (GoGameTypeComputerVsComputer == game.type)
          continue;
        if (GoGameStateGameHasEnded == game.state)
          continue;
        if (game.score.scoringEnabled)
          continue;
        if (game.nextMovePlayerIsComputerPlayer)
          continue;
        // Resigning the game performs a backup of the game in progress. We
        // can't let that happen if it's not the last board position, otherwise
        // the backup .sgf file would not contain the full game.
        if (! game.boardPosition.isLastPosition)
          continue;
        title = @"Resign";
        break;
      }
      case UndoResignButton:
      {
        if (GoGameStateGameHasEnded != game.state)
          continue;
        if (GoGameHasEndedReasonResigned != game.reasonForGameHasEnded)
          continue;
        // Undoing a resignation performs a backup of the game in progress. We
        // can't let that happen if it's not the last board position, otherwise
        // the backup .sgf file would not contain the full game.
        if (! game.boardPosition.isLastPosition)
          continue;
        title = @"Undo resign";
        break;
      }
      case SaveGameButton:
      {
        title = @"Save game";
        break;
      }
      case NewGameButton:
      {
        title = @"New game";
        break;
      }
      default:
      {
        DDLogError(@"%@: Showing action sheet with unexpected button type %d", self, iterButtonIndex);
        assert(0);
        break;
      }
    }
    NSInteger buttonIndex = [self.actionSheet addButtonWithTitle:title];
    [self.buttonIndexes setObject:[NSNumber numberWithInt:iterButtonIndex]
                           forKey:[NSNumber numberWithInteger:buttonIndex]];
  }

  // On the iPad the cancel button is not displayed, but if the user taps
  // outside of the popover to cancel the action sheet, the action sheet
  // notifies the delegate with the button index stored in cancelButtonIndex
  self.actionSheet.cancelButtonIndex = [self.actionSheet addButtonWithTitle:@"Cancel"];

  // It's important that we do NOT use showFromBarButtonItem:animated:(), for
  // two reasons:
  // 1) On the iPad this would allow other buttons in the bar button item's
  //    parent navigation bar to be tapped without dismissing the action sheet.
  //    This would be bad because the app logic requires that in certain app
  //    states the functions from the "Game Actions" menu must not be available.
  // 2) On the iPhone, showFromBarButtonItem:animated:() simply seems to not
  //    work properly - items in the action sheet cannot be selected when that
  //    method is used.
  [self.actionSheet showFromRect:rect inView:view animated:YES];
  [self.actionSheet release];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user selecting an action from the action sheet
/// displayed when the "Action" button was tapped.
///
/// We could also implement actionSheet:clickedButtonAtIndex:(), but visually
/// it looks better to do UI stuff (e.g. display "new game" modal view)
/// *AFTER* the alert sheet has been dismissed.
// -----------------------------------------------------------------------------
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  self.actionSheet = nil;
  if (actionSheet.cancelButtonIndex == buttonIndex)
  {
    [self.delegate gameActionsActionSheetControllerDidFinish:self];
    return;
  }
  id object = [self.buttonIndexes objectForKey:[NSNumber numberWithInteger:buttonIndex]];
  enum ActionSheetButton button = [object intValue];
  switch (button)
  {
    case ScoreButton:
      [self score];
      break;
    case MarkModeButton:
      [self toggleMarkMode];
      break;
    case UpdatePlayerInfluenceButton:
      [self updatePlayerInfluence];
      break;
    case ResignButton:
      [self resign];
      break;
    case UndoResignButton:
      [self undoResign];
      break;
    case SaveGameButton:
      [self saveGame];
      break;
    case NewGameButton:
      [self newGame];
      break;
    default:
      DDLogError(@"%@: Dismissing action sheet with unexpected button type %d", self, button);
      assert(0);
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Cancels the action sheet if it is currently displayed.
// -----------------------------------------------------------------------------
- (void) cancelActionSheet
{
  if (! self.actionSheet)
    return;
  [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:NO];
  // Don't do anything else, the above line caused this
  // GameActionsActionSheetController to be deallocated
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Score" action sheet button. Enables
/// scoring mode.
// -----------------------------------------------------------------------------
- (void) score
{
  [[GameActionManager sharedGameActionManager] scoringStart:self];
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Start marking as [...]" action sheet
/// button. Toggles the mark mode during scoring.
// -----------------------------------------------------------------------------
- (void) toggleMarkMode
{
  ScoringModel* model = [ApplicationDelegate sharedDelegate].scoringModel;
  switch (model.scoreMarkMode)
  {
    case GoScoreMarkModeDead:
    {
      model.scoreMarkMode = GoScoreMarkModeSeki;
      break;
    }
    case GoScoreMarkModeSeki:
    {
      model.scoreMarkMode = GoScoreMarkModeDead;
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Update player influence" action sheet
/// button. Triggers a long-running GTP command at the end of which the new
/// player influence values are drawn.
// -----------------------------------------------------------------------------
- (void) updatePlayerInfluence
{
  [[[[GenerateTerritoryStatisticsCommand alloc] init] autorelease] submit];
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Resign" action sheet button.
/// Causes the human player whose turn it currently is to resign the game.
// -----------------------------------------------------------------------------
- (void) resign
{
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[GoGame sharedGame] resign];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
  [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Undo resign" action sheet button.
/// Causes the state of the game to revert from "has ended" to one of the
/// various "in progress" states.
// -----------------------------------------------------------------------------
- (void) undoResign
{
  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];
    [[GoGame sharedGame] revertStateFromEndedToInProgress];
  }
  @finally
  {
    [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
  [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Save game" action sheet button. Saves
/// the current game to .sgf.
// -----------------------------------------------------------------------------
- (void) saveGame
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* defaultGameName = [model uniqueGameNameForGame:[GoGame sharedGame]];
  EditTextController* editTextController = [[EditTextController controllerWithText:defaultGameName
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"Game name";
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self.modalMaster presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [editTextController release];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "New game" action sheet button. Starts
/// a new game, discarding the current game.
// -----------------------------------------------------------------------------
- (void) newGame
{
  // This controller manages the actual "New Game" view
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self loadGame:false] retain];

  // This controller provides a navigation bar at the top of the screen where
  // it will display the navigation item that represents the "new game"
  // controller. The "new game" controller internally configures this
  // navigation item according to its needs.
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  // Present the navigation controller, not the "new game" controller.
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self.modalMaster presentViewController:navigationController animated:YES completion:nil];
  // Cleanup
  [navigationController release];
  [newGameController release];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user dismissing an alert view for which this controller
/// is the delegate.
// -----------------------------------------------------------------------------
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  switch (buttonIndex)
  {
    case AlertViewButtonTypeNo:
      break;
    case AlertViewButtonTypeYes:
    {
      switch (alertView.tag)
      {
        case AlertViewTypeSaveGame:
          [self doSaveGame:self.saveGameName];
          self.saveGameName = nil;
          break;
        default:
          DDLogError(@"%@: Dismissing alert view with unexpected button type %ld", self, (long)buttonIndex);
          assert(0);
          break;
      }
      break;
    }
    default:
      break;
  }
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief NewGameDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  if (didStartNewGame)
  {
    [[[[CleanBackupSgfCommand alloc] init] autorelease] submit];
    [[[[NewGameCommand alloc] init] autorelease] submit];
  }
  [self.modalMaster dismissViewControllerAnimated:YES completion:nil];
  [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  enum ArchiveGameNameValidationResult validationResult = [ArchiveUtility validateGameName:text];
  if (ArchiveGameNameValidationResultValid == validationResult)
  {
    return true;
  }
  else
  {
    [ArchiveUtility showAlertForFailedGameNameValidation:validationResult];
    return false;
  }
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  bool gameActionsActionSheetControllerDidFinish = true;
  if (! didCancel)
  {
    ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
    if ([model gameWithName:editTextController.text])
    {
      UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game already exists"
                                                      message:@"Another game with that name already exists. Do you want to overwrite that game?"
                                                     delegate:self
                                            cancelButtonTitle:@"No"
                                            otherButtonTitles:@"Yes", nil];
      alert.tag = AlertViewTypeSaveGame;
      [alert show];
      [alert release];
      // Remember game name for later use (should the user confirm the
      // overwrite).
      self.saveGameName = editTextController.text;
      // We are not yet finished, user must still confirm/reject the overwrite
      gameActionsActionSheetControllerDidFinish = false;
    }
    else
    {
      [self doSaveGame:editTextController.text];
    }
  }
  [self.modalMaster dismissViewControllerAnimated:YES completion:nil];
  if (gameActionsActionSheetControllerDidFinish)
    [self.delegate gameActionsActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Performs the actual "save game" operation. The saved game is named
/// @a gameName. If a game with that name already exists, it is overwritten.
// -----------------------------------------------------------------------------
- (void) doSaveGame:(NSString*)gameName
{
  [[[[SaveGameCommand alloc] initWithSaveGame:gameName] autorelease] submit];
}

@end
