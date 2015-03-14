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
#import "PlayRootViewController.h"
#import "PlayRootViewControllerPad.h"
#import "PlayRootViewControllerPhone.h"
#import "../../shared/LayoutManager.h"


@implementation PlayRootViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a UI type-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// UI type.
// -----------------------------------------------------------------------------
+ (PlayRootViewController*) playRootViewController
{
  PlayRootViewController* playRootViewController;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    playRootViewController = [[[PlayRootViewControllerPhone alloc] init] autorelease];
  else
    playRootViewController = [[[PlayRootViewControllerPad alloc] init] autorelease];
  playRootViewController.edgesForExtendedLayout = UIRectEdgeNone;
  playRootViewController.automaticallyAdjustsScrollViewInsets = NO;
  return playRootViewController;
}

@end
