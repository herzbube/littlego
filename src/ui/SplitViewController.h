// -----------------------------------------------------------------------------
// Copyright 2014-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class SplitViewController;


// -----------------------------------------------------------------------------
/// @brief The SplitViewControllerDelegate protocol must be implemented by the
/// delegate of SplitViewController.
// -----------------------------------------------------------------------------
@protocol SplitViewControllerDelegate
- (void) splitViewController:(SplitViewController*)svc
      willHideViewController:(UIViewController*)aViewController
           withBarButtonItem:(UIBarButtonItem*)barButtonItem;
- (void) splitViewController:(SplitViewController*)svc
      willShowViewController:(UIViewController*)aViewController
   invalidatingBarButtonItem:(UIBarButtonItem *)button;
@end


// -----------------------------------------------------------------------------
/// @brief The SplitViewController class is a container view controller that
/// re-implements a reduced set of functionality of the UIKit class
/// UISplitViewController, minus bugs.
///
/// After many hours of debugging UISplitViewController, and implementing
/// workarounds that let me use UISplitViewController the way I want it, I
/// finally decided to write my own replacement class: SplitViewController. I
/// suspect that most of my problems I had with UISplitViewController were due
/// to the fact that UISplitViewController is intended to be used as a top-level
/// view controller. In this project, however, I need UISplitViewController to
/// be inside a UITabBarController.
///
/// SplitViewController re-implements the following functionality from
/// UISplitViewController:
/// - Show the left pane in landscape orientation, hide the left pane in
///   portrait orientation
/// - Inform the delegate when the left pane is shown/hidden, providing it with
///   a UIBarButtonItem object which when tapped will display the left pane.
///
/// SplitViewController improves on UISplitViewController in the following
/// ways:
/// - Not restricted to iPad
/// - Not restricted to be used as top-level view controller
///
/// SplitViewController does not implement the following features provided by
/// UISplitViewController
/// - No swipe gesture
/// - No popover support (not using popovers allows SplitViewController to be
///   used on the iPhone)
/// - No integration in Interface Builder
// -----------------------------------------------------------------------------
@interface SplitViewController : UIViewController
{
}

@property (nonatomic, copy) NSArray* viewControllers;
@property (nonatomic, assign) id <SplitViewControllerDelegate> delegate;
/// @brief The minimum width that the left pane should get.
///
/// In portrait orientation when the left pane is shown in the overlay its
/// width will be equal to this minimum width.
///
/// In landscape orientation the left pane's left edge is anchored to the left
/// edge of the superview, and the left pane's right edge is anchored to the
/// left edge of the safe area PLUS this minimum width. This has the following
/// effect on the left pane width:
/// - If the safe area left edge is equal to the superview left edge, the left
///   pane width will be equal to this minimum width.
/// - But if the safe area left edge is inset from the superview left edge (e.g.
///   because of the presence of the notch on an iPhone), the left pane width
///   will be equal to this minimum width + the safe area left inset. Given that
///   the left pane view content is properly adjusting to the safe area it will
///   therefore still have sufficient width to present its content.
@property (nonatomic, assign) int leftPaneMinimumWidth;

@end
