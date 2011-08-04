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
#import "SettingsViewController.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates types of table view cells used in the "Settings" table
/// view.
// -----------------------------------------------------------------------------
enum TableViewCellType
{
  DefaultCellType,
  Value1CellType,
  SwitchCellType
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  FeedbackSection,
  ViewSection,
  PlayersSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the FeedbackSection.
// -----------------------------------------------------------------------------
enum FeedbackSectionItem
{
  PlaySoundItem,
  VibrateItem,
  MaxFeedbackSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ViewSection.
// -----------------------------------------------------------------------------
enum ViewSectionItem
{
  MarkLastMoveItem,
  DisplayCoordinatesItem,
  DisplayMoveNumbersItem,
  CrossHairPointDistanceFromFingerItem,
  MaxViewSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersSection.
// -----------------------------------------------------------------------------
enum PlayersSectionItem
{
  AddPlayerItem,
  MaxPlayersSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for SettingsViewController.
// -----------------------------------------------------------------------------
@interface SettingsViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
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
/// @name Helpers
//@{
- (UITableViewCell*) tableView:(UITableView*)tableView cellForType:(enum TableViewCellType)type;
//@}
@end


@implementation SettingsViewController


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SettingsViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
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
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case FeedbackSection:
      return MaxFeedbackSectionItem;
    case ViewSection:
      return MaxViewSectionItem;
    case PlayersSection:
      return MaxPlayersSectionItem + 2;  // TODO add correct number here (acquired from model)
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
    case FeedbackSection:
      return @"Feedback when computer plays";
    case ViewSection:
      return @"View settings";
    case PlayersSection:
      return @"Players";
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
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case FeedbackSection:
      cell = [self tableView:tableView cellForType:SwitchCellType];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      accessoryView.enabled = false;  // TODO enable when settings are implemented
      switch (indexPath.row)
      {
        case PlaySoundItem:
          cell.textLabel.text = @"Play sound";
          accessoryView.on = NO;
          break;
        case VibrateItem:
          cell.textLabel.text = @"Vibrate";
          accessoryView.on = NO;
          break;
        default:
          assert(0);
          break;
      }
      break;
    case ViewSection:
      {
        enum TableViewCellType cellType;
        switch (indexPath.row)
        {
          case CrossHairPointDistanceFromFingerItem:
            cellType = Value1CellType;
            break;
          default:
            cellType = SwitchCellType;
            break;
        }
        cell = [self tableView:tableView cellForType:cellType];
        UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
        accessoryView.enabled = false;  // TODO enable when settings are implemented
        switch (indexPath.row)
        {
          case MarkLastMoveItem:
            cell.textLabel.text = @"Mark last move";
            accessoryView.on = YES;
            break;
          case DisplayCoordinatesItem:
            cell.textLabel.text = @"Coordinates";
            accessoryView.on = NO;
            break;
          case DisplayMoveNumbersItem:
            cell.textLabel.text = @"Move numbers";
            accessoryView.on = NO;
            break;
          case CrossHairPointDistanceFromFingerItem:
            cell.textLabel.text = @"Cross-hair distance";
            cell.detailTextLabel.text = @"2";
            break;
          default:
            assert(0);
            break;
        }
        break;
      }
    case PlayersSection:
      cell = [self tableView:tableView cellForType:DefaultCellType];
      // TODO enable this when player management is implemented
      //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      // TODO add icon to player entries to distinguish human from computer
      // players
      switch (indexPath.row)
      {
        case 0:
          cell.textLabel.text = @"Human Player";
          break;
        case 1:
          cell.textLabel.text = @"Computer Player";
          break;
        case 2:
          cell.textLabel.text = @"Add player ...";
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
  
//  UIViewController* modalController;
  switch (indexPath.section)
  {
    case FeedbackSection:
//      modalController = [[BoardSizeController controllerWithDelegate:self
//                                                    defaultBoardSize:self.boardSize] retain];
      break;
    case ViewSection:
      return;
    case PlayersSection:
      return;
    default:
      assert(0);
      return;
  }
/*
  UINavigationController* navigationController = [[UINavigationController alloc]
                                                  initWithRootViewController:modalController];
  navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
  [self presentModalViewController:navigationController animated:YES];
  [navigationController release];
  [modalController release];
*/
}

// -----------------------------------------------------------------------------
/// @brief Factory method that returns a UITableViewCell object for
/// @a tableView, with a style that is appropriate for the requested @a type.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForType:(enum TableViewCellType)type
{
  // Check whether we can reuse an existing cell object
  NSString* cellID;
  switch (type)
  {
    case DefaultCellType:
      cellID = @"DefaultCellType";
      break;
    case Value1CellType:
      cellID = @"Value1CellType";
      break;
    case SwitchCellType:
      cellID = @"SwitchCellType";
      break;
    default:
      assert(0);
      return nil;
  }
  // UITableViewCell does the caching for us
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell != nil)
    return cell;

  // Create the cell object
  UITableViewCellStyle cellStyle;
  switch (type)
  {
    case Value1CellType:
      cellStyle = UITableViewCellStyleValue1;
      break;
    default:
      cellStyle = UITableViewCellStyleDefault;
      break;
  }
  cell = [[[UITableViewCell alloc] initWithStyle:cellStyle
                                 reuseIdentifier:cellID] autorelease];

  // Additional customization
  switch (type)
  {
    case SwitchCellType:
      {
        // UISwitch ignores the frame, so we can conveniently use CGRectZero here
        UISwitch* accessoryViewSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = accessoryViewSwitch;
        break;
      }
    default:
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
  }

  // Return the finished product
  return cell;
}


@end
