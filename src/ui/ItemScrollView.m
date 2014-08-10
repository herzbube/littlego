// -----------------------------------------------------------------------------
// Copyright 2012-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "ItemScrollView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ItemScrollView.
// -----------------------------------------------------------------------------
@interface ItemScrollView()
/// @name Privately declared properties
//@{
/// @brief Array that contains the item views and their indexes that are
/// currently visible in the ItemScrollView.
///
/// Each entry in the @e visibleItems array is another array with two elements:
/// The first element is the item view (an UIView object), and the second
/// element is the item view's index (an NSNumber object with an int value).
///
/// There are 4 accessor methods that conveniently provide access to the first
/// and the last item view in the array, and the index of the first and the last
/// item view.
@property(nonatomic, retain) NSMutableArray* visibleItems;
/// @brief The gesture recognizer that handles tap gestures on the visible
/// item views.
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum ItemScrollViewOrientation itemScrollViewOrientation;
@property(nonatomic, retain, readwrite) UIView* itemContainerView;
@property(nonatomic, assign, readwrite) int numberOfItemsInItemScrollView;
//@}
@end


@implementation ItemScrollView

// -----------------------------------------------------------------------------
/// @brief Initializes an ItemScrollView object with frame rectangle @a frame
/// and items arranged horizontally.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)frame
{
  // Invoke designated initializer
  return [self initWithFrame:frame orientation:ItemScrollViewOrientationHorizontal];
}

