// -----------------------------------------------------------------------------
// Copyright 2011-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoItem.h"
#import "GameInfoItemController.h"
#import "ViewLoadResultController.h"
#import "../command/game/RenameGameCommand.h"
#import "../command/game/LoadGameCommand.h"
#import "../command/sgf/LoadSgfCommand.h"
#import "../go/GoGame.h"
#import "../main/ApplicationDelegate.h"
#import "../main/MainUtility.h"
#import "../shared/LayoutManager.h"
#import "../sgf/SgfSettingsModel.h"
#import "../sgf/SgfUtilities.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"
#import "../utility/UIDeviceAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Game" table view.
// -----------------------------------------------------------------------------
enum EditGameTableViewSection
{
  ArchiveSection,
  LoadResultSection,
  GamesSection,
  ForceLoadingSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ArchiveSection.
// -----------------------------------------------------------------------------
enum ArchiveSectionItem
{
  NameItem,
  LastSavedDateItem,
  MaxArchiveSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LoadResultSection.
// -----------------------------------------------------------------------------
enum LoadResultSectionItem
{
  LoadResultItem1,
  LoadResultItem2,
  MaxLoadResultSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GamesSection.
// -----------------------------------------------------------------------------
enum GamesSectionItem
{
  PlaceholderGameItem,
  MaxGamesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ForceLoadingSection.
// -----------------------------------------------------------------------------
enum ForceLoadingSectionItem
{
  ForceLoadingItem,
  MaxForceLoadingSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items displayed in a section for an individual game
// -----------------------------------------------------------------------------
enum IndividualGameSectionItem
{
  ShowDetailsItem,
  LoadGameItem,
  MaxIndividualGameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the possible types of results that loading SGF data can
/// have.
// -----------------------------------------------------------------------------
enum LoadResultType
{
  /// @brief The SGF data was loaded successfully, after evaluating SgfcKit's
  /// read result(s) and taking the "load success type" user preference into
  /// account.
  LoadResultTypeSuccessful,
  /// @brief The SGF data failed to load, after evaluating SgfcKit's
  /// read result(s), taking the "load success type" user preference into
  /// account. The reason for the failure is not a fatal error.
  LoadResultTypeFailedWithNonFatalError,
  /// @brief The SGF data failed to load. The reason for the failure is a fatal
  /// error.
  LoadResultTypeFailedWithFatalError
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ViewGameController.
// -----------------------------------------------------------------------------
@interface ViewGameController()
@property(nonatomic, retain) UIBarButtonItem* actionButton;
@property(nonatomic, retain) SgfSettingsModel* sgfSettingsModel;
@property(nonatomic, assign) int numberOfLoadResults;
@property(nonatomic, retain) SGFCDocumentReadResult* sgfDocumentReadResultSingleEncoding;
@property(nonatomic, retain) SGFCDocumentReadResult* sgfDocumentReadResultMultipleEncodings;
@property(nonatomic, assign) enum LoadResultType loadResultType;
@property(nonatomic, assign) NSUInteger numberOfGameInfoItems;
@property(nonatomic, retain) NSArray* gameInfoItems;
@property(nonatomic, retain) NSArray* gameInfoNodes;
@property(nonatomic, assign) bool loadGameEnabled;
@property(nonatomic, retain) GameInfoItem* gameInfoItemBeingLoaded;
@property(nonatomic, retain) SGFCNode* gameInfoNodeBeingLoaded;
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
    controller.sgfSettingsModel = [ApplicationDelegate sharedDelegate].sgfSettingsModel;
    controller.sgfDocumentReadResultSingleEncoding = nil;
    controller.sgfDocumentReadResultMultipleEncodings = nil;
    controller.loadResultType = LoadResultTypeFailedWithFatalError;
    controller.numberOfGameInfoItems = 0;
    controller.gameInfoItems = nil;
    controller.gameInfoNodes = nil;
    controller.loadGameEnabled = true;
    controller.gameInfoItemBeingLoaded = nil;
    controller.gameInfoNodeBeingLoaded = nil;
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
  self.sgfSettingsModel = nil;
  self.sgfDocumentReadResultSingleEncoding = nil;
  self.sgfDocumentReadResultMultipleEncodings = nil;
  self.gameInfoItems = nil;
  self.gameInfoNodes = nil;
  self.gameInfoItemBeingLoaded = nil;
  self.gameInfoNodeBeingLoaded = nil;
  self.actionButton = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  self.navigationItem.title = @"View archive content";
  self.actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                     target:self
                                                                     action:@selector(action:)] autorelease];
  self.actionButton.style = UIBarButtonItemStylePlain;
  self.navigationItem.rightBarButtonItems = [NSArray arrayWithObject:self.actionButton];
  [self updateLoadGameEnabled];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  // KVO observing
  [self.game addObserver:self forKeyPath:@"fileDate" options:0 context:NULL];

