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
@class EditGameResultController;
@class GoGameResult;


// -----------------------------------------------------------------------------
/// @brief The EditGameResultDelegate protocol must be implemented by the
/// delegate of EditGameResultController.
// -----------------------------------------------------------------------------
@protocol EditGameResultDelegate <NSObject>
/// @brief This method is invoked whenever the data of @a gameResult changes
/// in the view presented by @a controller.
- (void) editGameResultController:(EditGameResultController*)controller gameResultDidChange:(GoGameResult*)gameResult;
/// @brief This method is invoked when editing of the data of @a gameResult
/// did finish and @a controller is being dismissed.
///
/// This method is invoked as the first step of dealloc() of @a controller, the
/// delegate therefore must not do anything substantial with @a controller
/// anymore.
- (void) editGameResultController:(EditGameResultController*)controller gameResultEditingDidFinish:(GoGameResult*)gameResult;
@end


// -----------------------------------------------------------------------------
/// @brief The EditGameResultController class is responsible for displaying
/// a view that lets the user edit the values stored in a GoGameResult object.
///
/// EditGameResultController expects to be presented by pushing it on top of a
/// navigation controller. EditGameResultController does not populate its
/// navigation item with any controls.
// -----------------------------------------------------------------------------
@interface EditGameResultController : UITableViewController <ItemPickerDelegate, EditTextDelegate>
{
}

+ (EditGameResultController*) controllerWithGameResult:(GoGameResult*)gameResult
                                              delegate:(id<EditGameResultDelegate>)delegate;

@property(nonatomic, assign) id<EditGameResultDelegate> delegate;

@end