// -----------------------------------------------------------------------------
/// @brief Initializes an ItemScrollView object with frame rectangle @a frame
/// and items arranged according to @a orientation.
///
/// @note This is the designated initializer of ItemScrollView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)frame orientation:(enum ItemScrollViewOrientation)orientation;
{
  // Call designated initializer of superclass (UIScrollView)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;

  // Will be set to the correct size when the data source is configured
  self.contentSize = self.frame.size;

  self.itemScrollViewOrientation = orientation;
  self.itemScrollViewDelegate = nil;
  _itemScrollViewDataSource = nil;  // don't use self, don't want to trigger reloadData()
  self.visibleItems = [[[NSMutableArray alloc] init] autorelease];
  self.tappingEnabled = true;
  self.numberOfItemsInItemScrollView = 0;
  [self setupItemContainerView];
  [self setupTapGestureRecognizer];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ItemScrollView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.itemScrollViewDelegate = nil;
  _itemScrollViewDataSource = nil;  // don't use self, don't want to trigger reloadData()
  self.visibleItems = nil;
  self.tapRecognizer = nil;
  self.itemContainerView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates and sets up the container view that will be the item views'
/// superview.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupItemContainerView
{
  self.itemContainerView = [[[UIView alloc] init] autorelease];
  self.itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
  [self addSubview:self.itemContainerView];
  // Must be enabled so that hit-testing works in handleTapFrom:()
  self.itemContainerView.userInteractionEnabled = YES;
}

// -----------------------------------------------------------------------------
/// @brief Creates and sets up the gesture recognizer that is used to detect
/// taps on item views.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)] autorelease];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setItemScrollViewDelegate:(id<ItemScrollViewDelegate>)delegate
{
  if (delegate == _itemScrollViewDelegate)
    return;
  _itemScrollViewDelegate = delegate;
  [self updateTapRecognition];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setItemScrollViewDataSource:(id<ItemScrollViewDataSource>)dataSource
{
  if (nil == dataSource)
  {
    NSString* errorMessage = @"Data source must not be nil";
    DDLogError(@"%@: %@", self, errorMessage);
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:errorMessage
                                                   userInfo:nil];
    @throw exception;
  }
  _itemScrollViewDataSource = dataSource;
  [self reloadData];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setTappingEnabled:(bool)newValue
{
  if (newValue == _tappingEnabled)
    return;
  _tappingEnabled = newValue;
  [self updateTapRecognition];
}

// -----------------------------------------------------------------------------
/// @brief Enables tap recognition if both a delegate is present and if tapping
/// is enabled in general. Otherwise disables tap recognition.
// -----------------------------------------------------------------------------
- (void) updateTapRecognition
{
  if (self.tappingEnabled && self.itemScrollViewDelegate)
  {
    [self addGestureRecognizer:self.tapRecognizer];
  }
  else
  {
    // Without a delegate there is no point in wasting cycles on recognizing
    // gestures
    [self removeGestureRecognizer:self.tapRecognizer];
  }
}

// -----------------------------------------------------------------------------
/// @brief Changes the content size of the scroll view and removes all visible
/// items. This causes a full new cycle of item view acquisition as soon as
/// UIKit begins updating the scroll view.
///
/// If @a keepVisibleItems is false, the content offset is reset so that the
/// item view acquisition begins at index position 0.
///
/// If @a keepVisibleItems is true, the content offset is set so that the item
/// view acquisition begins with the index position that
/// indexOfFirstVisibleItemView() returns.
// -----------------------------------------------------------------------------
- (void) setItemScrollViewOrientation:(enum ItemScrollViewOrientation)orientation keepVisibleItems:(bool)keepVisibleItems
{
  if (orientation == self.itemScrollViewOrientation)
    return;
  self.itemScrollViewOrientation = orientation;

  int indexOfFirstVisibleItemView = [self indexOfFirstVisibleItemView];
  [self removeAllVisibleItems];
  [self updateContentSize];
  if (keepVisibleItems)
  {
    if (-1 == indexOfFirstVisibleItemView)
    {
      [self resetScrollPosition];
    }
    else
    {
      CGPoint newContentOffset = [self contentOffsetOfItemViewAtMinimumEdgeWithIndex:indexOfFirstVisibleItemView];
      [self setContentOffset:newContentOffset animated:NO];
    }
  }
  else
  {
    [self resetScrollPosition];
  }
  [self setNeedsLayout];  // force layout update
}

// -----------------------------------------------------------------------------
/// @brief Reloads everything from scratch. The content offset is also reset so
/// that item view acquisition begins at index position 0.
// -----------------------------------------------------------------------------
- (void) reloadData
{
  // TODO There is a weird problem where sometimes setNeedsLayout (invoked
  // further down) does not trigger layoutSubviews. This is an attempt at
  // working around the problem, because it appears that setting the content
  // offset to a different value will guarantee that layoutSubviews is called.
  // The circumstances where layoutSubviews is not triggered apparently are
  // these:
  // 1) Content offset does not change (i.e. we are already at content offset
  //    0,0 when reloadData is invoked)
  // 2) Content size does not change (i.e. the number of items and the item
  //    extent do not change when reloadData is invoked)
  // 3) The item views use Auto Layout (i.e. layoutSubviews is always invoked
  //    if item views do not use Auto Layout)
  // 4) Possibly: Content size is < scroll view frame size
  if (CGPointEqualToPoint(self.contentOffset, CGPointMake(0, 0)))
  {
    // Set a dummy value that is different from 0,0. resetScrollPosition which
    // is invoked further down will set the content offset back to 0,0.
    self.contentOffset = CGPointMake(1, 1);
  }

  [self removeAllVisibleItems];
  [self resetScrollPosition];
  self.numberOfItemsInItemScrollView = [self.itemScrollViewDataSource numberOfItemsInItemScrollView:self];
  [self updateContentSize];
  [self setNeedsLayout];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for reloadData()
// -----------------------------------------------------------------------------
- (void) removeAllVisibleItems
{
  for (NSArray* itemArray in _visibleItems)
  {
    UIView* itemView = [itemArray objectAtIndex:0];
    [itemView removeFromSuperview];
  }
  [_visibleItems removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for reloadData()
// -----------------------------------------------------------------------------
- (void) resetScrollPosition
{
  self.contentOffset = CGPointMake(0, 0);
}

// -----------------------------------------------------------------------------
/// @brief Queries the data source for an updated number of items to be
/// displayed, then updates the content size without reloading data.
///
/// The content offset usually remains unaffected by this method.
///
/// The content offset is adjusted, however, if one or more item views are
/// currently displayed whose item index exceeds the new number of items
/// reported by the data source. The content offset is adjusted so that the
/// item view with the new maximum index is positioned at the right or bottom
/// edge of the scroll view. This can also be pictured as the user scrolling
/// leftwards/upwards to the item view with the new maximum index (although no
/// scrolling takes place in actuality, the transition to the new content offset
/// is immediate).
///
/// If items come into view by this scrolling that previously were not visible,
/// the data source is queried for the new item views in the usual manner as
/// soon as UIKit updates the scroll view layout.
// -----------------------------------------------------------------------------
- (void) updateNumberOfItems
{
  int newNumberOfItemsInItemScrollView = [self.itemScrollViewDataSource numberOfItemsInItemScrollView:self];
  if (newNumberOfItemsInItemScrollView == self.numberOfItemsInItemScrollView)
    return;
  // Use self to trigger KVO
  int oldNumberOfItemsInItemScrollView = self.numberOfItemsInItemScrollView;
  self.numberOfItemsInItemScrollView = newNumberOfItemsInItemScrollView;
  [self updateContentSize];
  if (newNumberOfItemsInItemScrollView < oldNumberOfItemsInItemScrollView)
  {
    [self cleanupExcessItemViews];
    [self updateContentOffsetAfterNumberOfItemsHasDecreased];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateNumberOfItems().
// -----------------------------------------------------------------------------
- (void) updateContentSize
{
  int itemExtent = [self itemViewExtent];
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
  {
    CGFloat contentWidth = self.numberOfItemsInItemScrollView * itemExtent;
    self.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
  }
  else
  {
    CGFloat contentHeight = self.numberOfItemsInItemScrollView * itemExtent;
    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight);
  }
  self.itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateNumberOfItems().
// -----------------------------------------------------------------------------
- (void) cleanupExcessItemViews
{
  int indexOfLastItemView = self.numberOfItemsInItemScrollView - 1;
  int maximumEdgeOfLastItemView = [self maximumEdgeOfItemViewWithIndex:indexOfLastItemView];
  [self removeItemsAfterMaximumEdge:maximumEdgeOfLastItemView];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateNumberOfItems().
// -----------------------------------------------------------------------------
- (void) updateContentOffsetAfterNumberOfItemsHasDecreased
{
  if ([self isContentOffsetValid])
    return;
  CGPoint newContentOffset = CGPointZero;
  if (0 == self.numberOfItemsInItemScrollView)
  {
    newContentOffset = CGPointZero;
  }
  else
  {
    int indexOfLastItemView = self.numberOfItemsInItemScrollView - 1;
    CGPoint newContentOffset = [self contentOffsetOfItemViewAtMaximumEdgeWithIndex:indexOfLastItemView];
    if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    {
      if (newContentOffset.x < 0)
        newContentOffset.x = 0;
    }
    else
    {
      if (newContentOffset.y < 0)
        newContentOffset.y = 0;
    }
  }
  [self setContentOffset:newContentOffset animated:NO];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateContentOffsetAfterNumberOfItemsHasDecreased().
// -----------------------------------------------------------------------------
- (bool) isContentOffsetValid
{
  bool contentOffsetIsValid = true;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
  {
    if (self.contentOffset.x + self.frame.size.width > self.contentSize.width)
      contentOffsetIsValid = false;
  }
  else
  {
    if (self.contentOffset.y + self.frame.size.height > self.contentSize.height)
      contentOffsetIsValid = false;
  }
  return contentOffsetIsValid;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the item view at index position @a index is currently
/// visible in this scroll view.
// -----------------------------------------------------------------------------
- (bool) isVisibleItemViewAtIndex:(int)index
{
  if (0 == _visibleItems.count)
    return false;
  else if ([self isBeforeFirstVisibleItemViewIndex:index])
    return false;
  else if ([self isAfterLastVisibleItemViewIndex:index])
    return false;
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Updates the content offset so that the target item view at index
/// position @a index becomes fully visible.
///
/// If item views are already visible, the content offset update is made as if
/// the user had naturally scrolled from the current offset position to the new
/// offset position and then stopped when the target item view came into view.
///
/// If no item views are currently visible, the behaviour is as if the item view
/// with index 0 were currently visible.
///
/// If @a animated is false, the content offset change is immediate. The data
/// source is queried for 1-n item views that are visible at the new offset
/// position.
///
/// If @a animated is true the content offset change is animated. The data
/// source is additionally queried for item views that become visible
/// "on the way" to the new offset position.
///
/// @note The content offset is not changed if the item view at index position
/// @a index is already visible.
// -----------------------------------------------------------------------------
- (void) makeVisibleItemViewAtIndex:(int)index animated:(bool)animated
{
  CGPoint newContentOffset;
  if (0 == _visibleItems.count || [self isAfterLastVisibleItemViewIndex:index])
  {
    newContentOffset = [self contentOffsetOfItemViewAtMaximumEdgeWithIndex:index];
    if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    {
      if (newContentOffset.x < 0)
        newContentOffset.x = 0;
    }
    else
    {
      if (newContentOffset.y < 0)
        newContentOffset.y = 0;
    }
  }
  else if ([self isBeforeFirstVisibleItemViewIndex:index])
    newContentOffset = [self contentOffsetOfItemViewAtMinimumEdgeWithIndex:index];
  else
    return;  // is visible

  [self setContentOffset:newContentOffset animated:(animated ? YES : NO)];
}

// -----------------------------------------------------------------------------
/// @brief Returns the content offset needed to place the item view at index
/// position @a index so that its minimum edge aligns with the scroll view's
/// minimum edge.
///
/// Internal helper for makeVisibleItemViewAtIndex:animated:()
///
/// @note The content offset returned by this method is too large if not enough
/// item views follow after the target item view to fill an entire page of the
/// scroll view. If such a content offset were used, the scroll view would
/// display an empty area at its maximum edge. Callers can detect the scenario
/// by checking whether the returned offset has a coordinate component that,
/// together with the scroll view's frame, exceeds the content size.
// -----------------------------------------------------------------------------
- (CGPoint) contentOffsetOfItemViewAtMinimumEdgeWithIndex:(int)index
{
  CGFloat contentOffsetX = 0;
  CGFloat contentOffsetY = 0;
  CGFloat minimumEdgeOfItemView = [self minimumEdgeOfItemViewWithIndex:index];
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    contentOffsetX = minimumEdgeOfItemView;
  else
    contentOffsetY = minimumEdgeOfItemView;
  return CGPointMake(contentOffsetX, contentOffsetY);
}

// -----------------------------------------------------------------------------
/// @brief Returns the content offset needed to place the item view at index
/// position @a index so that its maximum edge aligns with the scroll view's
/// maximum edge.
///
/// Internal helper for makeVisibleItemViewAtIndex:animated:()
///
/// @note The content offset returned by this method is too small if not enough
/// item views precede the target item view to fill an entire page of the
/// scroll view. If such a content offset were used, the scroll view would
/// display an empty area at its minimum edge. Callers can detect the scenario
/// by checking whether the returned offset has a negative coordinate component.
// -----------------------------------------------------------------------------
- (CGPoint) contentOffsetOfItemViewAtMaximumEdgeWithIndex:(int)index
{
  CGFloat contentOffsetX = 0;
  CGFloat contentOffsetY = 0;
  CGFloat maximumEdgeOfItemView = [self maximumEdgeOfItemViewWithIndex:index];
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    contentOffsetX = maximumEdgeOfItemView - self.frame.size.width + 1;
  else
    contentOffsetY = maximumEdgeOfItemView - self.frame.size.height + 1;
  return CGPointMake(contentOffsetX, contentOffsetY);
}

// -----------------------------------------------------------------------------
/// @brief This overrides the superclass implementation. Triggers acquisition
/// of item views.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

  self.itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);

  // Methods that are subsequently invoked no longer check this!
  if (0 == self.numberOfItemsInItemScrollView)
    return;

  CGRect visibleBounds = [self convertRect:self.bounds toView:self.itemContainerView];
  CGFloat minimumVisible;
  CGFloat maximumVisible;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
  {
    minimumVisible = CGRectGetMinX(visibleBounds);
    maximumVisible = CGRectGetMaxX(visibleBounds);
  }
  else
  {
    minimumVisible = CGRectGetMinY(visibleBounds);
    maximumVisible = CGRectGetMaxY(visibleBounds);
  }
  [self updateVisibleAreaWithMinimumEdge:minimumVisible maximumEdge:maximumVisible];
}

// -----------------------------------------------------------------------------
/// @brief Updates the visible area in the range between @a minimumEdge and
/// @a maximumEdge.
///
/// This method is usually invoked because of scrolling, but also when the
/// scroll view is laid out for the first time.
///
/// This method checks if new item views have become visible in the visible
/// area. If not, then nothing happens. If yes, the following two-step process
/// is initiated:
/// - New item view are requested from the data source and added as subviews to
///   the container view so that they become visible at either the minimum or
///   the maximum edge (depending on the direction of scrolling)
/// - Item views that are no longer visible are removed from the container view
///   so that they can be deallocated if no one else keeps a reference to them.
///
/// The orientation of the ItemScrollView decides whether the visible area
/// extends on the X- or Y-axis. If the orientation is horizontal, the
/// minimum/maximum edges are on the left/right. If the orientation is vertical,
/// the minimum/maximum edges are at the top/bottom.
///
/// @note Special handling in this method guarantees that helper methods always
/// have at least one visible item view at the time they are invoked.
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaWithMinimumEdge:(CGFloat)minimumEdge maximumEdge:(CGFloat)maximumEdge
{
  // To make the implementation of subsequent steps simpler we need to make sure
  // that the array already contains at least one item view
  if (_visibleItems.count == 0)
  {
    int indexOfInitialItemView = [self indexOfItemViewWithFrameContainingPosition:minimumEdge];
    UIView* initialItemView = [self itemViewWithIndex:indexOfInitialItemView];
    CGFloat minimumEdgeOfInitialItemView = [self minimumEdgeOfItemViewWithIndex:indexOfInitialItemView];
    [self placeItemView:initialItemView withMinimumEdgeAt:minimumEdgeOfInitialItemView];
  }

  [self updateVisibleAreaAtMaximumEdge:maximumEdge];
  [self updateVisibleAreaFromMinimumEdge:minimumEdge];

  [self removeItemsAfterMaximumEdge:maximumEdge];
  [self removeItemsBeforeMinimumEdge:minimumEdge];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:().
///
/// Is invoked at the time when no item views are visible in this scroll view.
/// Acquires the initial item view from the data source, adds it as a subview
/// to the container view and adds it to the list of visible item views.
// -----------------------------------------------------------------------------
- (UIView*) itemViewWithIndex:(int)index
{
  UIView* itemView = [self.itemScrollViewDataSource itemScrollView:self itemViewAtIndex:index];
  [self.itemContainerView addSubview:itemView];

  NSArray* itemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:index], nil];
  [_visibleItems addObject:itemArray];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaAtMaximumEdge:(CGFloat)maximumVisible
{
  UIView* lastItemView = [self lastVisibleItemView];
  CGFloat maximumEdge;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    maximumEdge = CGRectGetMaxX(lastItemView.frame);
  else
    maximumEdge = CGRectGetMaxY(lastItemView.frame);
  while (maximumEdge < maximumVisible)
  {
    UIView* nextItemView = [self nextItemView];
    if (nil == nextItemView)  // check for bouncing
      break;
    maximumEdge = [self placeItemView:nextItemView withMinimumEdgeAt:maximumEdge];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaAtMaximumEdge:()
// -----------------------------------------------------------------------------
- (UIView*) nextItemView
{
  int indexOfNewItem = [self indexOfLastVisibleItemView] + 1;
  if (indexOfNewItem >= self.numberOfItemsInItemScrollView)  // check for bouncing
    return nil;
  
  UIView* itemView = [self.itemScrollViewDataSource itemScrollView:self itemViewAtIndex:indexOfNewItem];
  [self.itemContainerView addSubview:itemView];
  
  NSArray* newLastItemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:indexOfNewItem], nil];
  [_visibleItems addObject:newLastItemArray];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaAtMaximumEdge:()
// -----------------------------------------------------------------------------
- (CGFloat) placeItemView:(UIView*)itemView withMinimumEdgeAt:(CGFloat)position
{
  CGRect newItemViewFrame = itemView.frame;
  CGFloat newMinimumEdge;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
  {
    newItemViewFrame.origin.x = position;
    newItemViewFrame.origin.y = 0;
    newMinimumEdge = CGRectGetMaxX(newItemViewFrame);
  }
  else
  {
    newItemViewFrame.origin.x = 0;
    newItemViewFrame.origin.y = position;
    newMinimumEdge = CGRectGetMaxY(newItemViewFrame);
  }
  itemView.frame = newItemViewFrame;

  if (self.itemScrollViewDelegate)
  {
    if ([self.itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:willDisplayItemView:)])
      [self.itemScrollViewDelegate itemScrollView:self willDisplayItemView:itemView];
  }

  return newMinimumEdge;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaFromMinimumEdge:(CGFloat)minimumVisible
{
  UIView* firstItemView = [self firstVisibleItemView];
  CGFloat minimumEdge;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    minimumEdge = CGRectGetMinX(firstItemView.frame);
  else
    minimumEdge = CGRectGetMinY(firstItemView.frame);
  while (minimumEdge > minimumVisible)
  {
    UIView* previousItemView = [self previousItemView];
    if (nil == previousItemView)  // check for bouncing
      break;
    minimumEdge = [self placeItemView:previousItemView withMaximumEdgeAt:minimumEdge];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaFromMinimumEdge:().
// -----------------------------------------------------------------------------
- (UIView*) previousItemView
{
  int indexOfNewItem = [self indexOfFirstVisibleItemView] - 1;
  if (indexOfNewItem < 0)  // check for bouncing
    return nil;

  UIView* itemView = [self.itemScrollViewDataSource itemScrollView:self itemViewAtIndex:indexOfNewItem];
  [self.itemContainerView addSubview:itemView];

  NSArray* newFirstItemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:indexOfNewItem], nil];
  [_visibleItems insertObject:newFirstItemArray atIndex:0];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaFromMinimumEdge:()
// -----------------------------------------------------------------------------
- (CGFloat) placeItemView:(UIView*)itemView withMaximumEdgeAt:(CGFloat)position
{
  CGRect newItemViewFrame = itemView.frame;
  CGFloat newMaximumEdge;
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
  {
    newItemViewFrame.origin.x = position - newItemViewFrame.size.width;
    newItemViewFrame.origin.y = 0;
    newMaximumEdge = CGRectGetMinX(newItemViewFrame);
  }
  else
  {
    newItemViewFrame.origin.x = 0;
    newItemViewFrame.origin.y = position - newItemViewFrame.size.height;
    newMaximumEdge = CGRectGetMinY(newItemViewFrame);
  }
  itemView.frame = newItemViewFrame;

  if (self.itemScrollViewDelegate)
  {
    if ([self.itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:willDisplayItemView:)])
      [self.itemScrollViewDelegate itemScrollView:self willDisplayItemView:itemView];
  }

  return newMaximumEdge;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) removeItemsAfterMaximumEdge:(CGFloat)maximumVisible
{
  UIView* lastItemView = [self lastVisibleItemView];
  while (true)
  {
    if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    {
      if (lastItemView.frame.origin.x <= maximumVisible)
        break;
    }
    else
    {
      if (lastItemView.frame.origin.y <= maximumVisible)
        break;
    }
    [lastItemView removeFromSuperview];
    [_visibleItems removeLastObject];
    lastItemView = [self lastVisibleItemView];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) removeItemsBeforeMinimumEdge:(CGFloat)minimumVisible
{
  UIView* firstItemView = [self firstVisibleItemView];
  while (true)
  {
    if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    {
      if (CGRectGetMaxX(firstItemView.frame) >= minimumVisible)
        break;
    }
    else
    {
      if (CGRectGetMaxY(firstItemView.frame) >= minimumVisible)
        break;
    }
    [firstItemView removeFromSuperview];
    [_visibleItems removeObjectAtIndex:0];
    firstItemView = [self firstVisibleItemView];
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture on any item view.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  if (! [self.itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:didTapItemView:)])
    return;
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGPoint tappingLocation = [gestureRecognizer locationInView:self];
  UIView* itemView = [self hitTest:tappingLocation withEvent:nil];
  // Make sure that the tap gesture actually hit an item view and not the
  // container view
  if (-1 == [self indexOfVisibleItemView:itemView])
    return;
  [self.itemScrollViewDelegate itemScrollView:self didTapItemView:itemView];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of the first of the item views that are currently
/// visible in this scroll view.
///
/// Returns -1 if no item views are currently visible.
// -----------------------------------------------------------------------------
- (int) indexOfFirstVisibleItemView
{
  if (0 == _visibleItems.count)
    return -1;
  NSArray* firstItemArray = [_visibleItems objectAtIndex:0];
  NSNumber* firstItemIndex = [firstItemArray lastObject];
  return [firstItemIndex intValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of the last of the item views that are currently
/// visible in this scroll view.
///
/// Returns -1 if no item views are currently visible.
// -----------------------------------------------------------------------------
- (int) indexOfLastVisibleItemView
{
  NSArray* lastItemArray = [_visibleItems lastObject];
  NSNumber* lastItemIndex = [lastItemArray lastObject];
  return [lastItemIndex intValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of visible item view @a view. Returns -1 if @a view
/// is not visible.
// -----------------------------------------------------------------------------
- (int) indexOfVisibleItemView:(UIView*)view
{
  for (NSArray* array in _visibleItems)
  {
    if ([array objectAtIndex:0] == view)
    {
      NSNumber* visibleIndex = [array lastObject];
      return [visibleIndex intValue];
    }
  }
  return -1;
}

// -----------------------------------------------------------------------------
/// @brief Returns the first of the item views that are currently visible in
/// this scroll view.
///
/// Returns nil if no item views are currently visible.
// -----------------------------------------------------------------------------
- (UIView*) firstVisibleItemView
{
  NSArray* firstItemArray = [_visibleItems objectAtIndex:0];
  return [firstItemArray objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Returns the last of the item views that are currently visible in
/// this scroll view.
///
/// Returns nil if no item views are currently visible.
// -----------------------------------------------------------------------------
- (UIView*) lastVisibleItemView
{
  NSArray* lastItemArray = [_visibleItems lastObject];
  return [lastItemArray objectAtIndex:0];
}

// -----------------------------------------------------------------------------
/// @brief Returns the visible item view at index position @a index.
///
/// Returns nil if the item view at index position @a index is not currently not
/// visible.
// -----------------------------------------------------------------------------
- (UIView*) visibleItemViewAtIndex:(int)index
{
  for (NSArray* array in _visibleItems)
  {
    NSNumber* visibleIndex = [array lastObject];
    if ([visibleIndex intValue] == index)
      return [array objectAtIndex:0];
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the item view at index position @a index is before
/// the first of the item views that are currently visible in this scroll view.
/// Returns false otherwise (or if no item views are currently visible).
// -----------------------------------------------------------------------------
- (bool) isBeforeFirstVisibleItemViewIndex:(int)index;
{
  int indexOfFirstVisibleItemView = [self indexOfFirstVisibleItemView];
  if (-1 == indexOfFirstVisibleItemView)
    return false;
  if (index < indexOfFirstVisibleItemView)
    return true;
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the item view at index position @a index is after
/// the last of the item views that are currently visible in this scroll view.
/// Returns false otherwise (or if no item views are currently visible).
// -----------------------------------------------------------------------------
- (bool) isAfterLastVisibleItemViewIndex:(int)index;
{
  int indexOfLastVisibleItemView = [self indexOfLastVisibleItemView];
  if (-1 == indexOfLastVisibleItemView)
    return false;
  if (index > indexOfLastVisibleItemView)
    return true;
  else
    return false;
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of the item view whose frame contains @a position.
// -----------------------------------------------------------------------------
- (int) indexOfItemViewWithFrameContainingPosition:(CGFloat)position
{
  int index = floor(position / [self itemViewExtent]);
  return index;
}

// -----------------------------------------------------------------------------
/// @brief Returns the minimum edge of the item view at index position @a index.
// -----------------------------------------------------------------------------
- (CGFloat) minimumEdgeOfItemViewWithIndex:(int)index
{
  CGFloat minimumEdge = [self itemViewExtent] * index;
  return minimumEdge;
}

// -----------------------------------------------------------------------------
/// @brief Returns the minimum edge of the item view at index position @a index.
// -----------------------------------------------------------------------------
- (CGFloat) maximumEdgeOfItemViewWithIndex:(int)index
{
  CGFloat maximumEdge = (index + 1) * [self itemViewExtent] - 1;
  return maximumEdge;
}

// -----------------------------------------------------------------------------
/// @brief Returns the extent of an item view. The extent is either the width or
/// height of the view, depending on the orientation of the ItemScrollView.
// -----------------------------------------------------------------------------
- (int) itemViewExtent
{
  if (ItemScrollViewOrientationHorizontal == self.itemScrollViewOrientation)
    return [self.itemScrollViewDataSource itemWidthInItemScrollView:self];
  else
    return [self.itemScrollViewDataSource itemHeightInItemScrollView:self];
}

@end
