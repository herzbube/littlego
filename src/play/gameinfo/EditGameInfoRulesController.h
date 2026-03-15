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
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class EditGameInfoRulesController;
@class GoGameInfoRules;


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRulesControllerDelegate protocol must be implemented
/// by the delegate of EditGameInfoRulesController.
// -----------------------------------------------------------------------------
@protocol EditGameInfoRulesControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditGameInfoRulesController in response to
/// this method invocation.
///
/// If @a didChangeGameInfoRules is true, the user has changed the game info
/// rules. The new game info rules are written back to the
/// EditGameInfoRulesController object's property @a gameInfoRules. If
/// @a didChangeGameInfoRules is false, the user has cancelled the editing
/// process, or completed it without actually changing the game info rules.
- (void) editGameInfoRulesControllerDidEndEditing:(EditGameInfoRulesController*)controller didChangeGameInfoRules:(bool)didChangeGameInfoRules;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRulesController class is responsible for displaying
/// a view that lets the user edit game info rules, consisting of either a
/// pre-defined rule, or a string describing a custom rule.
///
/// Editing game info rules cannot be handled by ItemPickerController
/// because it requires the user to edit two items:
/// - A list of possible rules
/// - A string
///
/// EditGameInfoRulesController expects to be presented modally or in a popup
/// by a navigation controller. EditGameInfoRulesController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditGameInfoRulesController : UIViewController <ItemPickerDelegate>
{
}

+ (EditGameInfoRulesController*) controllerWithGameInfoRules:(GoGameInfoRules*)gameInfoRules
                                                             delegate:(id<EditGameInfoRulesControllerDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user has finished
/// editing the game info rules.
@property(nonatomic, assign) id<EditGameInfoRulesControllerDelegate> delegate;
/// @brief The game info rules to be edited.
@property(nonatomic, assign) GoGameInfoRules* gameInfoRules;

@end
