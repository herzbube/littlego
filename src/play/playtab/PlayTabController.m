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


// Project includes
#import "PlayTabController.h"
#import "PlayTabControllerPad.h"
#import "PlayTabControllerPhone.h"
#import "../../shared/LayoutManager.h"


@implementation PlayTabController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a UI type-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// UI type.
// -----------------------------------------------------------------------------
+ (PlayTabController*) playTabController
{
  PlayTabController* playTabController;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    playTabController = [[[PlayTabControllerPhone alloc] init] autorelease];
  else
    playTabController = [[[PlayTabControllerPad alloc] init] autorelease];
  playTabController.edgesForExtendedLayout = UIRectEdgeNone;
  playTabController.automaticallyAdjustsScrollViewInsets = NO;
  return playTabController;
}

@end
