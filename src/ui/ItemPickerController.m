// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "ItemPickerController.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ItemPickerController.
// -----------------------------------------------------------------------------
@interface ItemPickerController()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* screenTitle;
@property(nonatomic, assign, readwrite) int indexOfDefaultItem;
@property(nonatomic, assign, readwrite) int indexOfSelectedItem;
@property(nonatomic, retain, readwrite) NSArray* itemList;
//@}
@end


@implementation ItemPickerController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an ItemPickerController instance of
/// grouped style that is used to pick an item from @a itemList.
///
/// @a indexOfDefaultItem is the index of the item that is selected by default
/// when the selection process begins. Can be -1 to indicate no default
/// selection.
// -----------------------------------------------------------------------------
+ (ItemPickerController*) controllerWithItemList:(NSArray*)itemList
                                     screenTitle:(NSString*)screenTitle
                              indexOfDefaultItem:(int)indexOfDefaultItem
                                        delegate:(id<ItemPickerDelegate>)delegate
{
  ItemPickerController* controller = [[ItemPickerController alloc] init];
  if (controller)
  {
    [controller autorelease];
    controller.itemList = itemList;
    controller.screenTitle = screenTitle;
    controller.footerTitle = nil;
    controller.indexOfDefaultItem = indexOfDefaultItem;
    controller.indexOfSelectedItem = indexOfDefaultItem;
    controller.delegate = delegate;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an ItemPickerController object.
///
/// @note This is the designated initializer of ItemPickerController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UITableViewController)
  self = [super initWithStyle:UITableViewStyleGrouped];
  if (! self)
    return nil;
  self.itemPickerControllerMode = ItemPickerControllerModeModal;
  self.context = nil;
  self.screenTitle = nil;
  self.footerTitle = nil;
  self.delegate = nil;
  self.indexOfDefaultItem = -1;
  self.indexOfSelectedItem = -1;
  self.itemList = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ItemPickerController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.context = nil;
  self.screenTitle = nil;
  self.footerTitle = nil;
  self.delegate = nil;
  self.itemList = nil;
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
  if (ItemPickerControllerModeModal == self.itemPickerControllerMode)
  {
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(cancel:)] autorelease];
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                            target:self
                                                                                            action:@selector(done:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
  }
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
  return self.itemList.count;
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
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.textLabel.text = [self.itemList objectAtIndex:indexPath.row];
  if (indexPath.row == self.indexOfSelectedItem)
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  else
    cell.accessoryType = UITableViewCellAccessoryNone;
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  // Deselect the row that was just selected
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this controller was not made to handle more than pow(2, 31)
  // items.
  int indexOfNewSelectedItem = (int)indexPath.row;
  // Do nothing if the selection did not change
  if (self.indexOfSelectedItem == indexOfNewSelectedItem)
    return;
  // Remove the checkmark from the previously selected cell
  NSIndexPath* previousIndexPath = [NSIndexPath indexPathForRow:self.indexOfSelectedItem inSection:0];
  UITableViewCell* previousCell = [tableView cellForRowAtIndexPath:previousIndexPath];
  if (previousCell.accessoryType == UITableViewCellAccessoryCheckmark)
    previousCell.accessoryType = UITableViewCellAccessoryNone;
  // Add the checkmark to the newly selected cell
  UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
  if (newCell.accessoryType == UITableViewCellAccessoryNone)
    newCell.accessoryType = UITableViewCellAccessoryCheckmark;
  // Last but not least, remember the new selection
  self.indexOfSelectedItem = indexOfNewSelectedItem;

  if (ItemPickerControllerModeModal == self.itemPickerControllerMode)
  {
    self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
  }
  else
  {
    if ([self isSelectionValid])
      [self.delegate itemPickerController:self didMakeSelection:true];
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has finished picking an item.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  [self.delegate itemPickerController:self didMakeSelection:true];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user has cancelled picking an item.
// -----------------------------------------------------------------------------
- (void) cancel:(id)sender
{
  [self.delegate itemPickerController:self didMakeSelection:false];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the currently selected item is valid.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  if (self.indexOfSelectedItem < 0 || self.indexOfSelectedItem >= self.itemList.count)
    return false;
  else
    return true;
}

@end
