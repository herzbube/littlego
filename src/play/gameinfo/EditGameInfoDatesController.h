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


// Project includes
#import "EditGameInfoDateController.h"

// Forward declarations
@class EditGameInfoDatesController;
@class GoGameInfoDates;


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoDatesControllerDelegate protocol must be implemented
/// by the delegate of EditGameInfoDatesController.
// -----------------------------------------------------------------------------
@protocol EditGameInfoDatesControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditGameInfoDatesController in response to
/// this method invocation.
///
/// If @a didChangeDatesInformation is true, the user has changed the values in
/// the GoGameInfoDates object. The new values are written back to the
/// EditGameInfoDatesController object's property @a goGameInfoDates. If
/// @a didChangeDatesInformation is false, the user has cancelled the editing
/// process, or completed it without actually changing any values.
- (void) editGameInfoDatesControllerDidEndEditing:(EditGameInfoDatesController*)controller didChangeDatesInformation:(bool)didChangeDatesInformation;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoDatesController class is responsible for displaying
/// a view that lets the user edit the values stored in a GoGameInfoDates
/// object.
///
/// EditGameInfoDatesController expects to be presented modally or in a popup
/// by a navigation controller. EditGameInfoDatesController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditGameInfoDatesController : UITableViewController <EditGameInfoDateControllerDelegate>
{
}

+ (EditGameInfoDatesController*) controllerWithGameInfoDates:(GoGameInfoDates*)gameInfoDates
                                                    delegate:(id<EditGameInfoDatesControllerDelegate>)delegate;

@property(nonatomic, assign) id<EditGameInfoDatesControllerDelegate> delegate;
/// @brief The dates information data to be edited.
@property(nonatomic, assign) GoGameInfoDates* gameInfoDates;

@end
