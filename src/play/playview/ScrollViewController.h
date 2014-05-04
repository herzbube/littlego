// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
@class PlayViewController;


// -----------------------------------------------------------------------------
/// @brief The ScrollViewController class manages the scroll views that contain
/// the "Play" view and the coordinate label views on the "Play" tab.
///
/// ScrollViewController is a container view controller. It has the following
/// responsibilities:
/// - Manage zooming and scrolling
/// - Synchronize zooming and scrolling properties of scroll views that contain
///   coordinate label views with the corresponding properties of the main
///   scroll view
/// - Monitor the maximum zoom scale user preference and apply the new value
///   to the "Play" view and coordinate label views
/// - Resize the Play view when a view layout change occurs outside of zooming.
///   See the documentation of viewWillLayoutSubviews() for details.
// -----------------------------------------------------------------------------
@interface ScrollViewController : UIViewController <UIScrollViewDelegate>
{
}

@property(nonatomic, assign) UIScrollView* scrollView;
@property(nonatomic, retain) PlayViewController* playViewController;
@property(nonatomic, assign) UIScrollView* coordinateLabelsLetterViewScrollView;
@property(nonatomic, assign) UIView* coordinateLabelsLetterView;
@property(nonatomic, assign) UIScrollView* coordinateLabelsNumberViewScrollView;
@property(nonatomic, assign) UIView* coordinateLabelsNumberView;

@end
