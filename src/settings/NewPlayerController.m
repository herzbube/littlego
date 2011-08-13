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
#import "NewPlayerController.h"
#import "PlayerModel.h"
#import "../utility/TableViewCellFactory.h"
#import "../ApplicationDelegate.h"
#import "../player/Player.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Player" table view.
// -----------------------------------------------------------------------------
enum NewPlayerTableViewSection
{
  PlayerNameSection,
  IsHumanSection,
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
/// @brief Class extension with private methods for NewPlayerController.
// -----------------------------------------------------------------------------
@interface NewPlayerController()
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
- (void) create:(id)sender;
- (void) toggleIsHuman:(id)sender;
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
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name Helpers
//@{
- (bool) isPlayerValid;
//@}
@end


@implementation NewPlayerController

@synthesize delegate;
@synthesize player;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NewPlayerController instance of
/// grouped style.
// -----------------------------------------------------------------------------
+ (NewPlayerController*) controllerWithDelegate:(id<NewPlayerDelegate>)delegate
{
  NewPlayerController* controller = [[NewPlayerController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.player = [[[Player alloc] init] autorelease];
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewPlayerController object.
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

  // Configure the navigation item representing this controller. This item will
  // be displayed by the navigation controller that wraps this controller in
  // its navigation bar.
  self.navigationItem.title = @"New Player";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                            style:UIBarButtonItemStyleDone
                                                                           target:self
                                                                           action:@selector(create:)];
  self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
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
/// @brief Invoked when the user wants to create a new player object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
  assert(model);
  [model add:self.player];

  [self.delegate didCreateNewPlayer:self];
  [self.navigationController popViewControllerAnimated:YES];
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
    case PlayerNameSection:
      return MaxPlayerNameSectionItem;
    case IsHumanSection:
      return MaxIsHumanSectionItem;
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
  UITableViewCell* cell;
  switch (indexPath.section)
  {
    case PlayerNameSection:
      switch (indexPath.row)
      {
        case PlayerNameItem:
          {
            enum TableViewCellType cellType = TextFieldCellType;
            cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
            UITextField* textField = (UITextField*)[cell viewWithTag:cellType];
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
    case IsHumanSection:
      switch (indexPath.row)
      {
        case IsHumanItem:
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          cell.textLabel.text = @"Human player";
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          [accessoryView addTarget:self action:@selector(toggleIsHuman:) forControlEvents:UIControlEventValueChanged];
          accessoryView.on = self.player.human;
          break;
        default:
          assert(0);
          break;
      }
      break;
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
  // Make sure that the new player cannot be added, unless its name is valid
  self.navigationItem.rightBarButtonItem.enabled = [self isPlayerValid];
  // Accept all changes, even those that make the player name invalid
  // -> the user must simply continue editing until the player name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Is Human" switch. Updates the Player
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleIsHuman:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.player.human = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current Player object contains valid data so that
/// the object can safely be added to the Player model.
// -----------------------------------------------------------------------------
- (bool) isPlayerValid
{
  return (self.player.name.length > 0);
}

@end
