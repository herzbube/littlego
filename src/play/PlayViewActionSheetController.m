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
#import "PlayViewActionSheetController.h"
#import "ScoringModel.h"
#import "../main/ApplicationDelegate.h"
#import "../go/GoBoardPosition.h"
#import "../go/GoGame.h"
#import "../go/GoScore.h"
#import "../archive/ArchiveViewModel.h"
#import "../command/backup/BackupGameCommand.h"
#import "../command/backup/CleanBackupCommand.h"
#import "../command/game/SaveGameCommand.h"
#import "../command/game/NewGameCommand.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates buttons that are displayed when the user taps the
/// "Game Actions" button on the "Play" view.
///
/// The order in which buttons are enumerated also defines the order in which
/// they appear in the UIActionSheet.
// -----------------------------------------------------------------------------
enum ActionSheetButton
{
  ScoreButton,
  ResignButton,
  UndoResignButton,
  SaveGameButton,
  NewGameButton,
  MaxButton     ///< @brief Pseudo enum value, used to iterate over the other enum values
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewActionSheetController.
// -----------------------------------------------------------------------------
@interface PlayViewActionSheetController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIActionSheetDelegate protocol
//@{
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name UIAlertViewDelegate protocol
//@{
- (void) alertView:(UIAlertView*)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//@}
/// @name NewGameDelegate protocol
//@{
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
//@}
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name Helpers
//@{
- (void) score;
- (void) resign;
- (void) saveGame;
- (void) doSaveGame:(NSString*)gameName;
- (void) newGame;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) NSString* saveGameName;
//@}
@end


@implementation PlayViewActionSheetController

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewActionSheetController object.
///
/// @a aController refers to a view controller based on which modal view
/// controllers can be displayed.
///
/// @a delegate is the delegate object that will be informed when this
/// controller has finished its task.
///
/// @note This is the designated initializer of PlayViewActionSheetController.
// -----------------------------------------------------------------------------
- (id) initWithModalMaster:(UIViewController*)aController delegate:(id<PlayViewActionSheetDelegate>)aDelegate
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.delegate = aDelegate;
  self.saveGameName = nil;
  self.modalMaster = aController;
  self.buttonIndexes = [NSMutableDictionary dictionaryWithCapacity:MaxButton];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewActionSheetController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.saveGameName = nil;
  self.modalMaster = nil;
  self.buttonIndexes = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Action" button. Displays an action
