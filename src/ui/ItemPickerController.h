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
/// different item. If @a controller is presented on top of a navigation stack
/// the delegate will typically not dismiss @a controller because the user can
/// do so by tapping the back button. However, if @a controller is presented in
/// a popover the delegate is responsible for dismissing @a controller.
///
/// If @a didMakeSelection is true, the user has made a selection; the index of
/// the selected item can be queried from the ItemPickerController object's
/// property @a indexOfSelectedItem. If @a didMakeSelection is false, the user
/// has cancelled the selection, either by tapping the "cancel" button
/// (in mode #ItemPickerControllerModeModal) or the "cancel" item (in both
/// modes).
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
/// - Modal mode: In this mode, ItemPickerController expects to be presented
///   modally by a navigation controller. ItemPickerController populates its
///   own navigation item with controls that are then expected to be displayed
///   in the navigation bar of the parent navigation controller.
/// - Non-modal mode: In this mode, ItemPickerController expects to be presented
///   in some non-modal way (e.g. pushed on top of a navigation stack, or
///   displayed in a popover). ItemPickerController does not create any
///   additional buttons, it is the caller's responsibility to setup an
///   appropriate way to dismiss ItemPickerController (e.g. create a back button
///   to be displayed in the navigation bar, or let the delegate dismiss
///   ItemPickerController when the user selects an item).
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
@interface ItemPickerController : UIViewController <UITableViewDataSource, UITableViewDelegate>
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
/// @brief The string to be displayed as the placeholder when there are no items
/// to pick.
@property(nonatomic, retain) NSString* placeholderText;
/// @brief This is the delegate that will be informed when the user has finished
/// picking an item.
@property(nonatomic, assign) id<ItemPickerDelegate> delegate;
/// @brief True if ItemPickerController should notify the delegate only when the
/// user selects a different item than the currently selected one. False if
/// ItemPickerController should notify the delegate even when the user selects
/// the same item again. The default is false.
///
/// When ItemPickerController is presented in a popover (i.e. in non-modal mode)
/// and the device is an iPad, then the user can tap outside the popover frame
/// to dismiss the popover without a change. However when the device is not an
/// iPad the user cannot tap outside the popover frame - in that case the user
/// can select the item that is already selected by default, and the delegate
/// is still notified and can dismiss ItemPickerController without a change.
/// If this notification is not desired for some reason, this property can be
/// set to false.
@property(nonatomic, assign) bool notifyDelegateOnlyWhenSelectionChanges;
/// @brief True if ItemPickerController should display a "cancel" item alongside
/// the regular items to pick. False if ItemPickerController should not display
/// a "cancel" item. The default is false.
///
/// Setting this property to true can be useful in mode
/// #ItemPickerControllerModeNonModal to give the user a clear way out of the
/// selection process when no other screen elements exist to do so (e.g. when
/// ItemPickerController is presented in a popover on iPhone devices). Setting
/// this property to true does not make sense in mode
/// #ItemPickerControllerModeModal because ItemPickerController already creates
/// a "cancel" button in that mode.
///
/// When the user taps the "cancel" item ItemPickerController notifies the
/// delegate with the @e didMakeSelection parameter set to false.
@property(nonatomic, assign) bool displayCancelItem;
/// @brief This contains the index of the item that is selected by default when
/// the selection process begins. Can be -1 to indicate no default selection.
@property(nonatomic, assign, readonly) int indexOfDefaultItem;
/// @brief When the selection process finishes with the user tapping "done", or
/// when the delegate dismisses ItemPickerController, this property contains
/// the index of the item picked by the user.
///
/// Changing this property causes ItemPickerController to update its display.
/// The new index position must match an array element in @e itemList, otherwise
/// @e indexOfSelectedItem will be set to -1 and no item will be selected. Any
/// negative value that is not -1 will be changed to -1. Value -1 means that
/// no item is selected.
@property(nonatomic, assign) int indexOfSelectedItem;
/// @brief Array with items available for selection. Items appear in the GUI in
/// the same order as objects in this array.
///
/// ItemPickerController supports two kinds of array elements:
/// - NSString object. ItemPickerController uses the string to represent the
///   item to pick.
/// - An array containing an NSString and an UIImage object.
///   ItemPickerController uses both the string and the image to represent the
///   item to pick.
///
/// If item images are present but not of a uniform width, the images are padded
/// to the widest item image so that the item strings appear left-aligned.
///
/// Changing this property causes ItemPickerController to update its display.
/// If possible ItemPickerController retains the previously selected item
/// (according to the index position in the item list). However, if the new item
/// list is smaller than the previous one ItemPickerController discards the
/// selection (@e indexOfSelectedItem will become -1).
@property(nonatomic, retain) NSArray* itemList;

@end
