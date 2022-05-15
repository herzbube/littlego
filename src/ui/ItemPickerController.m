// -----------------------------------------------------------------------------
// Copyright 2011-2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "AutoLayoutUtility.h"
#import "PlaceholderView.h"
#import "StaticTableView.h"
#import "TableViewCellFactory.h"
#import "UiUtilities.h"
#import "../utility/UIImageAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ItemPickerController.
// -----------------------------------------------------------------------------
@interface ItemPickerController()
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) NSString* screenTitle;
@property(nonatomic, assign, readwrite) int indexOfDefaultItem;
//@}
@property(nonatomic, retain) PlaceholderView* placeholderView;
@property(nonatomic, retain) StaticTableView* staticTableView;
@property(nonatomic, retain) UITableView* regularTableView;
@end


@implementation ItemPickerController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an ItemPickerController instance of
/// grouped style that is used to pick an item from @a itemList.
///
/// @a indexOfDefaultItem is the index of the item that is selected by default
/// when the selection process begins. Can be -1 to indicate no default
/// selection. @a indexOfDefaultItem must match an array element in @a itemList,
/// otherwise @e indexOfDefaultItem will be set to -1 and no item will be
/// selected. Any negative value that is not -1 will be changed to -1.
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
    controller.indexOfSelectedItem = indexOfDefaultItem;
    // indexOfSelectedItem property setter adapts invalid values, let's take
    // the value from there to avoid duplicated logic
    controller.indexOfDefaultItem = controller.indexOfSelectedItem;
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
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.itemPickerControllerMode = ItemPickerControllerModeModal;
  self.useScrollingTableView = true;
  self.context = nil;
  self.screenTitle = nil;
  self.notifyDelegateOnlyWhenSelectionChanges = false;
  self.footerTitle = nil;
  self.placeholderText = nil;
  self.delegate = nil;
  self.displayCancelItem = false;
  self.indexOfDefaultItem = -1;
  self.indexOfSelectedItem = -1;
  self.itemList = nil;
  self.placeholderView = nil;
  self.staticTableView = nil;
  self.regularTableView = nil;
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
  self.placeholderText = nil;
  self.delegate = nil;
  self.itemList = nil;
  self.placeholderView = nil;
  self.staticTableView = nil;
  self.regularTableView = nil;
  [super dealloc];
}