/// sheet with actions that are not used very often during a game.
// -----------------------------------------------------------------------------
- (void) showActionSheetFromView:(UIView*)view
{
  // TODO iPad: Modify this to not include a cancel button (see HIG).
  UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:@"Game actions"
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];

  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;

  // Add buttons in the order that they appear in the ActionSheetButton enum
  GoGame* game = [GoGame sharedGame];
  for (int iterButtonIndex = 0; iterButtonIndex < MaxButton; ++iterButtonIndex)
  {
    NSString* title = nil;
    switch (iterButtonIndex)
    {
      case ScoreButton:
        if (scoringModel.scoringMode)
          continue;
        title = @"Score";
        break;
      case ResignButton:
        if (GoGameTypeComputerVsComputer == game.type)
          continue;
        if (GoGameStateGameHasEnded == game.state)
          continue;
        if (scoringModel.scoringMode)
          continue;
        if (game.boardPosition.isComputerPlayersTurn)
          continue;
        title = @"Resign";
        break;
      case UndoResignButton:
        if (GoGameStateGameHasEnded != game.state)
          continue;
        if (GoGameHasEndedReasonResigned != game.reasonForGameHasEnded)
          continue;
        title = @"Undo resign";
        break;
      case SaveGameButton:
        title = @"Save game";
        break;
      case NewGameButton:
        title = @"New game";
        break;
      default:
        DDLogError(@"%@: Showing action sheet with unexpected button type %d", self, iterButtonIndex);
        assert(0);
        break;
    }
    NSInteger buttonIndex = [actionSheet addButtonWithTitle:title];
    [self.buttonIndexes setObject:[NSNumber numberWithInt:iterButtonIndex]
                           forKey:[NSNumber numberWithInt:buttonIndex]];
  }
  actionSheet.cancelButtonIndex = [actionSheet addButtonWithTitle:@"Cancel"];

  // Showing the acton sheet based on a view generates much smoother animations,
  // at least with the view setup in this app, than based on a bar button item.
  // TODO iPad: The action sheet "base" needs to be re-evaluated on the iPad
  // because there we can have pop-overs. Some historical notes on the bar
  // button item "base": Using this "base" apparently does not disable
  // the other buttons on the toolbar, i.e. the user can still tap other buttons
  // in the toolbar such as "Pass". Review whether this is true, and if it is
  // make sure that the sheet is dismissed if a button from the toolbar is
  // tapped. For details about this, see the UIActionSheet class reference,
  // specifically the documentation for showFromBarButtonItem:animated:().
  [actionSheet showInView:view];
  [actionSheet release];
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
  if (actionSheet.cancelButtonIndex == buttonIndex)
  {
    [self.delegate playViewActionSheetControllerDidFinish:self];
    return;
  }
  id object = [self.buttonIndexes objectForKey:[NSNumber numberWithInt:buttonIndex]];
  enum ActionSheetButton button = [object intValue];
  switch (button)
  {
    case ScoreButton:
      [self score];
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
/// @brief Reacts to a tap gesture on the "Score" action sheet button. Toggles
/// scoring mode on play view.
// -----------------------------------------------------------------------------
- (void) score
{
  ScoringModel* scoringModel = [ApplicationDelegate sharedDelegate].scoringModel;
  scoringModel.scoringMode = ! scoringModel.scoringMode;
  [scoringModel.score calculateWaitUntilDone:false];
  [self.delegate playViewActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Resign" action sheet button.
/// Causes the human player whose turn it currently is to resign the game.
// -----------------------------------------------------------------------------
- (void) resign
{
  // TODO ask user for confirmation because this action cannot be undone

  // Fuego does not have support for resignation, so we don't have to tell it
  // about this event.
  [[GoGame sharedGame] resign];
  [[[[BackupGameCommand alloc] init] autorelease] submit];
  [self.delegate playViewActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Undo resign" action sheet button.
/// Causes the state of the game to revert from "has ended" to one of the
/// various "in progress" states.
// -----------------------------------------------------------------------------
- (void) undoResign
{
  // Fuego does not have support for resignation, so we don't have to tell it
  // about this event.
  [[GoGame sharedGame] revertStateFromEndedToInProgress];
  [[[[BackupGameCommand alloc] init] autorelease] submit];
  [self.delegate playViewActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Save game" action sheet button. Saves
/// the current game to .sgf.
// -----------------------------------------------------------------------------
- (void) saveGame
{
  ArchiveViewModel* model = [ApplicationDelegate sharedDelegate].archiveViewModel;
  NSString* defaultGameName = [model defaultGameName:[GoGame sharedGame]];
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
          DDLogError(@"%@: Dismissing alert view with unexpected button type %d", self, buttonIndex);
          assert(0);
          break;
      }
      break;
    }
    default:
      break;
  }
  [self.delegate playViewActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief NewGameDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  if (didStartNewGame)
  {
    [[[[CleanBackupCommand alloc] init] autorelease] submit];
    [[[[NewGameCommand alloc] init] autorelease] submit];
  }
  [self.modalMaster dismissViewControllerAnimated:YES completion:nil];
  [self.delegate playViewActionSheetControllerDidFinish:self];
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  // TODO Change this check for illegal characters to also use NSPredicate.
  // Note that in a first attempt, the following predicate format string did
  // not work: @"SELF MATCHES '[/\\\\|]+'"
  NSString* illegalCharacterString = @"/\\|";
  NSCharacterSet* illegalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"/\\|"];
  NSRange range = [text rangeOfCharacterFromSet:illegalCharacterSet];
  if (range.location != NSNotFound)
  {
    NSString* errorMessage = [NSString stringWithFormat:@"The name you entered contains one or more of the following illegal characters: %@. Please remove the character(s) and try again.", illegalCharacterString];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Illegal characters in game name"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeSaveGame;
    [alert show];
    [alert release];
    return false;
  }
  NSPredicate* predicateReservedWords = [NSPredicate predicateWithFormat:@"SELF MATCHES '^(.|..)$'"];
  if ([predicateReservedWords evaluateWithObject:text])
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Illegal game name"
                                                    message:@"The name you entered is a reserved word and cannot be used for saving games."
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeSaveGame;
    [alert show];
    [alert release];
    return false;
  }
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  bool playViewActionSheetControllerDidFinish = true;
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
      playViewActionSheetControllerDidFinish = false;
    }
    else
    {
      [self doSaveGame:editTextController.text];
    }
  }
  [self.modalMaster dismissViewControllerAnimated:YES completion:nil];
  if (playViewActionSheetControllerDidFinish)
    [self.delegate playViewActionSheetControllerDidFinish:self];
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
