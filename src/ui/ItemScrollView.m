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


// Project includes
#import "ItemScrollView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for ItemScrollView.
// -----------------------------------------------------------------------------
@interface ItemScrollView()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Overrides from superclass
//@{
- (void) layoutSubviews;
//@}
/// @name Gesture handler
//@{
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer;
//@}
/// @name Helpers
//@{
- (void) setupItemContainerView;
- (void) setupTapGestureRecognizer;
- (void) removeAllVisibleItems;
- (void) resetScrollPosition;
- (void) updateContentSize;
- (void) updateVisibleAreaWithMinimumEdge:(CGFloat)minimumEdge maximumEdge:(CGFloat)maximumEdge;
- (void) updateVisibleAreaAtMaximumEdge:(CGFloat)maximumVisible;
- (void) updateVisibleAreaFromMinimumEdge:(CGFloat)minimumVisible;
- (void) removeItemsAfterMaximumEdge:(CGFloat)maximumVisible;
- (void) removeItemsBeforeMinimumEdge:(CGFloat)maximumVisible;
- (UIView*) itemViewWithIndex:(int)index;
- (UIView*) nextItemView;
- (UIView*) previousItemView;
- (CGFloat) placeItemView:(UIView*)itemView withMinimumEdgeAt:(CGFloat)position;
- (CGFloat) placeItemView:(UIView*)itemView withMaximumEdgeAt:(CGFloat)position;
- (bool) isBeforeFirstVisibleItemViewIndex:(int)index;
- (bool) isAfterLastVisibleItemViewIndex:(int)index;
- (CGPoint) contentOffsetOfItemViewAtMinimumEdgeWithIndex:(int)index;
- (CGPoint) contentOffsetOfItemViewAtMaximumEdgeWithIndex:(int)index;
- (int) indexOfItemViewWithFrameContainingPosition:(CGFloat)position;
- (CGFloat) minimumEdgeOfItemViewWithIndex:(int)index;
- (CGFloat) maximumEdgeOfItemViewWithIndex:(int)index;
- (int) itemViewExtent;
//@}
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

@synthesize itemScrollViewOrientation;
@synthesize itemScrollViewDelegate;
@synthesize itemScrollViewDataSource;
@synthesize visibleItems;
@synthesize tapRecognizer;
@synthesize itemContainerView;
@synthesize numberOfItemsInItemScrollView;


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

  itemScrollViewOrientation = orientation;
  itemScrollViewDelegate = nil;
  itemScrollViewDataSource = nil;
  visibleItems = [[NSMutableArray alloc] init];
  [self setupItemContainerView];
  [self setupTapGestureRecognizer];
  numberOfItemsInItemScrollView = 0;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ItemScrollView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  itemScrollViewDelegate = nil;
  itemScrollViewDataSource = nil;
  // Using self triggers the setter which releases the object
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
  itemContainerView = [[UIView alloc] init];
  itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
  [self addSubview:itemContainerView];

  // Must be enabled so that hit-testing works in handleTapFrom:()
  itemContainerView.userInteractionEnabled = YES;
}

