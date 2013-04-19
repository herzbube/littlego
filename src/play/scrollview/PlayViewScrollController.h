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


// Forward declarations
@class PlayView;


// -----------------------------------------------------------------------------
/// @brief The PlayViewScrollController class manages the scroll views that
/// contain the Play view and the coordinate label views.
///
/// PlayViewScrollController's has the following responsibilities:
/// - Initialize zoom scales
/// - Synchronize content offset between Play view and coordinate label views
///   when the Play view is scrolled
/// - Synchronize zoom scale and content size between Play view and coordinate
///   label views when the Play view is scrolled
/// - Trigger redrawing of Play view and coordinate label views after a zoom
///   operation completes
/// - Monitor the maximum zoom scale user preference and apply the new value
///   to Play view and coordinate label views
// -----------------------------------------------------------------------------
@interface PlayViewScrollController : NSObject <UIScrollViewDelegate>
{
}

- (id) initWithScrollView:(UIScrollView*)scrollView playView:(PlayView*)playView;

@end
