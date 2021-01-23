// -----------------------------------------------------------------------------
// Copyright 2013-2019 Patrick Näf (herzbube@herzbube.ch)
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
#import "MaxMemoryController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/UIViewControllerAdditions.h"
#import "../utility/UIDeviceAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Maximum memory" user
/// preferences table view.
// -----------------------------------------------------------------------------
enum MaxMemoryTableViewSection
{
  MaxMemorySection,
  PhysicalMemorySection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MaxMemorySection.
// -----------------------------------------------------------------------------
enum MaxMemorySectionItem
{
  MaxMemoryItem,
  MaxMaxMemorySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PhysicalMemorySection.
// -----------------------------------------------------------------------------
enum PhysicalMemorySectionItem
{
  PhysicalMemoryItem,
  MaxPhysicalMemorySectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MaxMemoryController.
// -----------------------------------------------------------------------------
@interface MaxMemoryController()
@property(nonatomic, assign) int physicalMemory;
@property(nonatomic, assign) int maxMemoryLimit;
@end


@implementation MaxMemoryController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a MaxMemoryController object.
///
/// @note This is the designated initializer of MaxMemoryController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;
  self.delegate = nil;
  self.maxMemory = 0;
  self.physicalMemory = [UIDevice physicalMemoryMegabytes];
  if (self.physicalMemory <= 256)
    self.maxMemoryLimit = self.physicalMemory / 4;
  else if (self.physicalMemory <= 512)
    self.maxMemoryLimit = self.physicalMemory / 2;
  else
    self.maxMemoryLimit = self.physicalMemory * 2 / 3;
  if (self.maxMemory > self.maxMemoryLimit)
  {
    DDLogError(@"Maximum memory %d greater than maximum memory limit %d", self.maxMemory, self.maxMemoryLimit);
    self.maxMemory = self.maxMemoryLimit;
  }
  return self;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.title = @"Maximum memory";
  self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                         target:self
                                                                                         action:@selector(cancel:)] autorelease];
  self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(done:)] autorelease];

  // We set this because of TableViewSliderCell - see the class docs for details
  if ([UIDevice systemVersionMajor] >= 9)
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
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
    case PhysicalMemorySection:
      return MaxPhysicalMemorySectionItem;
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
    case MaxMemorySection:
      return @"WARNING: Setting this to a high value may cause the app to crash!!!\n\nIn an attempt to minimize this danger, the upper limit of the slider has been set to a fraction of the amount of memory that your device has. Read more about this setting under 'Help > Players & Profiles > Maximum memory'.";
    case PhysicalMemorySection:
      return @"This is the amount of memory that your device has.";
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
    case MaxMemorySection:
    {
      cell = [TableViewCellFactory cellWithType:SliderWithValueLabelCellType tableView:tableView];
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      sliderCell.descriptionLabel.text = @"Maximum memory (MB)";
      sliderCell.slider.minimumValue = fuegoMaxMemoryMinimum;
      sliderCell.slider.maximumValue = self.maxMemoryLimit;
      sliderCell.value = self.maxMemory;
      break;
    }
    case PhysicalMemorySection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Physical memory (MB)";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.physicalMemory];
      break;
    }
    default:
    {
      assert(0);
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
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
    case MaxMemorySection:
    {
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

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user did select a value.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  TableViewSliderCell* sliderCell = [self sliderCell];
  if (sliderCell.value > self.maxMemory)
  {
    NSString* formatString = @"You have increased the maximum amount of memory that the computer is allowed to use for its calculations.\n\nThe previous value was %d MB, the new value is %d MB.\n\nAre you sure you want to do this?";
    NSString* messageString = [NSString stringWithFormat:formatString, self.maxMemory, sliderCell.value];

    void (^yesActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
    {
      self.maxMemory = [self sliderCell].value;
      [self.delegate didEndEditing:self didCancel:false];
    };

    [self presentYesNoAlertWithTitle:@"Please confirm"
                             message:messageString
                          yesHandler:yesActionBlock
                           noHandler:nil];
  }
  else
  {
    self.maxMemory = sliderCell.value;
    [self.delegate didEndEditing:self didCancel:false];
  }
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled selecting a value.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate didEndEditing:self didCancel:true];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (TableViewSliderCell*) sliderCell
{
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:MaxMemoryItem inSection:MaxMemorySection];
  UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
  return (TableViewSliderCell*)cell;
}

@end
