// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
@class EditTextController;


// -----------------------------------------------------------------------------
/// @brief The EditTextDelegate protocol must be implemented by the delegate
/// of EditTextController.
// -----------------------------------------------------------------------------
@protocol EditTextDelegate
/// @brief This method is invoked when the user has finished editing the text.
///
/// @a didCancel is true if the user has cancelled editing. @a didCancel is
/// false if the user has confirmed editing.
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
@end


// -----------------------------------------------------------------------------
/// @brief The EditTextController class is responsible for displaying an
/// "Edit Text" view that allows the user to edit a text string.
///
/// The "Edit Text" view is a generic UITableView whose input elements are
/// created dynamically by EditTextController.
///
/// EditTextController expects to be displayed modally by a navigation
/// controller. For this reason it populates its own navigation item with
/// controls that are then expected to be displayed in the navigation bar of
/// the parent navigation controller.
///
/// EditTextController expects to be configured with a delegate that can be
/// informed when the user has finished editing the text. For this to work, the
/// delegate must implement the protocol EditTextDelegate.
// -----------------------------------------------------------------------------
@interface EditTextController : UITableViewController <UITextFieldDelegate>
{
@private
  /// @brief Private reference to the text field that does the actual editing.
  UITextField* m_textField;
}

+ (EditTextController*) controllerWithText:(NSString*)text title:(NSString*)title delegate:(id<EditTextDelegate>)delegate;

/// @brief The title to be displayed in the navigation item.
@property(retain) NSString* title;
/// @brief This is the delegate that will be informed when the user has
/// finished editing the text.
@property(nonatomic, assign) id<EditTextDelegate> delegate;
/// @brief When editing begins, this contains the default text. When editing
/// finishes with the user tapping "done", this contains the text entered by the
/// user.
@property(retain) NSString* text;
/// @brief Placeholder string that should be displayed instead of an empty
/// text.
@property(retain) NSString* placeholder;
/// @brief True if EditTextController should accept an empty text as valid
/// input.
///
/// If this property is false and the user clears the entire text, the user
/// @e must cancel editing to leave the view.
@property(assign) bool acceptEmptyText;
/// @brief True if the user has actually made changes to the text. False if the
/// user has cancelled editing, or if there were no changes.
///
/// This property is set after the user has finished editing the text. It is
/// useful if the delegate needs to take special action if the user made actual
/// changes.
@property(assign) bool textHasChanged;

@end
