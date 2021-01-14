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
#import "../ui/EditTextController.h"


// Forward declarations
@class SgfDisabledMessagesController;


// -----------------------------------------------------------------------------
/// @brief The SgfDisabledMessagesDelegate protocol must be
/// implemented by the delegate of SgfDisabledMessagesController.
// -----------------------------------------------------------------------------
@protocol SgfDisabledMessagesDelegate
/// @brief This method is invoked after
/// @a SgfDisabledMessagesController has updated the SgfSettingsModel
/// with new information.
- (void) didChangeDisabledMessages:(SgfDisabledMessagesController*)sgfDisabledMessagesController;
@end


// -----------------------------------------------------------------------------
/// @brief The SgfDisabledMessagesController class is responsible for managing
/// user interaction on the "Disabled messages" view.
// -----------------------------------------------------------------------------
@interface SgfDisabledMessagesController : UITableViewController <EditTextDelegate>
{
}

+ (SgfDisabledMessagesController*) controllerWithDelegate:(id<SgfDisabledMessagesDelegate>)delegate;

/// @brief This is the delegate that will be informed when the user makes any
/// changes.
@property(nonatomic, assign) id<SgfDisabledMessagesDelegate> delegate;

@end
