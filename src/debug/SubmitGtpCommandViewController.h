// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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
@class GtpCommandModel;


// -----------------------------------------------------------------------------
/// @brief The SubmitGtpCommandViewController class is responsible for managing
/// user interaction on the "Submit GTP command" view.
// -----------------------------------------------------------------------------
@interface SubmitGtpCommandViewController : UIViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
}

+ (SubmitGtpCommandViewController*) controller;

/// @brief The text field used to edit the GTP command before it is submitted.
@property(nonatomic, retain) IBOutlet UITextField* textField;
/// @brief The model object
@property(retain) GtpCommandModel* model;

@end
