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
#import "../../ui/ItemPickerController.h"

// Forward declarations
@class EditGameInfoRankController;
@class GoGameInfoRank;


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRankControllerDelegate protocol must be implemented
/// by the delegate of EditGameInfoRankController.
// -----------------------------------------------------------------------------
@protocol EditGameInfoRankControllerDelegate
/// @brief Notifies the delegate that the editing session has ended.
///
/// The delegate should dismiss the EditGameInfoRankController in response to
/// this method invocation.
///
/// If @a didChangeRankInformation is true, the user has changed the values in
/// the GoGameInfoRank object. The new values are written back to the
/// EditGameInfoRankController object's property @a goGameInfoRank. If
/// @a didChangeRankInformation is false, the user has cancelled the editing
/// process, or completed it without actually changing any values.
- (void) editGameInfoRankControllerDidEndEditing:(EditGameInfoRankController*)controller didChangeRankInformation:(bool)didChangeRankInformation;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameInfoRankController class is responsible for displaying
/// a view that lets the user edit the values stored in a GoGameInfoRank
/// object.
///
/// EditGameInfoRankController expects to be presented modally or in a popup
/// by a navigation controller. EditGameInfoRankController populates its own
/// navigation item with controls that are then expected to be displayed in the
/// navigation bar of the parent navigation controller.
// -----------------------------------------------------------------------------
@interface EditGameInfoRankController : UITableViewController <ItemPickerDelegate, EditTextDelegate>
{
}

+ (EditGameInfoRankController*) controllerWithGameInfoRank:(GoGameInfoRank*)gameInfoRank
                                                  delegate:(id<EditGameInfoRankControllerDelegate>)delegate;

@property(nonatomic, assign) id<EditGameInfoRankControllerDelegate> delegate;
/// @brief The rank information data to be edited.
@property(nonatomic, assign) GoGameInfoRank* gameInfoRank;
/// @brief A context object that can be set by the client to identify the
/// context or purpose that an instance of EditGameInfoRankController was
/// created for.
///
/// If a delegate handles more than one type of EditGameInfoRankController, the
/// context object is a convenient method how the delegate can distinguish
/// between them.
@property(nonatomic, retain) id context;
/// @brief The screen title to be displayed in the navigation item.
@property(nonatomic, retain, retain) NSString* screenTitle;

@end
