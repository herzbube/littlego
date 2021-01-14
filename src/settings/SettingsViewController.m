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
#import "SettingsViewController.h"
#import "BoardPositionSettingsController.h"
#import "BoardSetupSettingsController.h"
#import "DisplaySettingsController.h"
#import "MagnifyingGlassSettingsController.h"
#import "PlayerProfileSettingsController.h"
#import "ScoringSettingsController.h"
#import "SgfSettingsController.h"
#import "SoundSettingsController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  ViewSettingsSection,
  TouchAndSoundSettingsSection,
  PlayersProfilesSection,
  SgfSettingsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ViewSettingsSection.
// -----------------------------------------------------------------------------
enum ViewSettingsSectionItem
{
  DisplaySettingsItem,
  BoardPositionSettingsItem,
  ScoringSettingsItem,
  BoardSetupItem,
  MaxViewSettingsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TouchAndSoundSettingsSection.
// -----------------------------------------------------------------------------
enum TouchAndSoundSettingsSectionItem
{
  MagnifyingGlassItem,
  SoundVibrationItem,
  MaxTouchAndSoundSettingsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayersProfilesSection.
// -----------------------------------------------------------------------------
enum PlayersProfilesSectionItem
{
  PlayersProfilesSettingsItem,
  MaxPlayersProfilesSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the SgfSettingsSection.
// -----------------------------------------------------------------------------
enum SgfSettingsSectionItem
{
  SgfSettingsItem,
  MaxSgfSettingsSectionItem
};


@implementation SettingsViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a SettingsViewController instance of
/// grouped style.
// -----------------------------------------------------------------------------
+ (SettingsViewController*) controller
{
  SettingsViewController* controller = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
    [controller autorelease];
  return controller;
}

#pragma mark - UITableViewDataSource overrides

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
    case ViewSettingsSection:
      return MaxViewSettingsSectionItem;
    case TouchAndSoundSettingsSection:
      return MaxTouchAndSoundSettingsSectionItem;
    case PlayersProfilesSection:
      return MaxPlayersProfilesSectionItem;
    case SgfSettingsSection:
      return MaxSgfSettingsSectionItem;
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
    case ViewSettingsSection:
    {
      switch (indexPath.row)
      {
        case DisplaySettingsItem:
        {
          cell.textLabel.text = @"Display";
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
        case BoardSetupItem:
        {
          cell.textLabel.text = @"Board setup";
          break;
        }
      }
      break;
    }
    case TouchAndSoundSettingsSection:
    {
      switch (indexPath.row)
      {
        case MagnifyingGlassItem:
        {
          cell.textLabel.text = @"Magnifying Glass";
          break;
        }
        case SoundVibrationItem:
        {
          cell.textLabel.text = @"Sound & Vibration";
          break;
        }
      }
      break;
    }
    case PlayersProfilesSection:
    {
      cell.textLabel.text = @"Players & Profiles";
      break;
    }
    case SgfSettingsSection:
    {
      cell.textLabel.text = @"Smart Game Format (SGF)";
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  UIViewController* controller = nil;
  switch (indexPath.section)
  {
    case ViewSettingsSection:
    {
      switch (indexPath.row)
      {
        case DisplaySettingsItem:
        {
          controller = [DisplaySettingsController controller];
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
        case BoardSetupItem:
        {
          controller = [BoardSetupSettingsController controller];
          break;
        }
      }
      break;
    }
    case TouchAndSoundSettingsSection:
    {
      switch (indexPath.row)
      {
        case MagnifyingGlassItem:
        {
          controller = [MagnifyingGlassSettingsController controller];
          break;
        }
        case SoundVibrationItem:
        {
          controller = [SoundSettingsController controller];
          break;
        }
      }
      break;
    }
    case PlayersProfilesSection:
    {
      controller = [PlayerProfileSettingsController controller];
      break;
    }
    case SgfSettingsSection:
    {
      controller = [SgfSettingsController controller];
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
