// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
@class PageViewController;


// -----------------------------------------------------------------------------
/// @brief The PageViewControllerDelegate protocol must be implemented by the
/// delegate of PageViewController.
// -----------------------------------------------------------------------------
@protocol PageViewControllerDelegate <NSObject>
@optional
/// @brief Indicates that @a pageViewController is about to hide
/// @a currentViewController and show @a nextViewController instead.
///
/// @a currentViewController is @e nil if @a nextViewController is the initial
/// view controller being shown.
///
/// @a pageViewController has not yet made any changes to the view hierarchy
/// when it invokes this delegate method.
- (void) pageViewController:(PageViewController*)pageViewController
     willHideViewController:(UIViewController*)currentViewController
     willShowViewController:(UIViewController*)nextViewController;

/// @brief Indicates that @a pageViewController has completed
/// hiding @a currentViewController and showing @a nextViewController instead.
///
/// @a currentViewController is @e nil if @a nextViewController is the initial
/// view controller being shown.
///
/// @a pageViewController has completed all changes to the view hierarchy
/// when it invokes this delegate method.
- (void) pageViewController:(PageViewController*)pageViewController
     didHideViewController:(UIViewController*)currentViewController
     didShowViewController:(UIViewController*)nextViewController;
@end


// -----------------------------------------------------------------------------
/// @brief The PageViewController class is a container view controller that
/// re-implements a reduced set of functionality of the UIKit class
/// UIPageViewController.
///
/// There are two reasons for implementing PageViewController instead of using
/// UIPageViewController
/// - It seems to be impossible to add the UIPageViewController view as a
///   subview to a UIScrollView.
/// - There is no way how to layout the UIPageControl used by
///   UIPageViewController. Specifically, the UIPageControl used by
///   UIPageViewController takes up too much vertical space.
///
/// PageViewController re-implements the following functionality from
/// UIPageViewController:
/// - Pages must be provided by child view controllers.
/// - Displays a UIPageControl.
/// - Supports left/right swipe gestures.
///
/// PageViewController does not implement the following features provided by
/// UIPageViewController
/// - Only horizontal paging
/// - No delegate
/// - No data source to allow dynamic addition/removal of pages - pages can
///   only be specified at initialization time
/// - No "page curl" animation
/// - No "double sided" pages
/// - No integration in Interface Builder
// -----------------------------------------------------------------------------
@interface PageViewController : UIViewController
{
}

+ (PageViewController*) pageViewControllerWithViewControllers:(NSArray*)viewControllers;
+ (PageViewController*) pageViewControllerWithViewControllers:(NSArray*)viewControllers
                                        initialViewController:(UIViewController*)initialViewController;

/// @brief The delegate of PageViewController.
@property (nonatomic, assign) id<PageViewControllerDelegate> delegate;

/// @brief The duration in seconds of the slide animation when the
/// PageViewController replaces the current page with a new page.
@property (nonatomic, assign) CGFloat slideAnimationDurationInSeconds;

/// @brief The tint color to be used by the page control. Set this to @e nil to
/// indicate that the page control should use its default tint color. The
/// default value is @e nil.
@property (nonatomic, retain) UIColor* pageControlTintColor;

/// @brief The tint color to be used by the page control for the page indicator.
/// Set this to @e nil to indicate that the page control should use its default
/// tint color. The default value is @e nil.
@property (nonatomic, retain) UIColor* pageControlPageIndicatorTintColor;

/// @brief The tint color to be used by the page control for the current page
/// indicator. Set this to @e nil to indicate that the page control should use
/// its default tint color. The default value is @e nil.
@property (nonatomic, retain) UIColor* pageControlCurrentPageIndicatorTintColor;

/// @brief The height of the page control. Set this to -1 to indicate that the
/// page control should use its intrinsic height. The default value is -1.
///
/// Currently changes to this property are ignored after the PageViewController
/// @e view property has been accessed for the first time.
@property (nonatomic, assign) int pageControlHeight;

/// @brief The vertical spacing between the currently displayed page and the
/// page control. Set this to -1 to indicate that PageViewController should use
/// a minimal internal default spacing. The default value is -1.
///
/// Currently changes to this property take effect only when PageViewController
/// shows a new page.
@property (nonatomic, assign) int pageControlVerticalSpacing;

/// @brief The background style to use for the page control. The default value
/// is UIPageControlBackgroundStyleAutomatic.
///
/// Currently changes to this property are ignored after the PageViewController
/// @e view property has been accessed for the first time.
@property (nonatomic, assign) UIPageControlBackgroundStyle pageControlBackgroundStyle API_AVAILABLE(ios(14.0));

@end
