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
#import "../../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for PlayViewController.
// -----------------------------------------------------------------------------
@interface PlayViewController()
@property(nonatomic, retain) TapGestureController* tapGestureController;
@end


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
  [self releaseObjects];
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
/// @brief Private helper for dealloc and viewDidUnload
// -----------------------------------------------------------------------------
- (void) releaseObjects
{
  self.view = nil;
  self.playView = nil;
  self.panGestureController = nil;
  self.tapGestureController = nil;
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.playView = [[[PlayView alloc] initWithFrame:CGRectZero] autorelease];
  self.view = self.playView;
  self.view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  self.view.backgroundColor = [UIColor clearColor];

  self.panGestureController.playView = self.playView;
  self.tapGestureController.playView = self.playView;
}

/*xxx
// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
 // Activate the following code to display controls that you can use to change
 // Play view drawing parameters that are normally immutable at runtime. This
 // is nice for debugging changes to the drawing system.
 //  [self setupDebugView];
  [self setupSubcontrollers];
}

// -----------------------------------------------------------------------------
/// @brief Exists for compatibility with iOS 5. Is not invoked in iOS 6 and can
/// be removed if deployment target is set to iOS 6.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];

  // Dismiss the controller before releasing/deallocating objects
  [self.navigationBarController dismissGameInfoViewController];
  // Here we need to undo all of the stuff that is happening in
  // viewDidLoad(). Notes:
  // - If the game info view is currently visible, it will not be visible
  //   anymore when viewDidLoad() is invoked the next time
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self releaseObjects];
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // In iOS 5, the system purges the view and self.isViewLoaded becomes false
  // before didReceiveMemoryWarning() is invoked. In iOS 6 the system does not
  // purge the view and self.isViewLoaded is still true when we get here. The
  // view's window property then becomes important: It is nil if the main tab
  // bar controller displays a different tab than the one where the view is
  // visible.
  if (self.isViewLoaded && ! self.view.window)
  {
    // Do not release anything in iOS 6 and later (as opposed to iOS 5 where we
    // are forced to release stuff in viewDidUnload). A run through Instruments
    // shows that releasing objects here frees between 100-300 KB. Since the
    // user is expected to switch back to the Play tab anyway, this gain is
    // only temporary.
    //
    // Furthermore: If we want to release objects here, we need to first
    // resolve this issue: When the memory warning occurs while the game info
    // view controller is at the top of the navigation stack, it seems to be
    // impossible to pop the controller without the application crashing. In
    // iOS 5 / viewDidUnload(), popping the controller seems to work with
    //   [self.navigationBarController dismissGameInfoViewController];
    // (tested only in the simulator), but invoking the same method here
    // causes a crash.
  }
}
*/

@end
