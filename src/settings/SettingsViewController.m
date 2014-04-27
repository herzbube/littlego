// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "DisplaySettingsController.h"
#import "PlayerProfileSettingsController.h"
#import "ScoringSettingsController.h"
#import "SoundSettingsController.h"
#import "TouchSettingsController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Settings" table view.
// -----------------------------------------------------------------------------
enum SettingsTableViewSection
{
  ViewSettingsSection,
  TouchAndSoundSettingsSection,
  PlayersProfilesSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ViewSettingsSection.
// -----------------------------------------------------------------------------
enum ViewSettingsSectionItem
{
  PlayViewSettingsItem,
  BoardPositionSettingsItem,
  ScoringSettingsItem,
  MaxViewSettingsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TouchAndSoundSettingsSection.
// -----------------------------------------------------------------------------
enum TouchAndSoundSettingsSectionItem
{
  TouchInteractionItem,
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
        case PlayViewSettingsItem:
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
      }
      break;
    }
    case TouchAndSoundSettingsSection:
    {
      switch (indexPath.row)
      {
        case TouchInteractionItem:
        {
          cell.textLabel.text = @"Touch interaction";
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
        case PlayViewSettingsItem:
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
      }
      break;
    }
    case TouchAndSoundSettingsSection:
    {
      switch (indexPath.row)
      {
        case TouchInteractionItem:
        {
          controller = [TouchSettingsController controller];
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
    default:
    {
      break;
    }
  }
  if (controller)
    [self.navigationController pushViewController:controller animated:YES];
}

@end
