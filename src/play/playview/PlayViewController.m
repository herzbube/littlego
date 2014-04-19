// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "PlayViewController.h"
#import "PlayView.h"
#import "../gesture/PanGestureController.h"
#import "../gesture/TapGestureController.h"


@implementation PlayViewController

// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewController object.
///
/// @note This is the designated initializer of PlayViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  [self setupChildControllers];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  self.playView = nil;
  self.panGestureController = nil;
  self.tapGestureController = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupChildControllers
{
  self.panGestureController = [[[PanGestureController alloc] init] autorelease];
  self.tapGestureController = [[[TapGestureController alloc] init] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.playView = [[[PlayView alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.playView;
  self.view.backgroundColor = [UIColor clearColor];
  self.view.translatesAutoresizingMaskIntoConstraints = NO;

  self.panGestureController.playView = self.playView;
  self.tapGestureController.playView = self.playView;
}

@end
