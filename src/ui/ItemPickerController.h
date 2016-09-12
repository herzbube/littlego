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


// Forward declarations
@class ItemPickerController;


/// @brief Enumerates the modes that ItemPickerController can work in.
enum ItemPickerControllerMode
{
  /// @brief ItemPickerController expects to be presented modally. It creates
  /// self-managed buttons for cancelling or accepting the selection.
  ItemPickerControllerModeModal,
  /// @brief ItemPickerController expects to be presented non-modally. It
  /// creates no buttons of its own.
  ItemPickerControllerModeNonModal
};


// -----------------------------------------------------------------------------
/// @brief The ItemPickerDelegate protocol must be implemented by the delegate
/// of ItemPickerController.
// -----------------------------------------------------------------------------
@protocol ItemPickerDelegate
/// @brief This method is invoked when the user has finished working with
/// @a controller.
///
/// In modal mode, this method is invoked because the user tapped either the
/// "cancel" or the "done" button. The delegate is responsible for dismissing
/// @a controller.
///
/// In non-modal mode this method is invoked every time the user selects a
/// different item. Typically the delegate will not dismiss @a controller
/// because the user can do so by tapping the back button.
///
/// If @a didMakeSelection is true, the user has made a selection; the index of
/// the selected item can be queried from the ItemPickerController object's
/// property @a indexOfSelectedItem. If @a didMakeSelection is false, the user
/// has cancelled the selection (only available in modal mode).
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
@end


// -----------------------------------------------------------------------------
/// @brief The ItemPickerController class is responsible for displaying a
/// "Pick Item" view that lets the user pick an item from a list of items.
/// ItemPickerController is intended as an alternative to UIPickerView if
/// UIPickerView's style seems too "heavy-weight".
///
/// The "Pick Item" view is a generic UITableView of grouped style whose cells
/// are created dynamically by ItemPickerController according to the list of
/// items with which it is initialized.
///
/// ItemPickerController can be run in one of two modes:
/// - Modal mode: In this mode, ItemPickerController expects to be displayed
///   modally by a navigation controller. ItemPickerController populates its
///   own navigation item with controls that are then expected to be displayed
///   in the navigation bar of the parent navigation controller.
/// - Non-modal mode: In this mode, ItemPickerController expects to be
///   pushed on top of a navigation stack. ItemPickerController does not create
///   any additional buttons, it is the caller's responsibility to setup a
///   back button.
///
/// The controls created in modal mode are:
/// - A "cancel" button used to end the selection process and notify the
///   delegate that no item has been picked.
/// - A "done" button used to end the selection process and notify the delegate
///   that an item has been picked.
///
/// ItemPickerController expects to be configured with a delegate that can be
/// notified when the user has finished picking an item. For this to work, the
/// delegate must implement the protocol ItemPickerDelegate.
// -----------------------------------------------------------------------------
@interface ItemPickerController : UITableViewController
{
}

+ (ItemPickerController*) controllerWithItemList:(NSArray*)itemList
                                     screenTitle:(NSString*)screenTitle
                              indexOfDefaultItem:(int)indexOfDefaultItem
                                        delegate:(id<ItemPickerDelegate>)delegate;

/// @brief The mode that ItemPickerController is supposed to work in. The
/// default is ItemPickerControllerModeModal. The value of this property should
/// not be changed after ItemPickerController's view has been loaded.
@property(nonatomic, assign) enum ItemPickerControllerMode itemPickerControllerMode;
/// @brief A context object that can be set by the client to identify the
/// context or purpose that an instance of ItemPickerController was created for.
///
/// If a delegate handles more than one type of ItemPickerController, the
/// context object is a convenient method how the delegate can distinguish
/// between them.
@property(nonatomic, retain) id context;
/// @brief The screen title to be displayed in the navigation item.
@property(nonatomic, retain, readonly) NSString* screenTitle;
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
