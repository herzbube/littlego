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
#import "EditPlayerController.h"
#import "../ApplicationDelegate.h"
#import "../player/PlayerModel.h"
#import "../player/Player.h"
#import "../player/GtpEngineProfile.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Player" table view.
// -----------------------------------------------------------------------------
enum EditPlayerTableViewSection
{
  PlayerNameSection,
  IsHumanSection,
  GtpEngineProfileSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayerNameSection.
// -----------------------------------------------------------------------------
enum PlayerNameSectionItem
{
  PlayerNameItem,
  MaxPlayerNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the IsHumanSection.
// -----------------------------------------------------------------------------
enum IsHumanSectionItem
{
  IsHumanItem,
  MaxIsHumanSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GtpEngineProfileSection.
// -----------------------------------------------------------------------------
enum GtpEngineProfileSectionItem
{
  GtpEngineProfileItem,
  MaxGtpEngineProfileSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for EditPlayerController.
// -----------------------------------------------------------------------------
@interface EditPlayerController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Action methods
//@{
- (void) delete:(id)sender;
- (void) toggleIsHuman:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name GtpEngineProfileSelectionDelegate protocol
//@{
- (void) gtpEngineProfileSelectionController:(GtpEngineProfileSelectionController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name Helpers
//@{
- (bool) isPlayerValid;
//@}
@end


@implementation EditPlayerController

@synthesize delegate;
@synthesize player;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditPlayerController instance of
/// grouped style that is used to edit @a player.
// -----------------------------------------------------------------------------
+ (EditPlayerController*) controllerForPlayer:(Player*)player withDelegate:(id<EditPlayerDelegate>)delegate
{
  EditPlayerController* controller = [[EditPlayerController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = player;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditPlayerController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.player = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  assert(self.delegate != nil);

  self.navigationItem.title = @"Edit Player";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Delete"
                                                                            style:UIBarButtonItemStyleDone
                                                                           target:self
                                                                           action:@selector(delete:)];
  self.navigationItem.leftBarButtonItem.enabled = [self isPlayerValid];
  // Player can be deleted only if he is not currently playing a game
  self.navigationItem.rightBarButtonItem.enabled = (! self.player.isPlaying);
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  // Because we always display all sections we can reload sections, especially
  // GtpEngineProfileSection when we toggle between human/not human. Because
  // GtpEngineProfileSection will sometimes have zero rows, we get a nice
  // animation of rows fading in/out.
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case PlayerNameSection:
      return MaxPlayerNameSectionItem;
    case IsHumanSection:
      return MaxIsHumanSectionItem;
    case GtpEngineProfileSection:
      if (self.player.isHuman)
        return 0;  // GTP engine profile is only for computer players
      else
        return MaxGtpEngineProfileSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case PlayerNameSection:
    case IsHumanSection:
      return nil;
    case GtpEngineProfileSection:
      if (self.player.isHuman)
        return nil;
      else
        return @"GTP engine profile";
    default:
      assert(0);
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell;
  switch (indexPath.section)
  {
    case PlayerNameSection:
    {
      switch (indexPath.row)
      {
        case PlayerNameItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.delegate = self;
          textField.text = self.player.name;
          textField.placeholder = @"Player name";
          // Place the insertion point into this field; might be better to
          // do this in viewWillAppear:
          [textField becomeFirstResponder];
          break;
        }
        default:
          assert(0);
          break;
      }
      break;
    }
    case IsHumanSection:
    {
      switch (indexPath.row)
      {
        case IsHumanItem:
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          cell.textLabel.text = @"Human player";
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          [accessoryView addTarget:self action:@selector(toggleIsHuman:) forControlEvents:UIControlEventValueChanged];
          accessoryView.on = self.player.human;
          // Player type can be changed only if he is not currently playing a game
          accessoryView.enabled = (! self.player.isPlaying);
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case GtpEngineProfileSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.textLabel.text = [self.player gtpEngineProfile].name;
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    default:
    {
      assert(0);
      break;
    }
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
    case GtpEngineProfileSection:
    {
      UIViewController* modalController = [[GtpEngineProfileSelectionController controllerWithDelegate:self
                                                                                        defaultProfile:[self.player gtpEngineProfile]] retain];
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:modalController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentModalViewController:navigationController animated:YES];
      [navigationController release];
      [modalController release];
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  self.player.name = [textField.text stringByReplacingCharactersInRange:range withString:string];
  // Make sure that the editing view cannot be left, unless the player name is
  // valid
  [self.navigationItem setHidesBackButton:! [self isPlayerValid] animated:YES];
  // Notify delegate that something about the player object has changed
  [self.delegate didChangePlayer:self];
  // Accept all changes, even those that make the player name invalid
  // -> the user must simply continue editing until the player name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to delete the player object.
// -----------------------------------------------------------------------------
- (void) delete:(id)sender
{
  PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
  assert(model);
  [model remove:self.player];

  [self.delegate didDeletePlayer:self];
  [self.navigationController popViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Is Human" switch. Updates the Player
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleIsHuman:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.player.human = accessoryView.on;

  [self.delegate didChangePlayer:self];

  // Reloading the section works because it is always there - it just sometimes
  // has zero rows.
  NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex:GtpEngineProfileSection];
  [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current Player object contains valid data so that
/// editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isPlayerValid
{
  return (self.player.name.length > 0);
}

// -----------------------------------------------------------------------------
/// @brief GtpEngineProfileSelectionDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) gtpEngineProfileSelectionController:(GtpEngineProfileSelectionController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    NSString* previousProfileUUID = self.player.gtpEngineProfileUUID;
    if (! [previousProfileUUID isEqualToString:controller.profile.uuid])
    {
      self.player.gtpEngineProfileUUID = controller.profile.uuid;

      NSUInteger sectionIndex = GtpEngineProfileSection;
      NSUInteger rowIndex = GtpEngineProfileItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}


@end
