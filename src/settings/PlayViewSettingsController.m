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
#import "PlayViewSettingsController.h"
#import "../command/playerinfluence/ToggleTerritoryStatisticsCommand.h"
#import "../main/ApplicationDelegate.h"
#import "../play/model/PlayViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/UiUtilities.h"

// Constants
static const float sliderValueFactorForMaximumZoomScale = 10.0;
static const float sliderValueFactorForMoveNumbersPercentage = 100.0;
static const float sliderValueFactorForStoneDistanceFromFingertip = 100.0;
NSString* displayPlayerInfluenceText = @"Display player influence";


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Play View" user preferences
/// table view.
// -----------------------------------------------------------------------------
enum PlayViewTableViewSection
{
  FeedbackSection,
  ViewSection,
  DisplayMoveNumbersSection,
  DisplayPlayerInfluenceSection,
  StoneDistanceFromFingertipSection,
  ZoomSection,
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
  MaxViewSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisplayMoveNumbersSection.
// -----------------------------------------------------------------------------
enum DisplayMoveNumbersSectionItem
{
  MoveNumbersPercentageItem,
  MaxDisplayMoveNumbersSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the DisplayPlayerInfluenceSection.
// -----------------------------------------------------------------------------
enum DisplayPlayerInfluenceSectionItem
{
  DisplayPlayerInfluenceItem,
  MaxDisplayPlayerInfluenceSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the StoneDistanceFromFingertipSection.
// -----------------------------------------------------------------------------
enum StoneDistanceFromFingertipSectionItem
{
  StoneDistanceFromFingertipItem,
  MaxStoneDistanceFromFingertipSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ZoomSection.
// -----------------------------------------------------------------------------
enum ZoomSectionItem
{
  MaxZoomScaleItem,
  MaxZoomSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// PlayViewSettingsController.
// -----------------------------------------------------------------------------
@interface PlayViewSettingsController()
@property(nonatomic, assign) PlayViewModel* playViewModel;
@end


@implementation PlayViewSettingsController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a PlayViewSettingsController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (PlayViewSettingsController*) controller
{
  PlayViewSettingsController* controller = [[PlayViewSettingsController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
    [controller autorelease];
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewSettingsController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.playViewModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  ApplicationDelegate* delegate = [ApplicationDelegate sharedDelegate];
  self.playViewModel = delegate.playViewModel;
  
  self.title = @"Play view settings";
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
    case FeedbackSection:
      return MaxFeedbackSectionItem;
    case ViewSection:
      return MaxViewSectionItem;
    case DisplayMoveNumbersSection:
      return MaxDisplayMoveNumbersSectionItem;
    case DisplayPlayerInfluenceSection:
      return MaxDisplayPlayerInfluenceSectionItem;
    case StoneDistanceFromFingertipSection:
      return MaxStoneDistanceFromFingertipSectionItem;
    case ZoomSection:
      return MaxZoomSectionItem;
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
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case ViewSection:
      return @"On the iPhone you may need to zoom in to see coordinate labels.";
    case DisplayMoveNumbersSection:
      return @"The lowest setting displays no move numbers, the highest setting displays all move numbers. On the iPhone you may need to zoom in to see move numbers.";
    case DisplayPlayerInfluenceSection:
      return @"After turning this on, you will see player influence as soon as the computer player has made its next move, or you have selected 'Update player influence' from the actions menu on the Play tab.";
    case StoneDistanceFromFingertipSection:
      return @"Controls how far away from your fingertip the stone appears when you touch the board. The lowest setting places the stone directly under your fingertip.";
    case ZoomSection:
      return @"Controls how much you can zoom the board. Because zooming costs memory you may want to set a limit that is below the maximum zoom (3x). A limit of 2x zoom is recommended for devices that do not have much RAM (typically older devices such as the iPhone 3GS or the iPad 1st generation).";
    default:
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
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      switch (indexPath.row)
      {
        case PlaySoundItem:
          cell.textLabel.text = @"Play sound";
          accessoryView.on = self.playViewModel.playSound;
          [accessoryView addTarget:self action:@selector(togglePlaySound:) forControlEvents:UIControlEventValueChanged];
          break;
        case VibrateItem:
          cell.textLabel.text = @"Vibrate";
          accessoryView.on = self.playViewModel.vibrate;
          [accessoryView addTarget:self action:@selector(toggleVibrate:) forControlEvents:UIControlEventValueChanged];
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case ViewSection:
    {
      switch (indexPath.row)
      {
        case MarkLastMoveItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Mark last move";
          accessoryView.on = self.playViewModel.markLastMove;
          [accessoryView addTarget:self action:@selector(toggleMarkLastMove:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case DisplayCoordinatesItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Display coordinates";
          accessoryView.on = self.playViewModel.displayCoordinates;
          [accessoryView addTarget:self action:@selector(toggleDisplayCoordinates:) forControlEvents:UIControlEventValueChanged];
          break;
        }
      }
      break;
    }
    case DisplayMoveNumbersSection:
    {
      switch (indexPath.row)
      {
        case MoveNumbersPercentageItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          sliderCell.valueLabelHidden = true;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(moveNumbersPercentageDidChange:)];
          sliderCell.descriptionLabel.text = @"Display move numbers";
          sliderCell.slider.minimumValue = 0;
          sliderCell.slider.maximumValue = (1.0
                                            * sliderValueFactorForMoveNumbersPercentage);
          sliderCell.value = (self.playViewModel.moveNumbersPercentage
                              * sliderValueFactorForMoveNumbersPercentage);
          break;
        }
      }
      break;
    }
    case DisplayPlayerInfluenceSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = displayPlayerInfluenceText;
      cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
      cell.textLabel.numberOfLines = 0;
      accessoryView.on = self.playViewModel.displayPlayerInfluence;
      [accessoryView addTarget:self action:@selector(toggleDisplayPlayerInfluence:) forControlEvents:UIControlEventValueChanged];
      break;
    }
    case StoneDistanceFromFingertipSection:
    {
      switch (indexPath.row)
      {
        case StoneDistanceFromFingertipItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          sliderCell.valueLabelHidden = true;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(stoneDistanceFromFingertipDidChange:)];
          sliderCell.descriptionLabel.text = @"Stone distance from fingertip";
          sliderCell.slider.minimumValue = 0;
          sliderCell.slider.maximumValue = (1.0
                                            * sliderValueFactorForStoneDistanceFromFingertip);
          sliderCell.value = (self.playViewModel.stoneDistanceFromFingertip
                              * sliderValueFactorForStoneDistanceFromFingertip);
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
    case ZoomSection:
    {
      switch (indexPath.row)
      {
        case MaxZoomScaleItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          sliderCell.valueLabelHidden = true;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxZoomScaleDidChange:)];
          sliderCell.descriptionLabel.text = @"Maximum zoom";
          sliderCell.slider.minimumValue = (1.0
                                            * sliderValueFactorForMaximumZoomScale);
          sliderCell.slider.maximumValue = (maximumZoomScaleMaximum
                                            * sliderValueFactorForMaximumZoomScale);
          sliderCell.value = (self.playViewModel.maximumZoomScale
                              * sliderValueFactorForMaximumZoomScale);
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
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
    case DisplayMoveNumbersSection:
    {
      switch (indexPath.row)
      {
        case MoveNumbersPercentageItem:
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        default:
          break;
      }
      break;
    }
    case DisplayPlayerInfluenceSection:
    {
      NSString* cellText = displayPlayerInfluenceText;
      height = [UiUtilities tableView:tableView
                  heightForCellOfType:SwitchCellType
                             withText:cellText
               hasDisclosureIndicator:false];
      break;
    }
    case StoneDistanceFromFingertipSection:
    {
      switch (indexPath.row)
      {
        case StoneDistanceFromFingertipItem:
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        default:
          break;
      }
      break;
    }
    case ZoomSection:
    {
      switch (indexPath.row)
      {
        case MaxZoomScaleItem:
          height = [TableViewSliderCell rowHeightInTableView:tableView];
          break;
        default:
          break;
      }
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
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Play Sound" switch. Writes the new
/// value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) togglePlaySound:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.playSound = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Vibrate" switch. Writes the new
/// value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleVibrate:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.vibrate = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Mark last move" switch. Writes the
/// new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleMarkLastMove:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.markLastMove = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display coordinates" switch. Writes
/// the new value to the appropriate model.
// -----------------------------------------------------------------------------
- (void) toggleDisplayCoordinates:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.displayCoordinates = accessoryView.on;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the "display move numbers" setting.
// -----------------------------------------------------------------------------
- (void) moveNumbersPercentageDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.playViewModel.moveNumbersPercentage = (1.0 * sliderCell.value / sliderValueFactorForMoveNumbersPercentage);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Display player influence" switch.
// -----------------------------------------------------------------------------
- (void) toggleDisplayPlayerInfluence:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.playViewModel.displayPlayerInfluence = accessoryView.on;
  [[[ToggleTerritoryStatisticsCommand alloc] init] submit];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the "stone distance from fingertip"
/// setting.
// -----------------------------------------------------------------------------
- (void) stoneDistanceFromFingertipDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.playViewModel.stoneDistanceFromFingertip = (1.0 * sliderCell.value / sliderValueFactorForStoneDistanceFromFingertip);
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the "maximum zoom scale" setting.
// -----------------------------------------------------------------------------
- (void) maxZoomScaleDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.playViewModel.maximumZoomScale = (1.0 * sliderCell.value / sliderValueFactorForMaximumZoomScale);
}

@end
