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
@class GtpLogItem;


// -----------------------------------------------------------------------------
/// @brief The GtpLogItemViewController class is responsible for managing user
/// interaction on the "GTP Log Item" view.
///
/// The view is a grouped table view. It displays data encapsulated by a single
/// GtpLogItem object.
///
/// @note GtpLogItemViewController keeps the item data displayed even if the
/// item is removed from the Gtp log (e.g. because the log is cleared, or the
/// item is rotated out of the log). The GtpLogItem object is deallocated when
/// GtpLogItemViewController is dismissed.
// -----------------------------------------------------------------------------
@interface GtpLogItemViewController : UITableViewController
{
}

+ (GtpLogItemViewController*) controllerWithLogItem:(GtpLogItem*)logItem;

@end
