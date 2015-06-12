// -----------------------------------------------------------------------------
// Copyright 2013-2015 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief The BoardPositionTableListViewController class is responsible for
/// managing the table views that display the current board position and the
/// list of all board positions in #UIAreaPlay.
///
/// BoardPositionTableListViewController is a child view controller. It is used
/// on the iPad only where it replaces the iPhone-only subcontrollers
/// BoardPositionListViewController and CurrentBoardPositionViewController.
///
/// BoardPositionTableListViewController replicates a lot of the user
/// interaction and update policies described in the class documentation of
/// BoardPositionListViewController.
// -----------------------------------------------------------------------------
@interface BoardPositionTableListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
}

@end
