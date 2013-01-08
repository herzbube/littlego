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
- (UIView*) firstItemView;
- (UIView*) nextItemView;
- (UIView*) previousItemView;
- (CGFloat) placeItemView:(UIView*)itemView withMinimumEdgeAt:(CGFloat)position;
- (CGFloat) placeItemView:(UIView*)itemView withMaximumEdgeAt:(CGFloat)position;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, assign) int numberOfItemsInItemScrollView;
@property(nonatomic, retain) NSMutableArray* visibleItems;
@property(nonatomic, retain) UITapGestureRecognizer* tapRecognizer;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, assign, readwrite) enum ItemScrollViewOrientation itemScrollViewOrientation;
@property(nonatomic, retain, readwrite) UIView* itemContainerView;
//@}
@end


@implementation ItemScrollView

@synthesize itemScrollViewOrientation;
@synthesize itemScrollViewDelegate;
@synthesize itemScrollViewDataSource;
@synthesize numberOfItemsInItemScrollView;
@synthesize visibleItems;
@synthesize tapRecognizer;
@synthesize itemContainerView;


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
  numberOfItemsInItemScrollView = 0;
  visibleItems = [[NSMutableArray alloc] init];
  [self setupItemContainerView];
  [self setupTapGestureRecognizer];

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
/// @brief Reloads everything from scratch.
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
/// @brief Internal helper for reloadData()
// -----------------------------------------------------------------------------
- (void) updateContentSize
{
  numberOfItemsInItemScrollView = [itemScrollViewDataSource numberOfItemsInItemScrollView:self];
  if (ItemScrollViewOrientationHorizontal == itemScrollViewOrientation)
  {
    int itemWidth = [itemScrollViewDataSource itemWidthInItemScrollView:self];
    CGFloat contentWidth = numberOfItemsInItemScrollView * itemWidth;
    self.contentSize = CGSizeMake(contentWidth, self.frame.size.height);
  }
  else
  {
    int itemHeight = [itemScrollViewDataSource itemHeightInItemScrollView:self];
    CGFloat contentHeight = numberOfItemsInItemScrollView * itemHeight;
    self.contentSize = CGSizeMake(self.frame.size.width, contentHeight);
  }
  itemContainerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
}

// -----------------------------------------------------------------------------
/// @brief This overrides the superclass implementation. Triggers acquisition
/// of item views.
// -----------------------------------------------------------------------------
- (void) layoutSubviews
{
  [super layoutSubviews];

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
/// This method is usually invoked because of scrolling. This method checks if
/// new item views have become visible in the visible area. If not, then nothing
/// happens. If yes, the following two-step process is initiated:
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
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaWithMinimumEdge:(CGFloat)minimumEdge maximumEdge:(CGFloat)maximumEdge
{
  // To make the implementation of subsequent steps easier we need to make sure
  // that the array already contains at least one item view
  if (visibleItems.count == 0)
  {
    UIView* itemView = [self firstItemView];
    if (nil == itemView)  // check if data source does not provide any items
      return;
    [self placeItemView:itemView withMinimumEdgeAt:minimumEdge];
  }

  [self updateVisibleAreaAtMaximumEdge:maximumEdge];
  [self updateVisibleAreaFromMinimumEdge:minimumEdge];

  [self removeItemsAfterMaximumEdge:maximumEdge];
  [self removeItemsBeforeMinimumEdge:minimumEdge];
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) updateVisibleAreaAtMaximumEdge:(CGFloat)maximumVisible
{
  NSArray* lastItemArray = [visibleItems lastObject];
  UIView* lastItemView = [lastItemArray objectAtIndex:0];
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
  NSArray* lastItemArray = [visibleItems lastObject];
  NSNumber* lastItemIndex = [lastItemArray lastObject];
  int indexOfNewItem = [lastItemIndex intValue] + 1;
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
  NSArray* firstItemArray = [visibleItems objectAtIndex:0];
  UIView* firstItemView = [firstItemArray objectAtIndex:0];
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
/// @brief Internal helper for updateVisibleAreaFromMinimumEdge:()
// -----------------------------------------------------------------------------
- (UIView*) previousItemView
{
  NSArray* firstItemArray = [visibleItems objectAtIndex:0];
  NSNumber* firstItemIndex = [firstItemArray lastObject];
  int indexOfNewItem = [firstItemIndex intValue] - 1;
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
  NSArray* lastItemArray = [visibleItems lastObject];
  UIView* lastItemView = [lastItemArray objectAtIndex:0];
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
    lastItemArray = [visibleItems lastObject];
    lastItemView = [lastItemArray objectAtIndex:0];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (void) removeItemsBeforeMinimumEdge:(CGFloat)minimumVisible
{
  NSArray* firstItemArray = [visibleItems objectAtIndex:0];
  UIView* firstItemView = [firstItemArray objectAtIndex:0];
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
    firstItemArray = [visibleItems objectAtIndex:0];
    firstItemView = [firstItemArray objectAtIndex:0];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper for updateVisibleAreaWithMinimumEdge:maximumEdge:()
// -----------------------------------------------------------------------------
- (UIView*) firstItemView
{
  if (0 == numberOfItemsInItemScrollView)
    return nil;

  int indexOfItem = 0;
  UIView* itemView = [itemScrollViewDataSource itemScrollView:self itemViewAtIndex:indexOfItem];
  [itemContainerView addSubview:itemView];

  NSArray* itemArray = [NSArray arrayWithObjects:itemView, [NSNumber numberWithInt:indexOfItem], nil];
  [visibleItems addObject:itemArray];

  return itemView;
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

@end
