// -----------------------------------------------------------------------------
// Copyright 2012 Patrick Näf (herzbube@herzbube.ch)
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
@class ItemScrollView;


// -----------------------------------------------------------------------------
/// @brief Enumerates the orientations supported by ItemScrollView.
// -----------------------------------------------------------------------------
enum ItemScrollViewOrientation
{
  ItemScrollViewOrientationHorizontal,
  ItemScrollViewOrientationVertical
};

// -----------------------------------------------------------------------------
/// @brief The delegate of ItemScrollView must adopt the ItemScrollViewDelegate
/// protocol. The delegate is responsible for handling all non-scrolling user
/// interaction.
// -----------------------------------------------------------------------------
@protocol ItemScrollViewDelegate <NSObject>
@optional
- (void) itemScrollView:(ItemScrollView*)itemScrollView willDisplayItemView:(UIView*)itemView;
- (void) itemScrollView:(ItemScrollView*)itemScrollView didTapItemView:(UIView*)itemView;
@end

// -----------------------------------------------------------------------------
/// @brief The data source of ItemScrollView must adopt the
/// ItemScrollViewDataSource protocol.
///
/// The data source is responsible for providing new item views when they are
/// requested by ItemScrollViewDataSource.
// -----------------------------------------------------------------------------
@protocol ItemScrollViewDataSource <NSObject>
@required
/// @brief This method is invoked once to calculate the scroll view's content
/// size.
- (int) numberOfItemsInItemScrollView:(ItemScrollView*)itemScrollView;
/// @brief This method is invoked whenever the ItemScrollView needs item views
/// to populate the visible content area.
- (UIView*) itemScrollView:(ItemScrollView*)itemScrollView itemViewAtIndex:(int)index;

@optional
/// @brief This method is invoked once to calculate the scroll view's content
/// size width.
///
/// This method is invoked only if the ItemScrollView's orientation is
/// horizontal. Data sources do not need to implement this if the ItemScrollView
/// orientation is vertical.
- (int) itemWidthInItemScrollView:(ItemScrollView*)itemScrollView;
/// @brief This method is invoked once to calculate the scroll view's content
/// size height.
///
/// This method is invoked only if the ItemScrollView's orientation is
/// vertical. Data sources do not need to implement this if the ItemScrollView
/// orientation is horizontal.
- (int) itemHeightInItemScrollView:(ItemScrollView*)itemScrollView;
@end


// -----------------------------------------------------------------------------
/// @brief The ItemScrollView class provides seamless (i.e. not paginated)
/// scrolling through a finite number of item views. The item views are arranged
/// either horizontally or vertically.
///
/// ItemScrollView is designed to be used similarly to UITableView: It requires
/// that a data source (ItemScrollViewDataSource) provides the item views to be
/// displayed, and a delegate (ItemScrollViewDelegate) to handle all
/// non-scrolling user interaction.
///
/// Item views must all be of uniform width (if the ItemScrollView orientation
/// is horizontal) or height (if the ItemScrollView orientation is vertical) so
/// that the content size and with it the scroll bars can be properly
/// calculated. The uniform width/height that is advertised by the data source
/// is neither checked nor enforced when concrete item views are requested. If
/// the total width/height of all item views exceeds the calculated content
/// size, some item views are not displayed. If the total width/height is below
/// the content size, a part of the ItemScrollView remains empty.
///
/// In the other direction, item views should match the height/width of the
/// ItemScrollView. Item views that are less high/wide are placed so that they
/// align at the top/left of the ItemScrollView. Item views that exceed the
/// height/width of the ItemScrollView are clipped.
///
///
/// @par Memory usage vs. performance
///
/// ItemScrollView requests item views from the data source only as they are
/// needed: When it is initially displayed, it requests views until they fill
/// the entire visible area. When the user starts scrolling, ItemScrollView
/// requests as many views as are needed to fill the area that has become
/// visible through the scrolling action. Item views that are no longer visible
/// are removed from ItemScrollView, which means that unless someone else keeps
/// a reference to them they will be deallocated. This is to keep memory usage
/// low even if the data source has a large number of item views. The downside
/// of this is a certain performance overhead that may become noticeable if the
/// user is scrolling quickly and a large number of new item views needs to be
/// created in quick succession. For this reason it is recommended to make item
/// views as light-weight as possible.
///
///
/// @par Credits
///
/// This class is a complete rewrite of Apple's Street Scroller demo from their
/// UIScrollView presentation at WWDC 2011. The main goal was to generalize the
/// concept of a seamless scrolling view:
/// - It should be possible to scroll any type and number of item views
/// - Scrolling should be possible both horizontally and vertically
///
/// The original demo code can be found here:
/// http://developer.apple.com/library/ios/samplecode/StreetScroller/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011102
/// I found the reference to the demo at StackOverflow:
/// http://stackoverflow.com/questions/6736295/iphone-uiscrollview-continuous-circular-scrolling
// -----------------------------------------------------------------------------
@interface ItemScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>
{
}

- (id) initWithFrame:(CGRect)frame;
- (id) initWithFrame:(CGRect)frame orientation:(enum ItemScrollViewOrientation)orientation;
- (void) reloadData;

/// @brief The orientation of the ItemScrollView, i.e. in which direction should
/// scrolling be enabled.
@property(nonatomic, assign, readonly) enum ItemScrollViewOrientation itemScrollViewOrientation;
/// @brief The delegate for the ItemScrollView.
///
/// Setting a delegate is optional.
@property(nonatomic, assign) id<ItemScrollViewDelegate> itemScrollViewDelegate;
/// @brief The data source for the ItemScrollView.
///
/// Setting this property reconfigures the view with a new content size and
/// discards all item views that are currently visible. A new query cycle will
/// begin to fill the visible area of ItemScrollView with item views as soon as
/// UIKit begins updating ItemScrollView.
@property(nonatomic, assign) id<ItemScrollViewDataSource> itemScrollViewDataSource;
/// @brief The view that is the superview of all item views.
///
/// This property is exposed to facilitate zooming by a controller.
@property(nonatomic, retain, readonly) UIView* itemContainerView;

@end