#pragma mark - Property implementation

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setIndexOfSelectedItem:(int)indexOfSelectedItem
{
  if (indexOfSelectedItem == _indexOfSelectedItem)
    return;
  if (indexOfSelectedItem < -1 || indexOfSelectedItem + 1 > _itemList.count)
    indexOfSelectedItem = -1;

  int previousIndexOfSelectedItem = _indexOfSelectedItem;
  _indexOfSelectedItem = indexOfSelectedItem;

  if (self.isViewLoaded)
  {
    UITableView* tableView = [self itemPickerTableView];

    // Remove the checkmark from the previously selected cell
    if (previousIndexOfSelectedItem >= 0)
    {
      NSIndexPath* previousIndexPath = [NSIndexPath indexPathForRow:previousIndexOfSelectedItem inSection:0];
      UITableViewCell* previousCell = [tableView cellForRowAtIndexPath:previousIndexPath];
      if (previousCell.accessoryType == UITableViewCellAccessoryCheckmark)
        previousCell.accessoryType = UITableViewCellAccessoryNone;
    }

    // Add the checkmark to the newly selected cell
    if (indexOfSelectedItem)
    {
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:indexOfSelectedItem inSection:0];
      UITableViewCell* newCell = [tableView cellForRowAtIndexPath:indexPath];
      if (newCell.accessoryType == UITableViewCellAccessoryNone)
        newCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setItemList:(NSArray*)itemList
{
  if (itemList && _itemList && [itemList isEqualToArray:_itemList])
    return;

  if (_itemList)
  {
    [_itemList release];
    _itemList = nil;
  }

  if (itemList)
  {
    _itemList = itemList;
    [_itemList retain];

    if (_indexOfSelectedItem + 1 > _itemList.count)
      _indexOfSelectedItem = -1;
  }
  else
  {
    _indexOfSelectedItem = -1;
  }

  if (self.isViewLoaded)
  {
    UITableView* tableView = [self itemPickerTableView];
    [tableView reloadData];
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  [self setupViewContent];

  self.title = self.screenTitle;
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

#pragma mark - Private helpers for view setup

// -----------------------------------------------------------------------------
/// @brief Sets up the content of this controller's view.
// -----------------------------------------------------------------------------
- (void) setupViewContent
{
  if (0 == self.itemList.count)
  {
    self.placeholderView = [[[PlaceholderView alloc] initWithFrame:CGRectZero placeholderText:self.placeholderText] autorelease];
    [self.view addSubview:self.placeholderView];
    self.placeholderView.translatesAutoresizingMaskIntoConstraints = NO;
    [AutoLayoutUtility fillSuperview:self.view withSubview:self.placeholderView];
  }
  else
  {
    self.itemList = [self itemListWithUniformWidthImages];

    UIView* subview;
    if (self.useScrollingTableView)
    {
      self.regularTableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                            style:UITableViewStyleGrouped] autorelease];
      subview = self.regularTableView;
    }
    else
    {
      self.staticTableView = [[[StaticTableView alloc] initWithFrame:CGRectZero
                                                               style:UITableViewStyleGrouped] autorelease];
      subview = self.staticTableView;
    }

    [self.view addSubview:subview];
    subview.translatesAutoresizingMaskIntoConstraints = NO;
    [AutoLayoutUtility fillSuperview:self.view withSubview:subview];

    UITableView* tableView = [self itemPickerTableView];
    tableView.delegate = self;
    tableView.dataSource = self;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a new item list with item images that have a uniform width.
///
/// If the original item list does not contain any item images, or the item
/// images already have uniform width, then this method returns the original
/// item list.
// -----------------------------------------------------------------------------
- (NSArray*) itemListWithUniformWidthImages
{
  bool atLeastOneItemHasImage = false;
  bool atLeastOneImageNeedsPadding = false;
  CGFloat widthOfWidestImage = 0.0f;

  for (id item in self.itemList)
  {
    UIImage* itemImage = [self itemImageIfAny:item];
    if (! itemImage)
      continue;

    if (itemImage.size.width != widthOfWidestImage)
    {
      if (atLeastOneItemHasImage)
        atLeastOneImageNeedsPadding = true;
      else
        atLeastOneItemHasImage = true;

      if (itemImage.size.width > widthOfWidestImage)
        widthOfWidestImage = itemImage.size.width;
    }
  }

  if (! atLeastOneImageNeedsPadding)
    return self.itemList;

  NSMutableArray* newItemList = [NSMutableArray array];

  for (id item in self.itemList)
  {
    UIImage* itemImage = [self itemImageIfAny:item];
    if (itemImage)
    {
      UIImage* paddedItemImage = [itemImage imageByPaddingToWidth:widthOfWidestImage];

      NSArray* itemArray = item;
      NSArray* newItem = @[itemArray.firstObject, paddedItemImage];

      [newItemList addObject:newItem];
    }
    else
    {
      [newItemList addObject:item];
    }
  }

  return newItemList;
}

// -----------------------------------------------------------------------------
/// @brief Examines @a item whether it contains an image. If yes, returns the
/// item image. If no, returns @e nil.
// -----------------------------------------------------------------------------
- (UIImage*) itemImageIfAny:(id)item
{
  if ([item isKindOfClass:[NSString class]])
    return nil;
  NSArray* itemArray = item;
  UIImage* itemImage = itemArray.lastObject;
  return itemImage;
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  if (self.displayCancelItem)
    return 2;
  else
    return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  if (section == 0)
    return self.itemList.count;
  else
    return 1;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (section == 0)
    return self.footerTitle;
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  if (indexPath.section == 0)
  {
    UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];

    NSString* itemText = nil;
    UIImage* itemImage = nil;
    id item = [self.itemList objectAtIndex:indexPath.row];
    if ([item isKindOfClass:[NSString class]])
    {
      itemText = item;
    }
    else
    {
      NSArray* itemArray = item;
      itemText = itemArray.firstObject;
      itemImage = itemArray.lastObject;
    }

    cell.textLabel.text = itemText;
    cell.imageView.image = itemImage;

    if (indexPath.row == self.indexOfSelectedItem)
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
    else
      cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
  }
  else
  {
    UITableViewCell* cell = [TableViewCellFactory cellWithType:ActionTextCellType tableView:tableView];
    cell.textLabel.text = @"Cancel";
    return cell;
  }
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

  if (indexPath.section == 0)
  {
    int indexOfPreviousSelectedItem = self.indexOfSelectedItem;
    bool selectionDidChange = (indexOfNewSelectedItem != indexOfPreviousSelectedItem);

    if (selectionDidChange)
    {
      // Setter updates the table view
      self.indexOfSelectedItem = indexOfNewSelectedItem;

      if (self.notifyDelegateOnlyWhenSelectionChanges)
      {
        // ItemPickerController was configured not to notify the delegate
      }
      else
      {
        SEL selector = @selector(itemPickerControllerSelectionDidChange:);
        if ([self.delegate respondsToSelector:selector])
          [self.delegate itemPickerControllerSelectionDidChange:self];
      }
    }

    if (ItemPickerControllerModeModal == self.itemPickerControllerMode)
    {
      self.navigationItem.rightBarButtonItem.enabled = [self isSelectionValid];
    }
    else
    {
      if ([self isSelectionValid])
      {
        if (self.notifyDelegateOnlyWhenSelectionChanges && ! selectionDidChange)
        {
          // ItemPickerController was configured not to notify the delegate
        }
        else
        {
          [self.delegate itemPickerController:self didMakeSelection:true];
        }
      }
    }
  }
  else
  {
    [self.delegate itemPickerController:self didMakeSelection:false];
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
///
/// This method is important when ItemPickerController is displayed with no
/// default selection. In theory, the user might later also somehow be able to
/// return to the state where no item is selected.
// -----------------------------------------------------------------------------
- (bool) isSelectionValid
{
  if (self.indexOfSelectedItem < 0 || self.indexOfSelectedItem >= self.itemList.count)
    return false;
  else
    return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns the table view object that displays the items to pick.
///
/// Implementation note: Don't use a simple name like "tableView" in order to
/// avoid potential naming clashes with future UIKit properties.
// -----------------------------------------------------------------------------
- (UITableView*) itemPickerTableView
{
  if (self.useScrollingTableView)
    return self.regularTableView;
  else
    return self.staticTableView.tableView;
}

@end
