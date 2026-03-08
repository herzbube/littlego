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
#import "../../ui/EditTextController.h"

// Forward declarations
@class EditGameInfoRoundController;
@class GoGameInfoRound;


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRoundControllerDelegate protocol must be implemented
/// by the delegate of EditGameInfoRoundController.
// -----------------------------------------------------------------------------
@protocol EditGameInfoRoundControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditGameInfoRoundController in response to
/// this method invocation.
///
/// If @a didChangeRoundInformation is true, the user has changed the values in
/// the GoGameInfoRound object. The new values are written back to the
/// EditGameInfoRoundController object's property @a goGameInfoRound. If
/// @a didChangeRoundInformation is false, the user has cancelled the editing
/// process, or completed it without actually changing any values.
- (void) editGameInfoRoundControllerDidEndEditing:(EditGameInfoRoundController*)controller didChangeRoundInformation:(bool)didChangeRoundInformation;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRoundController class is responsible for displaying
/// a view that lets the user edit the values stored in a GoGameInfoRound
/// object.
///
/// EditGameInfoRoundController expects to be presented modally or in a popup
/// by a navigation controller. EditGameInfoRoundController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditGameInfoRoundController : UITableViewController <EditTextDelegate>
{
}

+ (EditGameInfoRoundController*) controllerWithGameInfoRound:(GoGameInfoRound*)gameInfoRound
                                                    delegate:(id<EditGameInfoRoundControllerDelegate>)delegate;

@property(nonatomic, assign) id<EditGameInfoRoundControllerDelegate> delegate;
/// @brief The round information data to be edited.
@property(nonatomic, assign) GoGameInfoRound* gameInfoRound;

@end
