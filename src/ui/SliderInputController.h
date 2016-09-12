// -----------------------------------------------------------------------------
// Copyright 2013-2016 Patrick Näf (herzbube@herzbube.ch)
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
@class SliderInputController;


// -----------------------------------------------------------------------------
/// @brief The SliderInputDelegate protocol must be implemented by the delegate
/// of SliderInputController.
// -----------------------------------------------------------------------------
@protocol SliderInputDelegate
/// @brief This method is invoked when the user dismisses @a controller.
- (void) didDismissSliderInputController:(SliderInputController*)controller;
@end


// -----------------------------------------------------------------------------
/// @brief The SliderInputController class is responsible for displaying a table
/// view with a single cell. The cell contains a slider that lets the user
/// select a value.
///
/// SliderInputController expects to be pushed onto the stack of a navigation
/// controller so that the user can dismiss it by tapping on the standard back
/// button item.
// -----------------------------------------------------------------------------
@interface SliderInputController : UITableViewController <UINavigationBarDelegate>
{
}

/// @brief A context object that can be set by the client to identify the
/// context or purpose that an instance of SliderInputController was created
/// for.
@property(nonatomic, retain) id context;
/// @brief The screen title to be displayed in the navigation item.
@property(nonatomic, retain) NSString* screenTitle;
/// @brief The string to be displayed as the title of the table view's footer.
@property(nonatomic, retain) NSString* footerTitle;
/// @brief The string to be displayed as the slider's description label.
@property(nonatomic, retain) NSString* descriptionLabelText;
/// @brief The delegate that is informed when the user dismisses the
/// SliderInputController.
@property(nonatomic, assign) id<SliderInputDelegate> delegate;
/// @brief Initially this contains the default value that the slider should
/// display. Contains the final value when the user dismisses the controller.
@property(nonatomic, assign) int value;
/// @brief Slider minimum value.
@property(nonatomic, assign) int minimumValue;
/// @brief Slider maximum value.
@property(nonatomic, assign) int maximumValue;

@end