  [self loadSgf];
  if (self.loadResultType == LoadResultTypeSuccessful)
    [self parseSgf];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  switch (self.loadResultType)
  {
    case LoadResultTypeFailedWithNonFatalError:
    {
      // ForceLoadingSection is displayed
      // GamesSection displays a placeholder
      return MaxSection;
    }
    case LoadResultTypeFailedWithFatalError:
    {
      // ForceLoadingSection is not displayed
      // GamesSection displays a placeholder
      return (MaxSection - 1);
    }
    case LoadResultTypeSuccessful:
    {
      if (self.numberOfGameInfoItems == 0)
      {
        // ForceLoadingSection is not displayed
        // GamesSection displays a placeholder
        return (MaxSection - 1);
      }
      else
      {
        // ForceLoadingSection is not displayed
        // GamesSection is not displayed
        // Instead one section per GameInfoItem is displayed
        return (MaxSection - 2 + self.numberOfGameInfoItems);
      }
    }
    default:
    {
      assert(0);
      return 0;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case ArchiveSection:
    {
      return MaxArchiveSectionItem;
    }
    case LoadResultSection:
    {
      return self.numberOfLoadResults;
    }
    default:
    {
      if (self.numberOfGameInfoItems > 0)
      {
        GameInfoItem* gameInfoItem = [self.gameInfoItems objectAtIndex:section - GamesSection];
        NSInteger numberOfSummaryRows = [gameInfoItem tableView:tableView numberOfRowsInSection:0 detailLevel:GameInfoItemDetailLevelSummary];
        if (gameInfoItem.goGameInfo)
          return numberOfSummaryRows + MaxIndividualGameSectionItem;
        else
          return numberOfSummaryRows;  // don't show additional rows if the GameInfoItem is just a placeholder
      }
      else
      {
        if (section == GamesSection)
          return MaxGamesSectionItem;
        else if (section == ForceLoadingSection)
          return MaxForceLoadingSectionItem;
        else
          break;
      }
    }
  }
  assert(0);
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case ArchiveSection:
    {
      return @"Archive info";
    }
    case LoadResultSection:
    {
      return @"Load result";
    }
    default:
    {
      if (self.numberOfGameInfoItems > 0)
      {
        GameInfoItem* gameInfoItem = [self.gameInfoItems objectAtIndex:section - GamesSection];
        return [gameInfoItem tableView:tableView titleForHeaderInSection:0 detailLevel:GameInfoItemDetailLevelSummary];
      }
      else
      {
        if (section == GamesSection)
          return @"Games";
        else if (section == ForceLoadingSection)
          return @"Force loading";
        else
          break;
      }
    }
  }
  assert(0);
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case LoadResultSection:
    {
      if (self.numberOfLoadResults > 1)
        return @"Loading the SGF data with encoding mode \"Single encoding\" failed. A second attempt was made to load the data with encoding mode \"Multiple encodings\". This is why you see two load results instead of only one.";
      break;
    }
    default:
    {
      if (self.numberOfGameInfoItems == 0 && section == ForceLoadingSection)
        return @"Loading the SGF data failed with non-fatal warnings or errors. Tapping the \"Force loading\" button loads the data again but this time ignores the warnings/errors. If this happens frequently you may wish to change your preferences to use syntax checking that is less strict.";
      break;
    }
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case ArchiveSection:
    {
      switch (indexPath.row)
      {
        case NameItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Name";
          cell.detailTextLabel.text = self.game.name;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case LastSavedDateItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.selectionStyle = UITableViewCellSelectionStyleNone;
          cell.textLabel.text = @"Last saved";
          cell.detailTextLabel.text = self.game.fileDate;
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case LoadResultSection:
    {
      switch (indexPath.row)
      {
        case LoadResultItem1:
        case LoadResultItem2:
        {
          cell = [TableViewCellFactory cellWithType:SubtitleCellType tableView:tableView];
          cell.accessoryType = [self accessoryTypeForLoadResultTableViewRow:indexPath.row];
          if (cell.accessoryType == UITableViewCellAccessoryNone)
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
          else
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
          cell.textLabel.text = [self textForLoadResultTableViewRow:indexPath.row];
          cell.detailTextLabel.text = [self subTitleForLoadResultTableViewRow:indexPath.row];
          cell.imageView.image = [self coloredIndicatorForLoadResultTableViewRow:indexPath.row];
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    default:
    {
      if (self.numberOfGameInfoItems > 0)
      {
        GameInfoItem* gameInfoItem = [self.gameInfoItems objectAtIndex:indexPath.section - GamesSection];
        NSInteger numberOfSummaryRows = [gameInfoItem tableView:tableView numberOfRowsInSection:0 detailLevel:GameInfoItemDetailLevelSummary];
        if (indexPath.row < numberOfSummaryRows)
        {
          cell = [gameInfoItem tableView:tableView cellForRowAtIndexPath:indexPath detailLevel:GameInfoItemDetailLevelSummary];
        }
        else
        {
          switch (indexPath.row - numberOfSummaryRows)
          {
            case ShowDetailsItem:
            {
              cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
              cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
              cell.textLabel.text = @"Show details";
              break;
            }
            case LoadGameItem:
            {
              cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
              cell.textLabel.text = @"Load game";
              break;
            }
            default:
            {
              assert(0);
              break;
            }
          }
        }
      }
      else
      {
        if (indexPath.section == GamesSection)
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.selectionStyle = UITableViewCellSelectionStyleNone;
          cell.textLabel.text = @"No games available.";
        }
        else if (indexPath.section == ForceLoadingSection)
        {
          cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
          cell.textLabel.text = @"Force loading";
        }
        else
        {
          assert(0);
        }
      }
      break;
    }
  }

  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  switch (indexPath.section)
  {
    case ArchiveSection:
    {
      switch (indexPath.row)
      {
        case NameItem:
          [self editGame];
          break;
        default:
          break;
      }
      break;
    }
    case LoadResultSection:
    {
      SGFCDocumentReadResult* loadResult = [self loadResultForTableViewRow:indexPath.row];
      if (loadResult.parseResult.count > 0)
      {
        ViewLoadResultController* viewLoadResultController = [ViewLoadResultController controllerWithLoadResult:loadResult];
        [self.navigationController pushViewController:viewLoadResultController animated:YES];
      }
      break;
    }
    default:
    {
      if (self.numberOfGameInfoItems > 0)
      {
        GameInfoItem* gameInfoItem = [self.gameInfoItems objectAtIndex:indexPath.section - GamesSection];
        NSInteger numberOfSummaryRows = [gameInfoItem tableView:tableView numberOfRowsInSection:0 detailLevel:GameInfoItemDetailLevelSummary];
        switch (indexPath.row - numberOfSummaryRows)
        {
          case ShowDetailsItem:
          {
            GameInfoItemController* gameInfoItemController = [GameInfoItemController controllerWithGameInfoItem:gameInfoItem];
            [self.navigationController pushViewController:gameInfoItemController animated:YES];
            break;
          }
          case LoadGameItem:
          {
            if (self.loadGameEnabled)
            {
              GameInfoItem* gameInfoItem = [self.gameInfoItems objectAtIndex:indexPath.section - GamesSection];
              SGFCNode* gameInfoNode = [self.gameInfoNodes objectAtIndex:indexPath.section - GamesSection];
              [self loadGame:gameInfoItem gameInfoNode:gameInfoNode];
            }
            break;
          }
          default:
          {
            break;
          }
        }
      }
      else
      {
        if (indexPath.section == ForceLoadingSection)
        {
          self.loadResultType = LoadResultTypeSuccessful;
          [self parseSgf];
          [self.tableView reloadData];
        }
      }
      break;
    }
  }
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateLoadGameEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateLoadGameEnabled];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  [self.tableView reloadData];
}

#pragma mark - Edit game name - Action handlers

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

#pragma mark - Edit game name - EditTextDelegate overrides

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

#pragma mark - Load game - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays NewGameController to allow the user to start a new game and
/// load the game's initial state from @a gameInfoNode.
// -----------------------------------------------------------------------------
- (void) loadGame:(GameInfoItem*)gameInfoItem gameInfoNode:(SGFCNode*)gameInfoNode
{
  self.gameInfoItemBeingLoaded = gameInfoItem;
  self.gameInfoNodeBeingLoaded = gameInfoNode;
  NewGameController* newGameController = [[NewGameController controllerWithDelegate:self loadGame:true] retain];
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:newGameController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  navigationController.delegate = [LayoutManager sharedManager];
  [self presentViewController:navigationController animated:YES completion:nil];
  [navigationController release];
  [newGameController release];
}

#pragma mark - Load game - NewGameControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief NewGameControllerDelegate protocol method
// -----------------------------------------------------------------------------
- (void) newGameController:(NewGameController*)controller didStartNewGame:(bool)didStartNewGame
{
  if (didStartNewGame)
  {
    LoadGameCommand* command = [[[LoadGameCommand alloc] initWithGameInfoNode:self.gameInfoNodeBeingLoaded goGameInfo:self.gameInfoItemBeingLoaded.goGameInfo] autorelease];
    [command submit];
  }
  self.gameInfoItemBeingLoaded = nil;
  self.gameInfoNodeBeingLoaded = nil;

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

#pragma mark - Load game - Button state handling

// -----------------------------------------------------------------------------
/// @brief Updates the enabled state of the "load game" function.
///
/// The function is disabled if a computer player is currently thinking, or if a
/// computer vs. computer game is not paused. With this measure we avoid the
/// complicated multi-thread handling of the situation where we need to wait for
/// the computer player to finish thinking before we can discard the current
/// game in favour of the game to be loaded.
// -----------------------------------------------------------------------------
- (void) updateLoadGameEnabled
{
  bool loadGameEnabled = false;

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
            loadGameEnabled = true;
          break;
        default:
          break;
      }
      break;
    }
    default:
    {
      if (! goGame.isComputerThinking)
        loadGameEnabled = true;
      break;
    }
  }
  self.loadGameEnabled = loadGameEnabled;
}

#pragma mark - Action button - Action handlers

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

#pragma mark - Action button - UIActivityItemSource overrides

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
  // this method returns an empty string. If this method returns the real UTI,
  // the resulting sharing sheet may not display some sharing options. Notably,
  // all Dropbox activities will be missing.
  if (activityType)
    return sgfUTI;
  else
    return @"";
}

#pragma mark - Private helpers - Load result handling

// -----------------------------------------------------------------------------
/// @brief Evaluates SgfcKit's read results and returns an LoadResultType value
/// after taking the "load success type" user preference and the
/// "force loading enabled" property into account.
// -----------------------------------------------------------------------------
- (enum LoadResultType) loadResultTypeBasedOnLoadResult:(SGFCDocumentReadResult*)loadResult
{
  int numberOfNonCriticalWarnings = 0;
  int numberOfNonCriticalErrors = 0;
  int numberCriticalMessages = 0;
  int numberOfFatalErrors = 0;
  NSArray* parseResult = loadResult.parseResult;
  for (SGFCMessage* message in parseResult)
  {
    if (message.isCriticalMessage)
      numberCriticalMessages++;
    else if (message.messageType == SGFCMessageTypeWarning)
      numberOfNonCriticalWarnings++;
    else if (message.messageType == SGFCMessageTypeError)
      numberOfNonCriticalErrors++;
    else
      numberOfFatalErrors++;
  }

  if (numberOfFatalErrors > 0 || ! loadResult.isSgfDataValid)
    return LoadResultTypeFailedWithFatalError;

  switch (self.sgfSettingsModel.loadSuccessType)
  {
    case SgfLoadSuccessTypeNoWarningsOrErrors:
    {
      if (parseResult.count == 0)
        return LoadResultTypeSuccessful;
      else
        return LoadResultTypeFailedWithNonFatalError;
    }
    case SgfLoadSuccessTypeNoCriticalWarningsOrErrors:
    {
      if (numberCriticalMessages == 0)
        return LoadResultTypeSuccessful;
      else
        return LoadResultTypeFailedWithNonFatalError;
    }
    case SgfLoadSuccessTypeWithCriticalWarningsOrErrors:
    {
      return LoadResultTypeSuccessful;
    }
    default:
    {
      assert(0);
      return LoadResultTypeFailedWithFatalError;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a UITableViewCellAccessoryType value for the table view
/// cell that is displayed in row @a row of section #LoadResultSection.
// -----------------------------------------------------------------------------
- (UITableViewCellAccessoryType) accessoryTypeForLoadResultTableViewRow:(NSInteger)row
{
  SGFCDocumentReadResult* loadResult = [self loadResultForTableViewRow:row];
  if (loadResult.parseResult.count > 0)
    return UITableViewCellAccessoryDisclosureIndicator;
  else
    return UITableViewCellAccessoryNone;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that can be used as the main text of the table view
/// cell that is displayed in row @a row of section #LoadResultSection.
// -----------------------------------------------------------------------------
- (NSString*) textForLoadResultTableViewRow:(NSInteger)row
{
  SGFCDocumentReadResult* loadResult = [self loadResultForTableViewRow:row];

  int numberOfNonCriticalWarnings = 0;
  int numberOfNonCriticalErrors = 0;
  int numberCriticalMessages = 0;
  int numberOfFatalErrors = 0;
  for (SGFCMessage* message in loadResult.parseResult)
  {
    if (message.isCriticalMessage)
      numberCriticalMessages++;
    else if (message.messageType == SGFCMessageTypeWarning)
      numberOfNonCriticalWarnings++;
    else if (message.messageType == SGFCMessageTypeError)
      numberOfNonCriticalErrors++;
    else
      numberOfFatalErrors++;
  }

  if (numberOfFatalErrors > 0)
  {
    NSString* fatalErrorText;
    if (numberOfFatalErrors == 1)
      fatalErrorText = [NSString stringWithFormat:@"%d fatal error", numberOfFatalErrors];
    else
      fatalErrorText = [NSString stringWithFormat:@"%d fatal errors", numberOfFatalErrors];

    return fatalErrorText;
  }
  else if (numberCriticalMessages > 0)
  {
    NSString* criticalMessageText;
    if (numberCriticalMessages == 1)
      criticalMessageText = [NSString stringWithFormat:@"%d critical warning or error", numberCriticalMessages];
    else
      criticalMessageText = [NSString stringWithFormat:@"%d critical warnings or errors", numberCriticalMessages];

    return criticalMessageText;
  }
  else
  {
    NSString* nonCriticalWarningText;
    if (numberOfNonCriticalWarnings == 1)
      nonCriticalWarningText = [NSString stringWithFormat:@"%d warning", numberOfNonCriticalWarnings];
    else
      nonCriticalWarningText = [NSString stringWithFormat:@"%d warnings", numberOfNonCriticalWarnings];

    NSString* nonCriticalErrorText;
    if (numberOfNonCriticalErrors == 1)
      nonCriticalErrorText = [NSString stringWithFormat:@"%d error", numberOfNonCriticalErrors];
    else
      nonCriticalErrorText = [NSString stringWithFormat:@"%d errors", numberOfNonCriticalErrors];

    return [NSString stringWithFormat:@"%@, %@", nonCriticalWarningText, nonCriticalErrorText];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that can be used as the subtitle of the table view
/// cell that is displayed in row @a row of section #LoadResultSection.
// -----------------------------------------------------------------------------
- (NSString*) subTitleForLoadResultTableViewRow:(NSInteger)row
{
  enum SgfEncodingMode encodingMode = [self encodingModeUsedForLoadResultTableViewRow:row];
  if (encodingMode == SgfEncodingModeSingleEncoding)
    return @"(with encoding mode \"Single encoding\")";
  else
    return @"(with encoding mode \"Multiple encodings\")";
}

// -----------------------------------------------------------------------------
/// @brief Returns a colored indicator that can be used as the image of the
/// table view cell that is displayed in row @a row of section
/// #LoadResultSection.
// -----------------------------------------------------------------------------
- (UIImage*) coloredIndicatorForLoadResultTableViewRow:(NSInteger)row
{
  SGFCDocumentReadResult* loadResult = [self loadResultForTableViewRow:row];
  return [SgfUtilities coloredIndicatorForLoadResult:loadResult];
}

// -----------------------------------------------------------------------------
/// @brief Returns the SGFCDocumentReadResult object that holds the load result
/// that is displayed in row @a row of section #LoadResultSection.
// -----------------------------------------------------------------------------
- (SGFCDocumentReadResult*) loadResultForTableViewRow:(NSInteger)row
{
  enum SgfEncodingMode encodingMode = [self encodingModeUsedForLoadResultTableViewRow:row];
  if (encodingMode == SgfEncodingModeSingleEncoding)
    return self.sgfDocumentReadResultSingleEncoding;
  else
    return self.sgfDocumentReadResultMultipleEncodings;
}

// -----------------------------------------------------------------------------
/// @brief Returns the SGFCDocumentReadResult object that holds the effective
/// load result that is used to populate the table view's #GamesSection.
// -----------------------------------------------------------------------------
- (SGFCDocumentReadResult*) effectiveLoadResult
{
  switch (self.sgfSettingsModel.encodingMode)
  {
    case SgfEncodingModeSingleEncoding:
      return self.sgfDocumentReadResultSingleEncoding;
    case SgfEncodingModeMultipleEncodings:
      return self.sgfDocumentReadResultMultipleEncodings;
    case SgfcEncodingModeBoth:
      if (self.sgfDocumentReadResultMultipleEncodings)
        return self.sgfDocumentReadResultMultipleEncodings;
      else
        return self.sgfDocumentReadResultSingleEncoding;
    default:
      assert(0);
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns the encoding mode that was used to produce the load result
/// that is displayed in row @a row of section #LoadResultSection.
// -----------------------------------------------------------------------------
- (enum SgfEncodingMode) encodingModeUsedForLoadResultTableViewRow:(NSInteger)row
{
  if (row == LoadResultItem1)
  {
    if (self.sgfSettingsModel.encodingMode == SgfcEncodingModeBoth)
      return SgfEncodingModeSingleEncoding;
    else
      return self.sgfSettingsModel.encodingMode;
  }
  else if (row == LoadResultItem2)
  {
    return SgfEncodingModeMultipleEncodings;
  }
  else
  {
    assert(0);
    return SgfEncodingModeSingleEncoding;
  }
}

#pragma mark - Private helpers - SGF loading and parsing

// -----------------------------------------------------------------------------
/// @brief Loads the SGF file with which the controller was initialized,
/// taking SGF user preferences into account. Updates load result related
/// controller properties.
///
/// This needs to be invoked once when the controller initializes.
///
/// If after invoking this method the load  result is #LoadResultTypeSuccessful
/// then the SGF data must be parsed in a second step to complete the data the
/// controller expects for presentation. If the load result is not
/// #LoadResultTypeSuccessful then the data is complete and nothing else needs
/// to be done.
// -----------------------------------------------------------------------------
- (void) loadSgf
{
  NSString* sgfFilePath = [self.model filePathForGameWithName:self.game.name];
  LoadSgfCommand* loadSgfCommand = [[[LoadSgfCommand alloc] initWithSgfFilePath:sgfFilePath] autorelease];
  bool success = [loadSgfCommand submit];
  if (success)
  {
    self.sgfDocumentReadResultSingleEncoding = loadSgfCommand.sgfDocumentReadResultSingleEncoding;
    self.sgfDocumentReadResultMultipleEncodings = loadSgfCommand.sgfDocumentReadResultMultipleEncodings;
    if (self.sgfDocumentReadResultSingleEncoding && self.sgfDocumentReadResultMultipleEncodings)
      self.numberOfLoadResults = 2;
    else
      self.numberOfLoadResults = 1;
    SGFCDocumentReadResult* effectiveLoadResult = [self effectiveLoadResult];
    self.loadResultType = [self loadResultTypeBasedOnLoadResult:effectiveLoadResult];
  }
}

// -----------------------------------------------------------------------------
/// @brief Parses the SGF data returned by effectiveLoadResult(). Updates
/// game related controller properties.
///
/// This needs to be invoked once, either when the controller initializes when
/// loadSgf() has determined the load result to be #LoadResultTypeSuccessful,
/// or at a later time when the user has decided to force loading despite
/// the load result being #LoadResultTypeFailedWithNonFatalError.
// -----------------------------------------------------------------------------
- (void) parseSgf
{
  SGFCDocumentReadResult* effectiveReadResult = [self effectiveLoadResult];
  SGFCDocument* document = effectiveReadResult.document;

  NSMutableArray* gameInfoItems = [NSMutableArray array];
  NSMutableArray* gameInfoNodes = [NSMutableArray array];

  for (SGFCGame* game in document.games)
  {
    if (! game.hasRootNode)
      continue;

    for (SGFCNode* gameInfoNode in game.gameInfoNodes)
    {
      SGFCGameInfo* gameInfo = gameInfoNode.gameInfo;

      NSUInteger gameNumber = gameInfoItems.count + 1;
      NSString* titleText = [NSString stringWithFormat:@"Game %ld", (long)gameNumber];

      GameInfoItem* gameInfoItem;
      if (gameInfo.gameType == SGFCGameTypeGo)
      {
        SGFCBoardSize boardSize = gameInfo.boardSize;
        if (SGFCBoardSizeIsSquare(boardSize))
        {
          switch (boardSize.Columns)
          {
            case 7:
            case 9:
            case 11:
            case 13:
            case 15:
            case 17:
            case 19:
            {
              gameInfoItem = [GameInfoItem gameInfoItemWithGoGameInfo:gameInfo.toGoGameInfo titleText:titleText];
              break;
            }
            default:
            {
              NSString* descriptiveText = [NSString stringWithFormat:@"The board size is not supported: %@.", [SgfUtilities stringForSgfBoardSize:boardSize]];
              gameInfoItem = [GameInfoItem gameInfoItemWithDescriptiveText:descriptiveText titleText:titleText];
              break;
            }
          }
        }
        else
        {
          NSString* descriptiveText = [NSString stringWithFormat:@"The board size is not square: %@.", [SgfUtilities stringForSgfBoardSize:boardSize]];
          gameInfoItem = [GameInfoItem gameInfoItemWithDescriptiveText:descriptiveText titleText:titleText];
        }
      }
      else
      {
        // TODO xxx not enough space. Either shorten the text or use a
        // multi-line table view cell
        NSString* descriptiveText = [NSString stringWithFormat:@"The game is not a Go game. The SGF game number is %ld.", gameInfo.gameTypeAsNumber];
        gameInfoItem = [GameInfoItem gameInfoItemWithDescriptiveText:descriptiveText titleText:titleText];
      }

      [gameInfoItems addObject:gameInfoItem];
      [gameInfoNodes addObject:gameInfoNode];
    }

    // TODO xxx if no gameinfoitem then create a placeholder
  }

  self.numberOfGameInfoItems = gameInfoItems.count;
  self.gameInfoItems = gameInfoItems;
  self.gameInfoNodes = gameInfoNodes;
}

@end
