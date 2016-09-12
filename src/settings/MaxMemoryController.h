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
@class MaxMemoryController;


// -----------------------------------------------------------------------------
/// @brief The MaxMemoryControllerDelegate protocol must be implemented by the
/// delegate of MaxMemoryController.
// -----------------------------------------------------------------------------
@protocol MaxMemoryControllerDelegate
/// @brief This method is invoked when the user has finished selecting a value.
///
/// @a didCancel is true if the user has cancelled selecting a value.
/// @a didCancel is false if the user did select a value.
- (void) didEndEditing:(MaxMemoryController*)maxMemoryController didCancel:(bool)didCancel;
@end


// -----------------------------------------------------------------------------
/// @brief The MaxMemoryController class is responsible for managing the user
/// preferences view dedicated to changing the "Maximum memory" GTP engine
/// profile setting.
// -----------------------------------------------------------------------------
@interface MaxMemoryController : UITableViewController
{
}

/// @brief The delegate that will be informed when the user has finished
/// selecting a value.
@property(nonatomic, assign) id<MaxMemoryControllerDelegate> delegate;
/// @brief The value initially displayed is taken from this property. When
/// selection ends with the user tapping "done", this contains the value
/// selected by the user.
@property(nonatomic, assign) int maxMemory;

@end
