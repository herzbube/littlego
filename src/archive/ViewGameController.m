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
#import "ViewGameController.h"
#import "ArchiveGame.h"
#import "ArchiveViewModel.h"
#import "../go/GoGame.h"
#import "../command/game/RenameGameCommand.h"
#import "../command/game/LoadGameCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Game" table view.
// -----------------------------------------------------------------------------
enum EditGameTableViewSection
{
  GameNameSection,
  GameAttributesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameNameSection.
// -----------------------------------------------------------------------------
enum GameNameSectionItem
{
  GameNameItem,
  MaxGameNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GameAttributesSection.
// -----------------------------------------------------------------------------
enum GameAttributesSectionItem
{
  LastSavedDateItem,
  MaxGameAttributesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ViewGameController.
// -----------------------------------------------------------------------------
@interface ViewGameController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name NewGameDelegate protocol
//@{
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame;
//@}
/// @name Notification responders
//@{
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Helpers
//@{
- (void) editGame;
- (void) loadGame;
- (void) updateLoadButtonState;
//@}
@end


@implementation ViewGameController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a ViewGameController instance of
/// grouped style that is used to view information associated with @a game.
// -----------------------------------------------------------------------------
+ (ViewGameController*) controllerWithGame:(ArchiveGame*)game model:(ArchiveViewModel*)model
{
  ViewGameController* controller = [[ViewGameController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.game = game;
    controller.model = model;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ViewGameController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.game removeObserver:self forKeyPath:@"fileDate"];

  self.game = nil;
  self.model = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.title = @"View Game";
  UIBarButtonItem* emailButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:emailIconResource]
                                                              style:UIBarButtonItemStyleBordered
                                                             target:self
                                                             action:@selector(emailGame)] autorelease];
  UIBarButtonItem* loadButton = [[[UIBarButtonItem alloc] initWithTitle:@"Load"
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(loadGame)] autorelease];
  self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:loadButton, emailButton, nil];
  [self updateLoadButtonState];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  // KVO observing
  [self.game addObserver:self forKeyPath:@"fileDate" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  // Undo all of the stuff that is happening in viewDidLoad
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.game removeObserver:self forKeyPath:@"fileDate"];
  self.navigationItem.rightBarButtonItem = nil;
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case GameNameSection:
      return MaxGameNameSectionItem;
    case GameAttributesSection:
      return MaxGameAttributesSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
  switch (indexPath.section)
  {
    case GameNameSection:
    {
      switch (indexPath.row)
      {
        case GameNameItem:
        {
          cell.textLabel.text = @"Game name";
          cell.detailTextLabel.text = self.game.name;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        default:
          assert(0);
          break;
      }
      break;
    }
    case GameAttributesSection:
    {
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      switch (indexPath.row)
      {
        case LastSavedDateItem:
          cell.textLabel.text = @"Last saved";
          cell.detailTextLabel.text = self.game.fileDate;
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    default:
      assert(0);
      break;
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  switch (indexPath.section)
  {
    case GameNameSection:
    {
      switch (indexPath.row)
      {
        case GameNameItem:
          [self editGame];
          break;
        default:
          break;
      }
      break;
    }
    default:
      break;
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateLoadButtonState];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateLoadButtonState];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Displays EditTextController to allow the user to change the
/// archive game's name.
// -----------------------------------------------------------------------------
- (void) editGame
{
  EditTextController* editTextController = [[EditTextController controllerWithText:self.game.name
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"Game name";
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:editTextController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [editTextController release];
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  ArchiveGame* aGame = [self.model gameWithName:text];
  if (nil == aGame)
    return true;  // ok, no game with the new name exists
  else if (aGame == self.game)
    return true;  // ok, user has made no real changes
  UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Game already exists"
                                                  message:@"Please choose a different name. Another game with that name already exists."
                                                 delegate:self
                                        cancelButtonTitle:nil
                                        otherButtonTitles:@"Ok", nil];
  alert.tag = AlertViewTypeRenameGame;
  [alert show];
  [alert release];
  return false;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    RenameGameCommand* command = [[[RenameGameCommand alloc] initWithGame:self.game
                                                                  newName:editTextController.text] autorelease];
    [command submit];

    [self.tableView reloadData];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

// -----------------------------------------------------------------------------
/// @brief Displays NewGameController to allow the user to start a new game and
/// load the game's initial state from the archive game being viewed.
// -----------------------------------------------------------------------------
- (void) loadGame
{
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self loadGame:true] retain];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [newGameController release];
}

// -----------------------------------------------------------------------------
/// @brief NewGameDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  if (didStartNewGame)
  {
    NSString* filePath = [self.model.archiveFolder stringByAppendingPathComponent:self.game.fileName];
    LoadGameCommand* command = [[[LoadGameCommand alloc] initWithFilePath:filePath gameName:self.game.name] autorelease];
    [command submit];
  }
  // Must dismiss modal view controller before navigation stack is changed
  // -> if it's done later the modal view controller is *NOT* dismissed
  [self dismissViewControllerAnimated:YES completion:nil];
  if (didStartNewGame)
  {
    [[ApplicationDelegate sharedDelegate] activateTab:TabTypePlay];
    // No animation necessary, the Play tab is now visible
    [self.navigationController popViewControllerAnimated:NO];
  }
}

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "load game" button.
///
/// The button is disabled if a computer player is currently thinking, or if a
/// computer vs. computer game is not paused. With this measure we avoid the
/// complicated multi-thread handling of the situation where we need to wait for
/// the computer player to finish thinking before we can discard the current
/// game in favour of the game to be loaded.
// -----------------------------------------------------------------------------
- (void) updateLoadButtonState
{
  BOOL enableButton = NO;
  GoGame* goGame = [GoGame sharedGame];
  switch (goGame.type)
  {
    case GoGameTypeComputerVsComputer:
    {
      switch (goGame.state)
      {
        case GoGameStateGameIsPaused:
        case GoGameStateGameHasEnded:
          if (! goGame.isComputerThinking)
            enableButton = YES;
          break;
        default:
          break;
      }
      break;
    }
    default:
    {
      if (! goGame.isComputerThinking)
        enableButton = YES;
      break;
    }
  }
  self.navigationItem.rightBarButtonItem.enabled = enableButton;
}

// -----------------------------------------------------------------------------
/// @brief Presents mail composer with the .sgf file attached, or displays an
/// alert if the device is not configured for sending emails.
// -----------------------------------------------------------------------------
- (void) emailGame
{
  if (! [self canSendMail])
    return;
  DDLogVerbose(@"%@: Presenting mail composer for game %@", self, self.game.name);
  MFMailComposeViewController* mailComposeViewController = [[MFMailComposeViewController alloc] init];
  mailComposeViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  mailComposeViewController.mailComposeDelegate = self;
  mailComposeViewController.subject = self.game.name;

  NSString* sgfFilePath = [self.model.archiveFolder stringByAppendingPathComponent:self.game.fileName];
  NSData* data = [NSData dataWithContentsOfFile:sgfFilePath];
  [mailComposeViewController addAttachmentData:data mimeType:sgfMimeType fileName:self.game.fileName];

  [self presentViewController:mailComposeViewController animated:YES completion:nil];
  [mailComposeViewController release];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for emailGame.
// -----------------------------------------------------------------------------
- (bool) canSendMail
{
  bool canSendMail = [MFMailComposeViewController canSendMail];
  if (! canSendMail)
  {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Operation failed"
                                                    message:@"This device is not configured to send email."
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = AlertViewTypeCannotSendEmail;
    [alert show];
    [alert release];
  }
  return canSendMail;
}

// -----------------------------------------------------------------------------
/// @brief MFMailComposeViewControllerDelegate method
// -----------------------------------------------------------------------------
- (void) mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
  DDLogVerbose(@"%@: Dismissing mail composer for game %@", self, self.game.name);
  [self dismissViewControllerAnimated:YES completion:nil];
}

@end
