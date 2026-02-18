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


// Forward declarations
@class GoGame;
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The InvalidTimeDataDetailViewController class is responsible for
/// showing details about why the time data in the node that is supplied to the
/// controller's initializer is invalid.
///
/// InvalidTimeDataDetailViewController displays the details in the form of a
/// table view, with the top-level table view cell containing a textual
/// explanation of the #GoTimeDataInvalidReason value that is stored in the
/// GoNode, and the remaining cells providing context and actual values to
/// supplement the textual explanation.
// -----------------------------------------------------------------------------
@interface InvalidTimeDataDetailViewController : UITableViewController
{
}

- (id) initWithGame:(GoGame*)game
        currentNode:(GoNode*)currentNode;

@end
