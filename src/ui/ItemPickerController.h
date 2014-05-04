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


// Forward declarations
@class ItemPickerController;


// -----------------------------------------------------------------------------
/// @brief The ItemPickerDelegate protocol must be implemented by the delegate
/// of ItemPickerController.
// -----------------------------------------------------------------------------
@protocol ItemPickerDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller. The implementation is responsible for dismissing the modal
/// @a controller.
///
/// If @a didMakeSelection is true, the user has made a selection; the index of
/// the selected item can be queried from the ItemPickerController object's
/// property @a indexOfSelectedItem. If @a didMakeSelection is false, the user
/// has cancelled the selection.
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
@end


// -----------------------------------------------------------------------------
/// @brief The ItemPickerController class is responsible for displaying a
/// "Pick Item" view that lets the user pick an item from a list of items.
/// ItemPickerController is intended as an alternative to UIPickerView if
/// UIPickerView's style seems too "heavy-weight".
///
/// The "Pick Item" view is a generic UITableView of grouped style whose input
/// elements are created dynamically by ItemPickerController. The elements
/// are
/// - A number of table view cells that allow the user to pick one of them
/// - A "cancel" button used to end the selection process and notify the
///   delegate that no item has been picked. This button is placed in the
///   navigation item of ItemPickerController.
/// - A "done" button used to end the selection process and notify the delegate
///   that an item has been picked. This button is placed in the navigation
///   item of ItemPickerController.
///
/// ItemPickerController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// ItemPickerController expects to be configured with a delegate that can be
/// notified when the user has finished picking an item. For this to work, the
/// delegate must implement the protocol ItemPickerDelegate.
// -----------------------------------------------------------------------------
@interface ItemPickerController : UITableViewController
{
}

+ (ItemPickerController*) controllerWithItemList:(NSArray*)itemList
                                           title:(NSString*)title
                              indexOfDefaultItem:(int)indexOfDefaultItem
                                        delegate:(id<ItemPickerDelegate>)delegate;

/// @brief A context object that can be set by the client to identify the
/// context or purpose that an instance of ItemPickerController was created for.
@property(nonatomic, retain) id context;
/// @brief The title to be displayed in the navigation item.
@property(nonatomic, retain, readonly) NSString* title;
/// @brief The string to be displayed as the title of the table view's footer.
@property(nonatomic, retain) NSString* footerTitle;
/// @brief This is the delegate that will be informed when the user has finished
/// picking an item.
@property(nonatomic, assign) id<ItemPickerDelegate> delegate;
/// @brief This contains the index of the item that is selected by default when
/// the selection process begins. Can be -1 to indicate no default selection.
@property(nonatomic, assign, readonly) int indexOfDefaultItem;
/// @brief When the selection process finishes with the user tapping "done",
/// this contains the index of the item picked by the user.
@property(nonatomic, assign, readonly) int indexOfSelectedItem;
/// @brief Array of NSString* objects with texts that should be displayed as the
/// items available for selection. Items appear in the GUI in the same order as
/// objects in this array.
@property(nonatomic, retain, readonly) NSArray* itemList;

@end
