// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
@property(nonatomic, retain) UIBarButtonItem* actionButton;
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
  self.actionButton = nil;
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
  self.actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                     target:self
                                                                     action:@selector(action:)] autorelease];
  self.actionButton.style = UIBarButtonItemStylePlain;
  self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:self.actionButton, self.loadButton, nil];
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
    [ArchiveUtility showAlertForFailedGameNameValidation:validationResult
                                          alertPresenter:editTextController];
    return false;
  }
  ArchiveGame* aGame = [self.model gameWithName:text];
  if (nil == aGame)
    return true;  // ok, no game with the new name exists
  else if (aGame == self.game)
    return true;  // ok, user has made no real changes

  UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Game already exists"
                                                                           message:@"Please choose a different name. Another game with that name already exists."
                                                                    preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction* action) {}];
  [alertController addAction:okAction];

  [editTextController presentViewController:alertController animated:YES completion:nil];

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
/// @brief Presents a UIActivityViewController
// -----------------------------------------------------------------------------
- (void) action:(id)sender
{
  // We can use self because this controller conforms to the
  // UIActivityItemSource protocol. When UIActivityViewController is presented
  // it will start invoking UIActivityItemSource protocol methods in this
  // controller.
  NSArray* activityItems = @[self];
  NSArray* applicationActivities = nil;
  UIActivityViewController* activityViewController = [[[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                                        applicationActivities:applicationActivities] autorelease];

  NSMutableArray* excludedActivityTypes = [NSMutableArray arrayWithArray:
                                             @[UIActivityTypeAddToReadingList,
                                               UIActivityTypeAssignToContact,
                                               // Apparently Facebook does not allow to
                                               // pre-populate a message for the user
                                               UIActivityTypePostToFacebook,
                                               // Crazy idea: Render a Go board with
                                               // the content of the .sgf
                                               UIActivityTypePostToFlickr,
                                               UIActivityTypePostToVimeo,
                                               UIActivityTypeSaveToCameraRoll,
                                               // Don't know what this is
                                               UIActivityTypeOpenInIBooks]];
  if (@available(iOS 11, *))
  {
    // Don't know what this is
    [excludedActivityTypes addObject:UIActivityTypeMarkupAsPDF];
  }
  activityViewController.excludedActivityTypes = excludedActivityTypes;

  [self presentViewController:activityViewController animated:YES completion:nil];

  // As documented in the UIPopoverPresentationController class reference,
  // we should wait with accessing the presentation controller until after we
  // initiate the presentation, otherwise the controller may not have been
  // created yet. Furthermore, a presentation controller is only created on
  // the iPad, but not on the iPhone, so we check for the controller's
  // existence before using it.
  if (activityViewController.popoverPresentationController)
    activityViewController.popoverPresentationController.barButtonItem = self.actionButton;
}

// -----------------------------------------------------------------------------
/// @brief UIActivityItemSource method.
///
/// Returns a placeholder object for the .sgf file. The object type has an
/// effect on which activities are presented to the user. This SO answer [1]
/// suggests that returning a placeholder object that is a plain NSObject
/// instance is best, because placeholders that are not NSObject might cause
/// some activities to be filtered out. However, this information seems to be
/// incorrect - if we return an auto-released NSObject the list of activities
/// presented to the user is empty.
///
// [1] https://stackoverflow.com/a/43441790/1054378
// -----------------------------------------------------------------------------
- (id) activityViewControllerPlaceholderItem:(UIActivityViewController*)activityViewController
{
  return @"SGF file";
}

// -----------------------------------------------------------------------------
/// @brief UIActivityItemSource method.
///
/// Returns the .sgf file in a format that is best suited to the activity.
///
/// Tested activity types:
/// - com.apple.UIKit.activity.Mail (UIActivityTypeMail) = Apple Mail
/// - com.apple.UIKit.activity.Message (UIActivityTypeMessage) = iMessage
/// - org.whispersystems.signal.shareextension = Signal
/// - com.skype.skype.sharingextension = Skype
/// - com.facebook.Messenger.ShareExtension = Facebook Messenger
/// - com.getdropbox.Dropbox.ActionExtension = The grey "Save to Dropbox"
///   action. This is a so-called "Action Extension".
/// - com.getdropbox.Dropbox.DropboxShareExtension = The colored "Dropbox"
///   activity.
/// - com.apple.CloudDocsUI.AddToiCloudDrive = The "Save to Files" activity.
///   This lets the user select any app that collaborates with the iCloud Drive
///   API.
/// - com.apple.UIKit.activity.AirDrop (UIActivityTypeAirDrop) = AirDrop
/// - com.apple.UIKit.activity.CopyToPasteboard (UIActivityTypeCopyToPasteboard)
///   = The grey "Copy" action
/// - com.apple.mobilenotes.SharingExtension = "Add to Notes" activity
/// - com.apple.UIKit.activity.PostToTwitter (UIActivityTypePostToTwitter)
///   = Twitter
/// - com.hammerandchisel.discord.Share = Discord
/// - com.fogcreek.trello.trelloshare = Trello
/// - org.mozilla.ios.Firefox.ShareTo = Firefox
///
/// Untested activity types known because they are in the default list:
/// - com.apple.UIKit.activity.Print (UIActivityTypePrint)
/// - com.apple.UIKit.activity.PostToWeibo (UIActivityTypePostToWeibo)
///   Weibo is any chinese micro-blogging service, similar to Twitter
/// - com.apple.UIKit.activity.TencentWeibo (UIActivityTypePostToTencentWeibo)
///
/// @note: If this becomes relevant in the future: The .sgf file can be shared
/// as NSData object with this code:
///
/// @verbatim
/// NSData* sgfFileData = [NSData dataWithContentsOfFile:sgfFilePath];
/// return sgfFileData;
/// @endverbatim
// -----------------------------------------------------------------------------
- (id) activityViewController:(UIActivityViewController*)activityViewController
          itemForActivityType:(UIActivityType)activityType;
{
  NSString* sgfFilePath = [self.model filePathForGameWithName:self.game.name];
  NSURL* sgfFileURL = [NSURL fileURLWithPath:sgfFilePath isDirectory:NO];

  if ([activityType isEqualToString:UIActivityTypeCopyToPasteboard] ||
      [activityType isEqualToString:UIActivityTypePostToTwitter])
  {
    NSStringEncoding usedEncoding;
    NSError* error;
    NSString* sgfFileContent = [NSString stringWithContentsOfURL:sgfFileURL
                                                    usedEncoding:&usedEncoding
                                                           error:&error];

    // UIActivityTypeCopyToPasteboard
    // >>> Copies the file content to the clipboard for later pasting in any
    //     place that can receive text
    // UIActivityTypePostToTwitter
    // >>> Pre-populates the Tweet with the file content
    return sgfFileContent;
  }
  else
  {
    // UIActivityTypeMail
    // >>> Creates a mail attachment with the on-disk file name.
    // UIActivityTypeMessage, Signal, Facebook Messenger, Skype
    // >>> Creates a message attachment with the on-disk file name.
    // com.getdropbox.Dropbox.ActionExtension
    // >>> Lets the user select a save location. The .sgf file is saved under
    //     the on-disk file name.
    // com.getdropbox.Dropbox.DropboxShareExtension
    // >>> Lets the user select a save location, write a message, and a list of
    //     recipients that will be able to access the file. The .sgf file is
    //     saved under the on-disk file name.
    // com.apple.CloudDocsUI.AddToiCloudDrive
    // >>> Lets the user select an app that collaborates with the iCloud Drive
    //     API. The .sgf file is then saved in the file area of that app under
    //     the on-disk file name.
    // UIActivityTypeAirDrop
    // >>> Sends the file to the "Download" folder on the target system
    // com.apple.mobilenotes.SharingExtension
    // >>> Creates an attachment to an existing or new note. The attachment has
    //     the on-disk file name.
    // com.hammerandchisel.discord.Share
    // >>> Lets the user select a channel or recipient and a write a message.
    //     The .sgf file is attached to the message.
    // com.fogcreek.trello.trelloshare
    // >>> Lets the user select a board and a list and write a message. A new
    //     item is added to the list and the sgf file is attached to the item
    //     under the on-disk file name.
    // org.mozilla.ios.Firefox.ShareTo
    // >>> Attempts to open a file:// URL that refers to a file in the private
    //     sandbox of this app. Of course this does not work, but it's too much
    //     trouble to try to disable Firefox - if we were to add Firefox to
    //     the UIActivityController's excludedActivityTypes, the activity type
    //     might change in the future, in addition there are probably many other
    //     activity types that don't work either, but we have no way to disable
    //     them.
    // UIActivityTypePrint
    // >>> Untested. Let's hope that the file can be printed.
    // UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo
    // >>> Untested. Let's hope that, unlike Twitter, the file can be attached
    //     to the message.
    return sgfFileURL;
  }
}

// -----------------------------------------------------------------------------
/// @brief UIActivityItemSource method.
///
/// The string returned here is used for activities that have support for a
/// "subject". The typical example is UIActivityTypeMail.
// -----------------------------------------------------------------------------
- (NSString*) activityViewController:(UIActivityViewController*)activityViewController
              subjectForActivityType:(UIActivityType)activityType
{
  return self.game.name;
}

// -----------------------------------------------------------------------------
/// @brief UIActivityItemSource method.
///
/// This is invoked several times with @a activityType set to nil while the
/// sharing sheet is not yet shown to the user. This is called one more time
/// if the user has selected an activity for which
/// activityViewController:itemForActivityType:() has returned an NSData object.
// -----------------------------------------------------------------------------
- (NSString*) activityViewController:(UIActivityViewController*)activityViewController
   dataTypeIdentifierForActivityType:(UIActivityType)activityType
{
  // This method is already invoked several times before the sharing sheet is
  // even shown to the user. We can detect this "setup" phase because the
  // activityType parameter is nil - obviously because the user has not yet
  // selected an activity. It is very important that during the "setup" phase
  // this method returns nil. If this method returns the real UTI, the resulting
  // sharing sheet may not display some sharing options. Notably, the Dropbox
  // activity will be missing.
  if (activityType)
    return sgfUTI;
  else
    return nil;
}

@end
