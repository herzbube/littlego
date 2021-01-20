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


// Forward declarations
@class SGFCMessage;


// -----------------------------------------------------------------------------
/// @brief The ViewLoadResultMessageController class is responsible for managing
/// user interaction on the "View load result message" view.
///
/// The "View load result message" view displays information about a single
/// SGFC message that was generated during an attempt to load an SGF file. The
/// view is a generic UITableView whose input elements are created dynamically
/// by ViewLoadResultMessageController.
// -----------------------------------------------------------------------------
@interface ViewLoadResultMessageController : UITableViewController
{
}

+ (ViewLoadResultMessageController*) controllerWithMessage:(SGFCMessage*)message;

@end
