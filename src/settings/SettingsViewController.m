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
#import "SettingsViewController.h"
#import "BoardPositionSettingsController.h"
#import "PlayerProfileSettingsController.h"
#import "PlayViewSettingsController.h"
#import "ScoringSettingsController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  SettingsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SettingsSection.
// -----------------------------------------------------------------------------
enum SettingsSectionItem
{
  PlayViewSettingsItem,
  BoardPositionSettingsItem,
  ScoringSettingsItem,
  PlayersProfilesSettingsItem,
  MaxSettingsSectionItem
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
- (void) loadView;
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
/// @brief Creates the view that this controller manages.
///
/// This implementation exists because this controller needs a grouped style
/// table view, and there is no simpler way to specify the table view style.
/// - This controller does not load its table view from a .nib file, so the
///   style can't be specified there
/// - This controller is itself loaded from a .nib file, so the style can't be
///   specified in initWithStyle:()
// -----------------------------------------------------------------------------
- (void) loadView
{
  [UiUtilities createTableViewWithStyle:UITableViewStyleGrouped forController:self];
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
    case SettingsSection:
      return MaxSettingsSectionItem;
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
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  switch (indexPath.section)
  {
    case SettingsSection:
    {
      switch (indexPath.row)
      {
        case PlayViewSettingsItem:
        {
          cell.textLabel.text = @"Play view";
          break;
        }
        case BoardPositionSettingsItem:
        {
          cell.textLabel.text = @"Board position";
          break;
        }
        case ScoringSettingsItem:
        {
          cell.textLabel.text = @"Scoring";
          break;
        }
        case PlayersProfilesSettingsItem:
        {
          cell.textLabel.text = @"Players & Profiles";
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

  UIViewController* controller = nil;
  switch (indexPath.section)
  {
    case SettingsSection:
    {
      switch (indexPath.row)
      {
        case PlayViewSettingsItem:
        {
          controller = [PlayViewSettingsController controller];
          break;
        }
        case BoardPositionSettingsItem:
        {
          controller = [BoardPositionSettingsController controller];
          break;
        }
        case ScoringSettingsItem:
        {
          controller = [ScoringSettingsController controller];
          break;
        }
        case PlayersProfilesSettingsItem:
        {
          controller = [PlayerProfileSettingsController controller];
          break;
        }
        default:
        {
          break;
        }
      }
      break;
    }
    default:
    {
      break;
    }
  }
  if (controller)
    [self.navigationController pushViewController:controller animated:YES];
}

@end
