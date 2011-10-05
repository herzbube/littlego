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
- (void) readUserDefaults;
- (void) writeUserDefaults;
- (GtpLogItem*) itemAtIndex:(int)index;
- (void) clearLog;

/// @brief Number of objects in @e itemList.
///
/// This property exists purely as a convenience to clients, since the object
/// count is also available from the itemList array.
@property(readonly) int itemCount;
/// @brief Array stores objects of type GtpLogItem. Items appear in the array
/// in the order that their corresponding commands were submitted.
@property(readonly, retain) NSArray* itemList;
/// @brief The size of the GTP log, i.e. the maximum number of objects that can
/// be in @e itemList.
///
/// If a new item is about to be added to @e itemList that would exceed the
/// limit, the oldest item is discarded first.
@property int gtpLogSize;
/// @brief True if the "GTP Log" view currently displays the frontside view,
/// false if it displays the backside view.
@property bool gtpLogViewFrontSideIsVisible;

@end
