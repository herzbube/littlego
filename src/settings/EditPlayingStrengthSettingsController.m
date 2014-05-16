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
#import "EditPlayingStrengthSettingsController.h"
#import "../player/GtpEngineProfile.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Playing strength settings"
/// table view.
// -----------------------------------------------------------------------------
enum EditPlayingStrengthSettingsTableViewSection
{
  MaxMemorySection,
  ThreadsSection,
  PonderingSection,
  ReuseSubtreeSection,
  PlayoutLimitsSection,
  ResetToDefaultsSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MaxMemorySection.
// -----------------------------------------------------------------------------
enum MaxMemorySectionItem
{
  FuegoMaxMemoryItem,
  MaxMaxMemorySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ThreadsSection.
// -----------------------------------------------------------------------------
enum ThreadsSectionItem
{
  FuegoThreadCountItem,
  MaxThreadsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PonderingSection.
// -----------------------------------------------------------------------------
enum PonderingSectionItem
{
  FuegoPonderingItem,
  FuegoMaxPonderTimeItem,
  MaxPonderingSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ReuseSubtreeSection.
// -----------------------------------------------------------------------------
enum ReuseSubtreeSectionItem
{
  FuegoReuseSubtreeItem,
  MaxReuseSubtreeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayoutLimitsSection.
// -----------------------------------------------------------------------------
enum PlayoutLimitsSectionItem
{
  FuegoMaxThinkingTimeItem,
  FuegoMaxGamesItem,
  MaxPlayoutLimitsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResetToDefaultsSection.
// -----------------------------------------------------------------------------
enum ResetToDefaultsSectionItem
{
  ResetToDefaultsItem,
  MaxResetToDefaultsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates categories of "max. games" as they are displayed to the
/// user instead of meaningless raw numbers.
// -----------------------------------------------------------------------------
enum MaxGamesCategory
{
  Game1MaxGamesCategory,
  Game10MaxGamesCategory,
  Game100MaxGamesCategory,
  Game500MaxGamesCategory,
  Game1000MaxGamesCategory,
  Game2000MaxGamesCategory,
  Game5000MaxGamesCategory,
  Game10000MaxGamesCategory,
  Game15000MaxGamesCategory,
  Game20000MaxGamesCategory,
  Game50000MaxGamesCategory,
  UnlimitedMaxGamesCategory,
  MaxMaxGamesCategory,
  UndefinedMaxGamesCategory
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditPlayingStrengthSettingsController.
// -----------------------------------------------------------------------------
@interface EditPlayingStrengthSettingsController()
@property(nonatomic, retain) UISwitch* reuseSubtreeSwitch;
@end


@implementation EditPlayingStrengthSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an
/// EditPlayingStrengthSettingsController instance of grouped style that is
/// used to edit the playing strength attributes of @a profile.
// -----------------------------------------------------------------------------
+ (EditPlayingStrengthSettingsController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditPlayingStrengthSettingsDelegate>)delegate
{
  EditPlayingStrengthSettingsController* controller = [[EditPlayingStrengthSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = profile;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// EditPlayingStrengthSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  self.reuseSubtreeSwitch = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Playing strength";
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
    case MaxMemorySection:
      return MaxMaxMemorySectionItem;
    case ThreadsSection:
      return MaxThreadsSectionItem;
    case PonderingSection:
      return MaxPonderingSectionItem;
    case ReuseSubtreeSection:
      return MaxReuseSubtreeSectionItem;
    case PlayoutLimitsSection:
      return MaxPlayoutLimitsSectionItem;
    case ResetToDefaultsSection:
      return MaxResetToDefaultsSectionItem;
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
  UITableViewCell* cell = nil;
  switch (indexPath.section)
  {
    case MaxMemorySection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Maximum memory";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d MB", self.profile.fuegoMaxMemory];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case ThreadsSection:
    {
      cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(threadCountDidChange:)];
      sliderCell.descriptionLabel.text = @"Number of threads";
      sliderCell.slider.minimumValue = fuegoThreadCountMinimum;
      sliderCell.slider.maximumValue = fuegoThreadCountMaximum;
      sliderCell.value = self.profile.fuegoThreadCount;
      break;
    }
    case PonderingSection:
    {
      switch (indexPath.row)
      {
        case FuegoPonderingItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Pondering";
          accessoryView.on = self.profile.fuegoPondering;
          [accessoryView addTarget:self action:@selector(togglePondering:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case FuegoMaxPonderTimeItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxPonderTimeDidChange:)];
          sliderCell.descriptionLabel.text = @"Ponder time (minutes)";
          sliderCell.slider.minimumValue = fuegoMaxPonderTimeMinimum / 60;
          sliderCell.slider.maximumValue = fuegoMaxPonderTimeMaximum / 60;
          sliderCell.value = self.profile.fuegoMaxPonderTime / 60;
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
    case ReuseSubtreeSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Reuse subtree";
      accessoryView.on = self.profile.fuegoReuseSubtree;
      [accessoryView addTarget:self action:@selector(toggleReuseSubtree:) forControlEvents:UIControlEventValueChanged];
      // If pondering is on, the default value of reuse subtree ("on") must
      // not be changed by the user
      accessoryView.enabled = ! self.profile.fuegoPondering;
      // Keep reference to control so that we can manipulate it when
      // pondering is changed later on
      self.reuseSubtreeSwitch = accessoryView;
      break;
    }
    case PlayoutLimitsSection:
    {
      switch (indexPath.row)
      {
        case FuegoMaxThinkingTimeItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxThinkingTimeDidChange:)];
          sliderCell.descriptionLabel.text = @"Thinking time (seconds)";
          sliderCell.slider.minimumValue = fuegoMaxThinkingTimeMinimum;
          sliderCell.slider.maximumValue = fuegoMaxThinkingTimeMaximum;
          sliderCell.value = self.profile.fuegoMaxThinkingTime;
          break;
        }
        case FuegoMaxGamesItem:
        {
          enum TableViewCellType cellType = Value1CellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          cell.textLabel.text = @"Max. games";
          if (fuegoMaxGamesMaximum == self.profile.fuegoMaxGames)
            cell.detailTextLabel.text = @"Unlimited";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%lld", self.profile.fuegoMaxGames];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    case ResetToDefaultsSection:
    {
      cell = [TableViewCellFactory cellWithType:DeleteTextCellType tableView:tableView];
      cell.textLabel.text = @"Reset to default values";
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
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
    case ThreadsSection:
    {
      height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case PonderingSection:
    {
      if (FuegoMaxPonderTimeItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case PlayoutLimitsSection:
    {
      if (FuegoMaxThinkingTimeItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    default:
    {
      break;
    }
  }
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (MaxMemorySection == indexPath.section)
  {
    MaxMemoryController* modalController = [[[MaxMemoryController alloc] init] autorelease];
    modalController.delegate = self;
    modalController.maxMemory = self.profile.fuegoMaxMemory;
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:modalController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
  }
  else if (PlayoutLimitsSection == indexPath.section)
  {
    if (FuegoMaxGamesItem == indexPath.row)
    {
      NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
      formatter.numberStyle = NSNumberFormatterDecimalStyle;
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      for (int maxGamesCategoryIndex = 0; maxGamesCategoryIndex < MaxMaxGamesCategory; ++maxGamesCategoryIndex)
      {
        unsigned long long maxGames = [self maxGames:maxGamesCategoryIndex];
        NSString* maxGamesCategory;
        if (UnlimitedMaxGamesCategory == maxGamesCategoryIndex)
          maxGamesCategory = @"Unlimited";
        else
          maxGamesCategory = [formatter stringFromNumber:[NSNumber numberWithUnsignedLongLong:maxGames]];
        [itemList addObject:maxGamesCategory];
      }
      int indexOfDefaultMaxGamesCategory = [self maxGamesCategory:self.profile.fuegoMaxGames];
      if (UndefinedMaxGamesCategory == indexOfDefaultMaxGamesCategory)
        indexOfDefaultMaxGamesCategory = -1;
      UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 title:@"Max. games"
                                                                    indexOfDefaultItem:indexOfDefaultMaxGamesCategory
                                                                              delegate:self];
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:modalController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentViewController:navigationController animated:YES completion:nil];
      [navigationController release];
    }
  }
  else if (ResetToDefaultsSection == indexPath.section)
  {
    // TODO iPad: Modify this to not include a cancel button (see HIG).
    UIActionSheet* actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:@"Reset to default values"
                                                    otherButtonTitles:nil];
    // The acton sheet must be shown based on the cell, not the table view,
    // otherwise buttons in the sheet cannot be properly tapped.
    [actionSheet showInView:[tableView cellForRowAtIndexPath:indexPath]];
    [actionSheet release];
  }
}

#pragma mark - MaxMemoryControllerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief MaxMemoryControllerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didEndEditing:(MaxMemoryController*)maxMemoryController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    self.profile.fuegoMaxMemory = maxMemoryController.maxMemory;
    NSUInteger sectionIndex = MaxMemorySection;
    NSUInteger rowIndex = FuegoMaxMemoryItem;
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
    NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
    [self.tableView reloadRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationNone];
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
    {
      self.profile.fuegoMaxGames = [self maxGames:controller.indexOfSelectedItem];

      [self.delegate didChangeProfile:self];

      NSUInteger sectionIndex = PlayoutLimitsSection;
      NSUInteger rowIndex = FuegoMaxGamesItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIActionSheetDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet.cancelButtonIndex != buttonIndex)
  {
    [self.profile resetPlayingStrengthPropertiesToDefaultValues];
    [self.delegate didChangeProfile:self];
    [self.tableView reloadData];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) togglePondering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoPondering = accessoryView.on;

  [self.delegate didChangeProfile:self];

  // Directly manipulating the switch control gives the best result,
  // graphics-wise. If we do the update via table view reload of a single cell,
  // there is a nasty little flicker when pondering is turned off and the
  // "reuse subtree" switch becomes enabled. I have not tracked down the source
  // of the flicker, but instead gone straight to directly manipulating the
  // switch control.
  if (self.profile.fuegoPondering)
  {
    self.profile.fuegoReuseSubtree = true;
    self.reuseSubtreeSwitch.on = true;
  }
  self.reuseSubtreeSwitch.enabled = ! self.profile.fuegoPondering;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Reuse subtree" switch. Updates the
/// profile object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleReuseSubtree:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoReuseSubtree = accessoryView.on;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's number of threads.
// -----------------------------------------------------------------------------
- (void) threadCountDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoThreadCount = sliderCell.value;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum pondering time.
// -----------------------------------------------------------------------------
- (void) maxPonderTimeDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxPonderTime = sliderCell.value * 60;

  [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum thinking time.
// -----------------------------------------------------------------------------
- (void) maxThinkingTimeDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxThinkingTime = sliderCell.value;

  [self.delegate didChangeProfile:self];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns a natural number corresponding to the enumeration value
/// @a maxGamesCategory.
///
/// Raises an @e NSInvalidArgumentException if @a maxGamesCategory is not
/// recognized.
// -----------------------------------------------------------------------------
- (unsigned long long) maxGames:(enum MaxGamesCategory)maxGamesCategory
{
  switch (maxGamesCategory)
  {
    case Game1MaxGamesCategory:
      return 1;
    case Game10MaxGamesCategory:
      return 10;
    case Game100MaxGamesCategory:
      return 100;
    case Game500MaxGamesCategory:
      return 500;
    case Game1000MaxGamesCategory:
      return 1000;
    case Game2000MaxGamesCategory:
      return 2000;
    case Game5000MaxGamesCategory:
      return 5000;
    case Game10000MaxGamesCategory:
      return 10000;
    case Game15000MaxGamesCategory:
      return 15000;
    case Game20000MaxGamesCategory:
      return 20000;
    case Game50000MaxGamesCategory:
      return 50000;
    case UnlimitedMaxGamesCategory:
      return fuegoMaxGamesMaximum;
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid 'max. games' category: %d", maxGamesCategory];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a category enumeration value that corresponds to the natural
/// number @a maxGames. Returns #UndefinedMaxGamesCategory if there is no
/// corresponding category.
// -----------------------------------------------------------------------------
- (enum MaxGamesCategory) maxGamesCategory:(unsigned long long)maxGames
{
  if (fuegoMaxGamesMaximum == maxGames)
    return UnlimitedMaxGamesCategory;
  switch (maxGames)
  {
    case 1:
      return Game1MaxGamesCategory;
    case 10:
      return Game10MaxGamesCategory;
    case 100:
      return Game100MaxGamesCategory;
    case 500:
      return Game500MaxGamesCategory;
    case 1000:
      return Game1000MaxGamesCategory;
    case 2000:
      return Game2000MaxGamesCategory;
    case 5000:
      return Game5000MaxGamesCategory;
    case 10000:
      return Game10000MaxGamesCategory;
    case 15000:
      return Game15000MaxGamesCategory;
    case 20000:
      return Game20000MaxGamesCategory;
    case 50000:
      return Game50000MaxGamesCategory;
    default:
      return UndefinedMaxGamesCategory;
  }
}

@end
