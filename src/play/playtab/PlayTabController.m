// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"


@implementation PlayTabController

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a device-dependent controller
/// object that knows how to set up the correct view hierarchy for the current
/// device.
// -----------------------------------------------------------------------------
+ (PlayTabController*) playTabController
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return [[[PlayTabControllerPhone alloc] init] autorelease];
  else
    return [[[PlayTabControllerPad alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayTabController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.view = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.view = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;
}

@end
