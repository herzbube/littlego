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
#import "../play/model/PlayViewModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"

// Constants
static const float sliderValueFactorForMaximumZoomScale = 10.0;
static const float sliderValueFactorForStoneDistanceFromFingertip = 100.0;


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Touch interaction" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum TouchInteractionTableViewSection
{
  StoneDistanceFromFingertipSection,
  ZoomSection,
  MaxSection
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
/// @brief Class extension with private properties for TouchSettingsController.
// -----------------------------------------------------------------------------
@interface TouchSettingsController()
@property(nonatomic, assign) PlayViewModel* playViewModel;
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
    controller.playViewModel = [ApplicationDelegate sharedDelegate].playViewModel;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TouchSettingsController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.playViewModel = nil;
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
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
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
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case StoneDistanceFromFingertipSection:
      return @"Controls how far away from your fingertip the stone appears when you touch the board. The lowest setting places the stone directly under your fingertip.";
    case ZoomSection:
      return @"Controls how much you can zoom the board. Because zooming costs (a lot of) memory you may want to set a limit that is below the maximum. This makes sure that you cannot crash the application by accidentally zooming the board too much.";
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
          float maximumZoomScaleMaximum;
          if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
            maximumZoomScaleMaximum = iPhoneMaximumZoomScaleMaximum;
          else
            maximumZoomScaleMaximum = iPadMaximumZoomScaleMaximum;
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

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
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

#pragma mark - Action handlers

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
