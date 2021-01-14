// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfDisabledMessagesController.h"
#import "../ui/ItemPickerController.h"

// Forward declarations
@class SgfSyntaxCheckingLevelSettingsController;


// -----------------------------------------------------------------------------
/// @brief The SgfSyntaxCheckingLevelSettingsDelegate protocol must be
/// implemented by the delegate of SgfSyntaxCheckingLevelSettingsController.
// -----------------------------------------------------------------------------
@protocol SgfSyntaxCheckingLevelSettingsDelegate
/// @brief This method is invoked after
/// @a SgfSyntaxCheckingLevelSettingsController has updated the SgfSettingsModel
/// with new information.
- (void) didChangeSyntaxCheckingLevel:(SgfSyntaxCheckingLevelSettingsController*)sgfSyntaxCheckingLevelSettingsController;
@end


// -----------------------------------------------------------------------------
/// @brief The SgfSyntaxCheckingLevelSettingsController class is responsible for
/// managing user interaction on the "Syntax checking level" preferences view.
///
/// The "Syntax checking level" preferences view allows the advanced user to
/// edit individual preferences related to how strict the syntax of SGF content
/// is checked when the SGF content is loaded. The view is a generic UITableView
/// whose input elements are created dynamically by
/// SgfSyntaxCheckingLevelSettingsController.
///
/// SgfSettingsController expects to be displayed by a navigation
/// controller, by being pushed on the controller's navigation stack.
///
/// SgfSyntaxCheckingLevelSettingsController expects to be configured with a
/// delegate that can be informed when the user makes any changes. For this to
/// work, the delegate must implement the protocol
/// SgfSyntaxCheckingLevelSettingsDelegate.
// -----------------------------------------------------------------------------
@interface SgfSyntaxCheckingLevelSettingsController : UITableViewController <ItemPickerDelegate,
                                                                             SgfDisabledMessagesDelegate>
{
}

+ (SgfSyntaxCheckingLevelSettingsController*) controllerWithDelegate:(id<SgfSyntaxCheckingLevelSettingsDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<SgfSyntaxCheckingLevelSettingsDelegate> delegate;

@end
