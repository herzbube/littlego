// -----------------------------------------------------------------------------
// Copyright 2013-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "SliderInputController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../utility/UIDeviceAdditions.h"


@implementation SliderInputController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an SliderInputController object.
///
/// @note This is the designated initializer of SliderInputController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;
  self.context = nil;
  self.screenTitle = nil;
  self.footerTitle = nil;
  self.descriptionLabelText = nil;
  self.delegate = nil;
  self.value = 0.0;
  self.minimumValue = 0.0;
  self.maximumValue = 0.0;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SliderInputController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.context = nil;
  self.screenTitle = nil;
  self.footerTitle = nil;
  self.descriptionLabelText = nil;
  self.delegate = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = self.screenTitle;

  // We set this because of TableViewSliderCell - see the class docs for details
  if ([UIDevice systemVersionMajor] >= 9)
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didMoveToParentViewController:(UIViewController*)parent
{
  // If parent is nil we were popped from the navigation controller. The class
  // documentation clearly states that we expect to be displayed in a navigation
  // controller.
  if (nil == parent && self.delegate)
    [self.delegate didDismissSliderInputController:self];
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  return self.footerTitle;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
  [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(sliderValueDidChange:)];
  sliderCell.descriptionLabel.text = self.descriptionLabelText;
  sliderCell.slider.minimumValue = self.minimumValue;
  sliderCell.slider.maximumValue = self.maximumValue;
  sliderCell.value = self.value;
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [TableViewSliderCell rowHeightInTableView:tableView];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing the slider value.
// -----------------------------------------------------------------------------
- (void) sliderValueDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.value = sliderCell.value;
}

@end
