// -----------------------------------------------------------------------------
// Copyright 2022-2024 Patrick Näf (herzbube@herzbube.ch)
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
@class OrientationChangeNotifyingView;


// -----------------------------------------------------------------------------
/// @brief The OrientationChangeNotifyingViewDelegate protocol must be
/// implemented by the delegate of OrientationChangeNotifyingView.
// -----------------------------------------------------------------------------
@protocol OrientationChangeNotifyingViewDelegate <NSObject>
@optional
/// @brief Indicates that @a orientationChangeNotifyingView has changed its
/// orientation. The view's larger dimension is now @a largerDimension, the
/// view's smaller dimension is now @a smallerDimension.
///
/// @a orientationChangeNotifyingView invokes this method at least once, when
/// it layouts its subviews for the first time and receives its initial bounds.
///
/// When @a orientationChangeNotifyingView is square it will report
/// @a largerDimension to be @e UILayoutConstraintAxisVertical (i.e. Portrait).
- (void) orientationChangeNotifyingView:(OrientationChangeNotifyingView*)orientationChangeNotifyingView
             didChangeToLargerDimension:(UILayoutConstraintAxis)largerDimension
                       smallerDimension:(UILayoutConstraintAxis)smallerDimension;
@end


// -----------------------------------------------------------------------------
/// @brief The OrientationChangeNotifyingView class is a UIView subclass with
/// the only purpose to notify a delegate when the view's dimensions change so
/// that its orientation changes from Portrait to Landscape, or vice versa.
///
/// OrientationChangeNotifyingView is useful because it can be difficult for
/// a view controller to detect which orientation its subviews have without
/// both assigning exact sizes to everything (something one usually wants to
/// avoid when coding for many devices) @b and taking the actual device screen
/// size into account. For instance, overriding the UIViewController method
/// viewDidLayoutSubviews() has proven to be unreliable for this purpose,
/// because the controller's main view may have stopped layouting subviews
/// although the layouting process is still ongoing in deeper layers of the
/// view hierarchy.
// -----------------------------------------------------------------------------
@interface OrientationChangeNotifyingView : UIView
{
}

/// @brief The delegate of OrientationChangeNotifyingView.
@property (nonatomic, assign) id<OrientationChangeNotifyingViewDelegate> delegate;

@end
