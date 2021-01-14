// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfSyntaxCheckingLevelSettingsController.h"
#import "../ui/EditTextController.h"
#import "../ui/ItemPickerController.h"


// -----------------------------------------------------------------------------
/// @brief The SgfSettingsController class is responsible for managing
/// user interaction on the "Smart Game Format" user preferences view.
///
/// The "Smart Game Format" view allows the user to edit preferences how
/// SGF content should be processed. The user can adjust the syntax checking
/// level either by selecting one of several pre-defined combinations of
/// settings, or by tweaking individual settings. In the latter case, editing
/// of those settings is delegated to SgfSyntaxCheckingLevelSettingsController.
///
/// The view managed by SgfSettingsController is a generic UITableView whose
/// input elements are created dynamically by SgfSettingsController.
///
/// SgfSettingsController expects to be displayed by a navigation
/// controller, by being pushed on the controller's navigation stack.
// -----------------------------------------------------------------------------
@interface SgfSettingsController : UITableViewController <EditTextDelegate,
                                                          ItemPickerDelegate,
                                                          SgfSyntaxCheckingLevelSettingsDelegate>
{
}

+ (SgfSettingsController*) controller;

@end
