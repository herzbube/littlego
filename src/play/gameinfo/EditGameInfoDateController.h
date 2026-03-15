// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
@class EditGameInfoDateController;
@class GoGameInfoRound;


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoDateControllerDelegate protocol must be implemented
/// by the delegate of EditGameInfoDateController.
// -----------------------------------------------------------------------------
@protocol EditGameInfoDateControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditGameInfoDateController in response to
/// this method invocation.
///
/// If @a didChangeDateInformation is true, the user has changed the date value.
/// The new values are written back to the
/// EditGameInfoDateController object's property @a dateComponents. If
/// @a didChangeDateInformation is false, the user has cancelled the editing
/// process, or completed it without actually changing any values.
- (void) editGameInfoDateControllerDidEndEditing:(EditGameInfoDateController*)controller didChangeDateInformation:(bool)didChangeDateInformation;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoDateController class is responsible for displaying
/// a view that lets the user edit a single date stored in a GoGameInfoDates
/// object.
///
/// EditGameInfoDateController expects to be presented modally or in a popup
/// by a navigation controller. EditGameInfoDateController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditGameInfoDateController : UITableViewController
{
}

+ (EditGameInfoDateController*) controllerWithDateComponents:(NSDateComponents*)dateComponents
                                                    delegate:(id<EditGameInfoDateControllerDelegate>)delegate;

@property(nonatomic, assign) id<EditGameInfoDateControllerDelegate> delegate;
/// @brief The date information data to be edited.
@property(nonatomic, assign) NSDateComponents* dateComponents;
/// @brief A context object that can be set by the client to identify the
/// context or purpose that an instance of EditGameInfoDateController was
/// created for.
///
/// If a delegate handles more than one type of EditGameInfoDateController, the
/// context object is a convenient method how the delegate can distinguish
/// between them.
@property(nonatomic, retain) id context;

@end
