// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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
@class MagnifyingViewController;
@class MagnifyingViewModel;


// -----------------------------------------------------------------------------
/// @brief The MagnifyingViewControllerDelegate protocol must be implemented by
/// the delegate of MagnifyingViewController.
// -----------------------------------------------------------------------------
@protocol MagnifyingViewControllerDelegate
- (MagnifyingViewModel*) magnifyingViewControllerModel:(MagnifyingViewController*)magnifyingViewController;
@end


// -----------------------------------------------------------------------------
/// @brief The MagnifyingViewController class is responsible for managing a
/// MagnifyingView.
///
/// Clients instantiate MagnifyingViewController when they want the magnifying
/// glass to become visible to the user. To actually make the magnifying glass
/// visible, a client must invoke updateMagnificationCenter:inView:() with the
/// initial location. Afterwards, the client continuously invokes
/// updateMagnificationCenter:inView:() to change the magnifying glass location.
/// When a client no longer wants to display the magnifying glass, it
/// deallocates MagnifyingViewController.
///
/// MagnifyingView is responsible for rendering the magnifying glass,
/// MagnifyingViewController is responsible for positioning MagnifyingView.
///
/// MagnifyingViewController must be configured with a delegate, which in turn
/// must provide a MagnifyingViewModel object that the controller can query to
/// obtain user preferences how the MagnifyingView should be positioned.
// -----------------------------------------------------------------------------
@interface MagnifyingViewController : UIViewController
{
}

- (void) updateMagnificationCenter:(CGPoint)magnificationCenter
                            inView:(UIView*)magnificationCenterView;

@property(nonatomic, assign) id<MagnifyingViewControllerDelegate> magnifyingViewControllerDelegate;

@end
