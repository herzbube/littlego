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


// Forward declarations
@class GtpLogItem;


// -----------------------------------------------------------------------------
/// @brief The GtpLogModel class is responsible for managing information that
/// records the log of the GTP client/engine command/response exchange.
// -----------------------------------------------------------------------------
@interface GtpLogModel : UIViewController
{
}

- (id) init;
- (GtpLogItem*) itemAtIndex:(int)index;
- (void) clearLog;

/// @brief Number of objects in itemList.
///
/// This property exists purely as a convenience to clients, since the object
/// count is also available from the itemList array.
@property(readonly) int itemCount;
/// @brief Array stores objects of type GtpLogItem. Items appear in the array
/// in the order that their corresponding commands were submitted.
@property(readonly, retain) NSArray* itemList;

@end