// -----------------------------------------------------------------------------
/// @brief Creates and sets up the gesture recognizer that is used to detect
/// taps on item views.
///
/// This is an internal helper invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupTapGestureRecognizer
{
  self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
	[self.tapRecognizer release];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setItemScrollViewDelegate:(id<ItemScrollViewDelegate>)delegate
{
  if (delegate == itemScrollViewDelegate)
    return;
  itemScrollViewDelegate = delegate;
  if (itemScrollViewDelegate)
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
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setItemScrollViewDataSource:(id<ItemScrollViewDataSource>)dataSource
{
  if (nil == dataSource)
  {
    NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                     reason:@"Data source must not be nil"
                                                   userInfo:nil];
    @throw exception;
  }
  itemScrollViewDataSource = dataSource;
  [self reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Reloads everything from scratch. The scroll position is also reset.
// -----------------------------------------------------------------------------
- (void) reloadData
{
  [self removeAllVisibleItems];
  [self resetScrollPosition];
  [self updateContentSize];
  [self setNeedsLayout];  // force layout update
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for reloadData()
// -----------------------------------------------------------------------------
- (void) removeAllVisibleItems
{
  for (NSArray* itemArray in visibleItems)
  {
    UIView* itemView = [itemArray objectAtIndex:0];
    [itemView removeFromSuperview];
  }
  [visibleItems removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for reloadData()
// -----------------------------------------------------------------------------
- (void) resetScrollPosition
{
  self.contentOffset = CGPointMake(0, 0);
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for reloadData() and updateNumberOfItems().
// -----------------------------------------------------------------------------
- (void) updateContentSize
{
  int newNumberOfItemsInItemScrollView = [itemScrollViewDataSource numberOfItemsInItemScrollView:self];
  if (newNumberOfItemsInItemScrollView == numberOfItemsInItemScrollView)
    return;
  // Use self to trigger KVO
  self.numberOfItemsInItemScrollView = newNumberOfItemsInItemScrollView;
  int itemExtent = [self itemViewExtent];
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
  {
    CGFloat contentWidth = numberOfItemsInItemScrollView * itemExtent;
    self.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
  }
  else
  {
    CGFloat contentHeight = numberOfItemsInItemScrollView * itemExtent;
    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight);
  }
  itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
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
/// the data source is queried for the new item views in the usual manner.
// -----------------------------------------------------------------------------
- (void) updateNumberOfItems
{
  [self updateContentSize];
  // TODO xxx do we need to update content offset? what is UIScrollView doing if
  // the content size is changed? does it reset the content offset? always?
  // or only if the new content size is smaller than the previous size? or does
  // it already do what we want?
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the item view at index position @a index is currently
/// visible in this scroll view.
// -----------------------------------------------------------------------------
- (bool) isVisibleItemViewAtIndex:(int)index
{
  if (0 == visibleItems.count)
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
  if (0 == visibleItems.count || [self isAfterLastVisibleItemViewIndex:index])
  {
    newContentOffset = [self contentOffsetOfItemViewAtMaximumEdgeWithIndex:index];
    if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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

  // Methods that are subsequently invoked no longer check this!
  if (0 == numberOfItemsInItemScrollView)
    return;

  CGRect visibleBounds = [self convertRect:self.bounds toView:itemContainerView];
  CGFloat minimumVisible;
  CGFloat maximumVisible;
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
  if (visibleItems.count == 0)
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
  UIView* itemView = [itemScrollViewDataSource itemScrollView:self itemViewAtIndex:index];
  [itemContainerView addSubview:itemView];

  NSArray* itemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:index], nil];
  [visibleItems addObject:itemArray];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaAtMaximumEdge:(CGFloat)maximumVisible
{
  UIView* lastItemView = [self lastVisibleItemView];
  CGFloat maximumEdge;
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
  if (indexOfNewItem >= numberOfItemsInItemScrollView)  // check for bouncing
    return nil;
  
  UIView* itemView = [itemScrollViewDataSource itemScrollView:self itemViewAtIndex:indexOfNewItem];
  [itemContainerView addSubview:itemView];
  
  NSArray* newLastItemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:indexOfNewItem], nil];
  [visibleItems addObject:newLastItemArray];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaAtMaximumEdge:()
// -----------------------------------------------------------------------------
- (CGFloat) placeItemView:(UIView*)itemView withMinimumEdgeAt:(CGFloat)position
{
  CGRect newItemViewFrame = itemView.frame;
  CGFloat newMinimumEdge;
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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

  if (itemScrollViewDelegate)
  {
    if ([itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:willDisplayItemView:)])
      [itemScrollViewDelegate itemScrollView:self willDisplayItemView:itemView];
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
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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

  UIView* itemView = [itemScrollViewDataSource itemScrollView:self itemViewAtIndex:indexOfNewItem];
  [itemContainerView addSubview:itemView];

  NSArray* newFirstItemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:indexOfNewItem], nil];
  [visibleItems insertObject:newFirstItemArray atIndex:0];

  return itemView;
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaFromMinimumEdge:()
// -----------------------------------------------------------------------------
- (CGFloat) placeItemView:(UIView*)itemView withMaximumEdgeAt:(CGFloat)position
{
  CGRect newItemViewFrame = itemView.frame;
  CGFloat newMaximumEdge;
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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

  if (itemScrollViewDelegate)
  {
    if ([itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:willDisplayItemView:)])
      [itemScrollViewDelegate itemScrollView:self willDisplayItemView:itemView];
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
    if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
    [visibleItems removeLastObject];
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
    if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
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
    [visibleItems removeObjectAtIndex:0];
    firstItemView = [self firstVisibleItemView];
  }
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tapping gesture on any item view.
// -----------------------------------------------------------------------------
- (void) handleTapFrom:(UITapGestureRecognizer*)gestureRecognizer
{
  UIGestureRecognizerState recognizerState = gestureRecognizer.state;
  if (UIGestureRecognizerStateEnded != recognizerState)
    return;
  CGPoint tappingLocation = [gestureRecognizer locationInView:self];
  UIView* itemView = [self hitTest:tappingLocation withEvent:nil];
  if ([itemScrollViewDelegate respondsToSelector:@selector(itemScrollView:didTapItemView:)])
    [itemScrollViewDelegate itemScrollView:self didTapItemView:itemView];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of the first of the item views that are currently
/// visible in this scroll view.
///
/// Returns -1 if no item views are currently visible.
// -----------------------------------------------------------------------------
- (int) indexOfFirstVisibleItemView
{
  if (0 == visibleItems.count)
    return -1;
  NSArray* firstItemArray = [visibleItems objectAtIndex:0];
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
  NSArray* lastItemArray = [visibleItems lastObject];
  NSNumber* lastItemIndex = [lastItemArray lastObject];
  return [lastItemIndex intValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns the index of visible item view @a view. Returns -1 if @a view
/// is not visible.
// -----------------------------------------------------------------------------
- (int) indexOfVisibleItemView:(UIView*)view
{
  for (NSArray* array in visibleItems)
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
  NSArray* firstItemArray = [visibleItems objectAtIndex:0];
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
  NSArray* lastItemArray = [visibleItems lastObject];
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
  for (NSArray* array in visibleItems)
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
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
    return [itemScrollViewDataSource itemWidthInItemScrollView:self];
  else
    return [itemScrollViewDataSource itemHeightInItemScrollView:self];
}

@end
