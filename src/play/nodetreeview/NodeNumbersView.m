// -----------------------------------------------------------------------------
// Copyright 2023-2024 Patrick Näf (herzbube@herzbube.ch)
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


// Project includes
#import "NodeNumbersView.h"
#import "NodeNumbersTileView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeNumbersView.
// -----------------------------------------------------------------------------
@interface NodeNumbersView()
@end


@implementation NodeNumbersView

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Redraws the node numbers view with updated colors.
// -----------------------------------------------------------------------------
- (void) updateColors
{
  [self notifyTiles:NTVLDEventInvalidateContent eventInfo:nil];
}

// -----------------------------------------------------------------------------
/// @brief Removes notification responders in all parts of the node numbers
/// view. This message is sent shortly before the node numbers view is
/// deallocated.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  for (id subview in [self.tileContainerView subviews])
  {
    if (! [subview isKindOfClass:[NodeNumbersTileView class]])
      continue;

    NodeNumbersTileView* tileView = subview;
    [tileView removeNotificationResponders];
  }
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Notifies all subviews that are NodeTreeTileView objects that @a event
/// has occurred. The event info object supplied to the tile view is
/// @a eventInfo. Also triggers each subview's delayed drawing mechanism.
// -----------------------------------------------------------------------------
- (void) notifyTiles:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id subview in [self.tileContainerView subviews])
  {
    if (! [subview isKindOfClass:[NodeNumbersTileView class]])
      continue;

    NodeNumbersTileView* tileView = subview;
    [tileView notifyLayerDelegate:event eventInfo:eventInfo];
    [tileView delayedDrawLayer];
  }
}

@end
