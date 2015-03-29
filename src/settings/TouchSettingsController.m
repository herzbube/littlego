// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "TouchSettingsController.h"
#import "../main/ApplicationDelegate.h"
#import "../ui/MagnifyingViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Touch interaction" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum TouchInteractionTableViewSection
{
  EnableModeSection,
  DistanceFromMagnificationCenterSection,
  VeerDirectionSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the EnableModeSection.
// -----------------------------------------------------------------------------
enum EnableModeSectionItem
{
  EnableModeItem,
  AutoThresholdItem,
  MaxEnableModeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DistanceFromMagnificationCenterSection.
// -----------------------------------------------------------------------------
enum DistanceFromMagnificationCenterSectionItem
{
  DistanceFromMagnificationCenterItem,
  MaxDistanceFromMagnificationCenterSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the VeerDirectionSection.
// -----------------------------------------------------------------------------
enum VeerDirectionSectionItem
{
  VeerDirectionItem,
  MaxVeerDirectionSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates how many options we provide the user with to change the
/// auto threshold size.
///
/// The values in this enumeration correspond to those in the global
/// enumeration #MagnifyingGlassAutoThreshold. The difference is that the
/// numeric values in #AutoThresholdFrequency are useful as zero-based indexes,
/// which we need to drive an ItemPickerController.
// -----------------------------------------------------------------------------
enum AutoThresholdFrequency
{
  AutoThresholdFrequencyLessOften,
  AutoThresholdFrequencyNormal,
  AutoThresholdFrequencyMoreOften
};

// -----------------------------------------------------------------------------
/// @brief Enumerates the settings we provide the user with to change the
/// distance of the magnifying glass from the magnification center.
///
/// The values in this enumeration correspond to those in the global
/// enumeration #MagnifyingGlassDistanceFromMagnificationCenter. The difference
/// is that the numeric values in #DistanceFromMagnificationCenterSetting are
/// useful as zero-based indexes, which we need to drive an
/// ItemPickerController.
// -----------------------------------------------------------------------------
enum DistanceFromMagnificationCenterSetting
{
  DistanceFromMagnificationCenterSettingCloser,
  DistanceFromMagnificationCenterSettingNormal,
  DistanceFromMagnificationCenterSettingFarther
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for TouchSettingsController.
// -----------------------------------------------------------------------------
@interface TouchSettingsController()
@property(nonatomic, assign) MagnifyingViewModel* magnifyingViewModel;
@end


@implementation TouchSettingsController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TouchSettingsController instance
/// of grouped style.
// -----------------------------------------------------------------------------
+ (TouchSettingsController*) controller
{
  TouchSettingsController* controller = [[TouchSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.magnifyingViewModel = [ApplicationDelegate sharedDelegate].magnifyingViewModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TouchSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.magnifyingViewModel = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Touch interaction";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (MagnifyingGlassEnableModeAlwaysOff == self.magnifyingViewModel.enableMode)
    return 1;
  else
    return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case EnableModeSection:
      if (MagnifyingGlassEnableModeAuto == self.magnifyingViewModel.enableMode)
        return MaxEnableModeSectionItem;
      else
        return (MaxEnableModeSectionItem - 1);
    case DistanceFromMagnificationCenterSection:
      return MaxDistanceFromMagnificationCenterSectionItem;
    case VeerDirectionSection:
      return MaxVeerDirectionSectionItem;
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
    case EnableModeSection:
    {
      switch (indexPath.row)
      {
        case EnableModeItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Show magnifying glass";
          cell.detailTextLabel.text = [self enableModeName:self.magnifyingViewModel.enableMode];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case AutoThresholdItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Auto takes effect";
          cell.detailTextLabel.text = [self autoThresholdName:self.magnifyingViewModel.autoThreshold];
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
    case DistanceFromMagnificationCenterSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Distance from center";
      cell.detailTextLabel.text = [self distanceFromMagnificationCenterName:self.magnifyingViewModel.distanceFromMagnificationCenter];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      break;
    }
    case VeerDirectionSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Veer direction";
      cell.detailTextLabel.text = [self veerDirectionName:self.magnifyingViewModel.veerDirection];
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
  NSString* titleString = nil;
  int indexOfDefaultItem = -1;
  NSString* footerTitle = nil;
  switch (indexPath.section)
  {
    case EnableModeSection:
    {
      switch (indexPath.row)
      {
        case EnableModeItem:
        {
          [itemList addObject:[self enableModeName:MagnifyingGlassEnableModeAlwaysOn]];
          [itemList addObject:[self enableModeName:MagnifyingGlassEnableModeAlwaysOff]];
          [itemList addObject:[self enableModeName:MagnifyingGlassEnableModeAuto]];
          indexOfDefaultItem = self.magnifyingViewModel.enableMode;
          titleString = @"Show magnifying glass";
          footerTitle = @"Controls if/when the magnifying glass is shown when you place a stone. If set to 'Auto', the app will show the magnifying glass only when intersections become too small to see when the fingertip touches the screen.";
          break;
        }
        case AutoThresholdItem:
        {
          [itemList addObject:[self autoThresholdName:MagnifyingGlassAutoThresholdLessOften]];
          [itemList addObject:[self autoThresholdName:MagnifyingGlassAutoThresholdNormal]];
          [itemList addObject:[self autoThresholdName:MagnifyingGlassAutoThresholdMoreOften]];
          indexOfDefaultItem = [self autoThresholdFrequency:self.magnifyingViewModel.autoThreshold];
          titleString = @"Auto takes effect";
          footerTitle = @"Adjusts how often you want the magnifying glass to pop up in 'Auto' mode. Select 'More often' if you want the magnifying glass to pop up even if intersections are fairly large. Select 'Less often' if you want the magnifying glass to pop up only if intersections are fairly small.";
          break;
        }
        default:
        {
          assert(0);
          return;
        }
      }
      break;
    }
    case DistanceFromMagnificationCenterSection:
    {
      [itemList addObject:[self distanceFromMagnificationCenterName:MagnifyingGlassDistanceFromMagnificationCenterCloser]];
      [itemList addObject:[self distanceFromMagnificationCenterName:MagnifyingGlassDistanceFromMagnificationCenterNormal]];
      [itemList addObject:[self distanceFromMagnificationCenterName:MagnifyingGlassDistanceFromMagnificationCenterFarther]];
      indexOfDefaultItem = [self distanceFromMagnificationCenterSetting:self.magnifyingViewModel.distanceFromMagnificationCenter];
      titleString = @"Distance from center";
      footerTitle = @"Adjusts the vertical distance of the magnifying glass from the center of magnification.";
      break;
      break;
    }
    case VeerDirectionSection:
    {
      [itemList addObject:[self veerDirectionName:MagnifyingGlassVeerDirectionLeft]];
      [itemList addObject:[self veerDirectionName:MagnifyingGlassVeerDirectionRight]];
      indexOfDefaultItem = self.magnifyingViewModel.veerDirection;
      titleString = @"Veer direction";
      footerTitle = @"Select the horizontal direction in which the magnifying glass veers away when it reaches the top of the screen.";
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }

  ItemPickerController* itemPickerController = [ItemPickerController controllerWithItemList:itemList
                                                                                      title:titleString
                                                                         indexOfDefaultItem:indexOfDefaultItem
                                                                                   delegate:self];
  itemPickerController.itemPickerControllerMode = ItemPickerControllerModeNonModal;

  itemPickerController.context = indexPath;
  itemPickerController.footerTitle = footerTitle;
  [self.navigationController pushViewController:itemPickerController animated:YES];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  bool reloadRowOnly = true;
  NSIndexPath* indexPath = controller.context;
  switch (indexPath.section)
  {
    case EnableModeSection:
    {
      switch (indexPath.row)
      {
        case EnableModeItem:
        {
          self.magnifyingViewModel.enableMode = controller.indexOfSelectedItem;
          reloadRowOnly = false;
          break;
        }
        case AutoThresholdItem:
        {
          self.magnifyingViewModel.autoThreshold = [self autoThreshold:controller.indexOfSelectedItem];
          break;
        }
        default:
        {
          assert(0);
          return;
        }
      }
      break;
    }
    case DistanceFromMagnificationCenterSection:
    {
      self.magnifyingViewModel.distanceFromMagnificationCenter = [self magnifyingGlassDistanceFromMagnificationCenter:controller.indexOfSelectedItem];
      break;
    }
    case VeerDirectionSection:
    {
      self.magnifyingViewModel.veerDirection = controller.indexOfSelectedItem;
      break;
    }
    default:
    {
      assert(0);
      return;
    }
  }

  if (reloadRowOnly)
  {
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:UITableViewRowAnimationNone];
  }
  else
  {
    [self.tableView reloadData];
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a enableMode that is suitable for
/// displaying in the UI.
// -----------------------------------------------------------------------------
- (NSString*) enableModeName:(enum MagnifyingGlassEnableMode)enableMode
{
  switch (enableMode)
  {
    case MagnifyingGlassEnableModeAlwaysOn:
      return @"Always";
    case MagnifyingGlassEnableModeAlwaysOff:
      return @"Never";
    case MagnifyingGlassEnableModeAuto:
      return @"Auto";
    default:
      [ExceptionUtility throwNotImplementedException];
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a autoThreshold that is suitable
/// for displaying in the UI.
// -----------------------------------------------------------------------------
- (NSString*) autoThresholdName:(enum MagnifyingGlassAutoThreshold)autoThreshold
{
  switch (autoThreshold)
  {
    case MagnifyingGlassAutoThresholdLessOften:
      return @"Less often";
    case MagnifyingGlassAutoThresholdNormal:
      return @"Normal";
    case MagnifyingGlassAutoThresholdMoreOften:
      return @"More often";
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps @a autoThreshold to a value from the enumeration
/// #AutoThresholdFrequency.
// -----------------------------------------------------------------------------
- (enum AutoThresholdFrequency) autoThresholdFrequency:(enum MagnifyingGlassAutoThreshold)autoThreshold
{
  switch (autoThreshold)
  {
    case MagnifyingGlassAutoThresholdLessOften:
      return AutoThresholdFrequencyLessOften;
    case MagnifyingGlassAutoThresholdNormal:
      return AutoThresholdFrequencyNormal;
    case MagnifyingGlassAutoThresholdMoreOften:
      return AutoThresholdFrequencyMoreOften;
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return AutoThresholdFrequencyNormal;
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps @a autoThresholdFrequency to a value from the enumeration
/// #MagnifyingGlassAutoThreshold.
// -----------------------------------------------------------------------------
- (enum MagnifyingGlassAutoThreshold) autoThreshold:(enum AutoThresholdFrequency)autoThresholdFrequency
{
  switch (autoThresholdFrequency)
  {
    case AutoThresholdFrequencyLessOften:
      return MagnifyingGlassAutoThresholdLessOften;
    case AutoThresholdFrequencyNormal:
      return MagnifyingGlassAutoThresholdNormal;
    case AutoThresholdFrequencyMoreOften:
      return MagnifyingGlassAutoThresholdMoreOften;
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return MagnifyingGlassAutoThresholdNormal;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a distanceFromMagnificationCenter
/// that is suitable for displaying in the UI.
// -----------------------------------------------------------------------------
- (NSString*) distanceFromMagnificationCenterName:(enum MagnifyingGlassDistanceFromMagnificationCenter)distanceFromMagnificationCenter
{
  switch (distanceFromMagnificationCenter)
  {
    case MagnifyingGlassDistanceFromMagnificationCenterCloser:
      return @"Closer";
    case MagnifyingGlassDistanceFromMagnificationCenterNormal:
      return @"Normal";
    case MagnifyingGlassDistanceFromMagnificationCenterFarther:
      return @"Farther";
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps @a distanceFromMagnificationCenter to a value from the
/// enumeration #DistanceFromMagnificationCenterSetting.
// -----------------------------------------------------------------------------
- (enum DistanceFromMagnificationCenterSetting) distanceFromMagnificationCenterSetting:(enum MagnifyingGlassDistanceFromMagnificationCenter)distanceFromMagnificationCenter
{
  switch (distanceFromMagnificationCenter)
  {
    case MagnifyingGlassDistanceFromMagnificationCenterCloser:
      return DistanceFromMagnificationCenterSettingCloser;
    case MagnifyingGlassDistanceFromMagnificationCenterNormal:
      return DistanceFromMagnificationCenterSettingNormal;
    case MagnifyingGlassDistanceFromMagnificationCenterFarther:
      return DistanceFromMagnificationCenterSettingFarther;
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return DistanceFromMagnificationCenterSettingNormal;
  }
}

// -----------------------------------------------------------------------------
/// @brief Maps @a distanceFromMagnificationCenterSetting to a value from the
/// enumeration #MagnifyingGlassDistanceFromMagnificationCenter.
// -----------------------------------------------------------------------------
- (enum MagnifyingGlassDistanceFromMagnificationCenter) magnifyingGlassDistanceFromMagnificationCenter:(enum DistanceFromMagnificationCenterSetting)distanceFromMagnificationCenterSetting
{
  switch (distanceFromMagnificationCenterSetting)
  {
    case DistanceFromMagnificationCenterSettingCloser:
      return MagnifyingGlassDistanceFromMagnificationCenterCloser;
    case DistanceFromMagnificationCenterSettingNormal:
      return MagnifyingGlassDistanceFromMagnificationCenterNormal;
    case DistanceFromMagnificationCenterSettingFarther:
      return MagnifyingGlassDistanceFromMagnificationCenterFarther;
    default:
      [ExceptionUtility throwNotImplementedException];
      // Pseudo return statement to make the compiler happy (which does not
      // "see" the exception thrown above)
      return MagnifyingGlassDistanceFromMagnificationCenterNormal;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a veerDirection that is suitable
/// for displaying in the UI.
// -----------------------------------------------------------------------------
- (NSString*) veerDirectionName:(enum MagnifyingGlassVeerDirection)veerDirection
{
  switch (veerDirection)
  {
    case MagnifyingGlassVeerDirectionLeft:
      return @"Left";
    case MagnifyingGlassVeerDirectionRight:
      return @"Right";
    default:
      [ExceptionUtility throwNotImplementedException];
      return nil;
  }
}

@end
