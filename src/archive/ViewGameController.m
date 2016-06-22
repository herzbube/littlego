// -----------------------------------------------------------------------------
// Copyright 2011-2015 Patrick Näf (herzbube@herzbube.ch)
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
#import "ArchiveUtility.h"
#import "ArchiveViewModel.h"
#import "../command/game/RenameGameCommand.h"
#import "../command/game/LoadGameCommand.h"
#import "../go/GoGame.h"
#import "../main/MainUtility.h"
#import "../shared/LayoutManager.h"
#import "../ui/TableViewCellFactory.h"


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
/// @brief Class extension with private properties for ViewGameController.
// -----------------------------------------------------------------------------
@interface ViewGameController()
@property(nonatomic, retain) UIBarButtonItem* loadButton;
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
  self.loadButton = nil;
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
  self.loadButton = [[[UIBarButtonItem alloc] initWithTitle:@"Load"
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(loadGame)] autorelease];
  UIBarButtonItem* actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                 target:self
                                                                                 action:@selector(action:)] autorelease];
  actionButton.style = UIBarButtonItemStylePlain;
  self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:actionButton, self.loadButton, nil];
  [self updateLoadButtonState];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  // KVO observing
  [self.game addObserver:self forKeyPath:@"fileDate" options:0 context:NULL];
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
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [editTextController release];
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  enum ArchiveGameNameValidationResult validationResult = [ArchiveUtility validateGameName:text];
  if (ArchiveGameNameValidationResultValid != validationResult)
  {
    [ArchiveUtility showAlertForFailedGameNameValidation:validationResult];
    return false;
  }
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
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [newGameController release];
}

// -----------------------------------------------------------------------------
/// @brief NewGameControllerDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  if (didStartNewGame)
  {
    LoadGameCommand* command = [[[LoadGameCommand alloc] initWithGameName:self.game.name] autorelease];
    [command submit];
  }
  // Must dismiss modal view controller before navigation stack is changed
  // -> if it's done later the modal view controller is *NOT* dismissed
  [self dismissViewControllerAnimated:YES completion:nil];
  if (didStartNewGame)
  {
    [MainUtility activateUIArea:UIAreaPlay];
    // In some layouts activating the Play UI area pops this VC from the
    // navigation stack, in other layouts we have to do the popping ourselves
    if (self.navigationController)
    {
      // No animation necessary, the Play UI area is already visible
      [self.navigationController popViewControllerAnimated:NO];
    }
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
  self.loadButton.enabled = enableButton;
}

// -----------------------------------------------------------------------------
/// @brief Presents a UIDocumentInteractionController
// -----------------------------------------------------------------------------
- (void) action:(id)sender
{
  NSString* sgfFilePath = [self.model filePathForGameWithName:self.game.name];
  NSURL* sgfFileURL = [NSURL fileURLWithPath:sgfFilePath isDirectory:NO];
  UIDocumentInteractionController* interactionController = [UIDocumentInteractionController interactionControllerWithURL:sgfFileURL];
  interactionController.delegate = self;
  interactionController.UTI = sgfUTI;
  [interactionController retain];
  // The Mail app does not appear in the "Open in..." menu if we use
  // presentOpenInMenuFromBarButtonItem:animated:, so we use
  // presentOptionsMenuFromBarButtonItem:animated:.
  BOOL didPresentMenu = [interactionController presentOptionsMenuFromBarButtonItem:sender
                                                                          animated:YES];
  if (! didPresentMenu)
    [interactionController autorelease];
}

// -----------------------------------------------------------------------------
/// @brief UIDocumentInteractionControllerDelegate method.
// -----------------------------------------------------------------------------
- (void) documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController*)controller
{
  [controller autorelease];
}

// -----------------------------------------------------------------------------
/// @brief UIDocumentInteractionControllerDelegate method.
///
/// This is deprecated in iOS 6, so it will probably go away in iOS 7. Until
/// that happens we can still make use of it by adding an item to copy the .sgf
/// file content to the clipboard. When this method goes away, we need to
/// replace it with UIActivityViewController if we want to keep the "Copy"
/// action.
// -----------------------------------------------------------------------------
- (BOOL) documentInteractionController:(UIDocumentInteractionController*)controller canPerformAction:(SEL)action
{
  if (@selector(copy:) == action)
    return YES;
  else
    return NO;
}

// -----------------------------------------------------------------------------
/// @brief UIDocumentInteractionControllerDelegate method.
///
/// This implementation performs the "copy to pasteboard" action.
///
/// This is deprecated in iOS 6, so it will probably go away in iOS 7. See
/// documentInteractionController:canPerformAction:() for some details.
// -----------------------------------------------------------------------------
- (BOOL) documentInteractionController:(UIDocumentInteractionController*)controller performAction:(SEL)action
{
  if (@selector(copy:) != action)
  {
    assert(0);
    DDLogError(@"%@: Cannot perform unsupported action %@", self, NSStringFromSelector(action));
    return NO;
  }

  NSStringEncoding usedEncoding;
  NSError* error;
  NSString* sgfFileContent = [NSString stringWithContentsOfURL:controller.URL
                                                  usedEncoding:&usedEncoding
                                                         error:&error];
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setString:sgfFileContent];
  return YES;
}

@end
