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


// -----------------------------------------------------------------------------
/// @brief The DebugPlayViewController class is responsible for displaying a
/// view with a number of input controls that allow to change the Play view's
/// drawing parameters that are normally immutable at runtime.
///
/// After each change the Play view is completely re-drawn to provide an
/// immediate visual feedback of the change's effects. Thus it is possible to
/// quickly test whether a change in the Play view drawing subsystem works as
/// intended.
///
/// The view set up by DebugPlayViewController is intended to be displayed on
/// the left-hand or right-hand side of the Play view when the device is in
/// landscape orientation.
///
/// TODO: DebugPlayViewController should be able to handle interface orientation
/// changes.
// -----------------------------------------------------------------------------
@interface DebugPlayViewController : UIViewController <UITextFieldDelegate>
{
}

- (id) init;

@end
