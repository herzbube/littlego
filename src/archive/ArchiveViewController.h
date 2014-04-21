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


// Forward declarations
@class ArchiveViewModel;


// -----------------------------------------------------------------------------
/// @brief The ArchiveViewController class is responsible for managing user
/// interaction on the "Archive" view.
// -----------------------------------------------------------------------------
@interface ArchiveViewController : UIViewController <UITableViewDataSource,
                                                     UITableViewDelegate,
                                                     UIAlertViewDelegate>
{
}

/// @brief The model that manages data used by the ArchiveView.
@property(nonatomic, assign) ArchiveViewModel* archiveViewModel;

@end
