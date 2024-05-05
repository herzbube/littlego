// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class EditNodeDescriptionController;


// -----------------------------------------------------------------------------
/// @brief The EditNodeDescriptionControllerDelegate protocol must be
/// implemented by the delegate of EditNodeDescriptionController.
// -----------------------------------------------------------------------------
@protocol EditNodeDescriptionControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss @a controller in response to this method
/// invocation.
///
/// If @a didChangeDescriptions is true, the user has changed either the short
/// description, or the long description, or both. The new description texts
/// are written back to the EditNodeDescriptionController object's properties
/// @a shortDescription and @a longDescription. If @a didChangeDescriptions is
/// false, the user has cancelled the editing process, or completed it without
/// actually changing the short description or long description.
- (void) editNodeDescriptionControllerDidEndEditing:(EditNodeDescriptionController*)controller didChangeDescriptions:(bool)didChangeDescriptions;
@end


// -----------------------------------------------------------------------------
/// @brief The EditNodeDescriptionController class is responsible for displaying
/// a view that lets the user edit the short and long descriptions of a node.
///
/// Editing the node description cannot be handled by EditTextController
/// because it requires the user to edit two texts.
/// - The short description of a node. A UITextField is used to edit this text
///   because the short description should be of limited length and not contain
///   any newlines.
/// - The long description of a node. A UITextView is used to edit this text
///   because the long description can be of arbitrary length and can also
///   contain newlines.
///
/// EditNodeDescriptionController expects to be presented modally or in a popup
/// by a navigation controller. EditNodeDescriptionController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditNodeDescriptionController : UIViewController
{
}

+ (EditNodeDescriptionController*) controllerWithShortDescription:(NSString*)shortDescription
                                                  longDescription:(NSString*)longDescription
                                                         delegate:(id<EditNodeDescriptionControllerDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user has finished
/// editing the short and long description texts.
@property(nonatomic, assign) id<EditNodeDescriptionControllerDelegate> delegate;
/// @brief A short text without newlines, describing a node. Is @e nil if no
/// short description is available.
///
/// EditNodeDescriptionController does not take any measures to prevent the
/// value to contain newlines. EditNodeDescriptionController expects the initial
/// value to come from a GoNodeAnnotation, and the result of the editing process
/// to be applied to a GoNodeAnnotation. GoNodeAnnotation is expected to remove
/// any newlines from the short description.
@property(nonatomic, retain, readonly) NSString* shortDescription;
/// @brief A long text which may include newlines, describing in detail a
/// node. Is @e nil if no long description is available.
@property(nonatomic, retain, readonly) NSString* longDescription;

@end
