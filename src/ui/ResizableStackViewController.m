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


// Project includes
#import "ResizableStackViewController.h"
#import "AutoLayoutUtility.h"
#import "UiUtilities.h"


/// @brief Collects information about a child view that is affected by a resize
/// gesture. This is an intermediate struct that is only used when the gesture
/// begins. The information about both child views affected by the resize
/// gesture is summarized in the struct GestureInfo.
struct ChildViewGestureInfo
{
  NSUInteger indexOfChildView;
  CGFloat initialStartEdgeAlongAxis;
  CGFloat initialEndEdgeAlongAxis;
  CGFloat initialExtentAlongAxis;
  CGFloat gestureStartLocationDistanceFromEdge;
  bool gestureStartLocationIsCloserToStartEdge;
};

/// @brief Collects information about a resize gesture.
struct GestureInfo
{
  CGPoint gestureStartLocation;
  NSUInteger indexOfChildView1;
  NSUInteger indexOfChildView2;
  CGFloat initialExtentAlongAxisChildView1;
  CGFloat initialExtentAlongAxisChildView2;
  CGFloat totalExtentAlongAxisToDistribute;
  double totalSizeToDistribute;
};


/// @brief The DragHandleView class is a private helper class of
/// ResizableStackViewController that performs the drawing necessary to render
/// a drag handle.
@interface DragHandleView : UIView
{
}

/// @brief The presentation style with which the drag handle should draw itself.
/// See the ResizableStackViewController property @e dragHandlePresentationStyle
/// for details.
@property (nonatomic, assign) enum DragHandlePresentationStyle dragHandlePresentationStyle;

/// @brief The fill/stroke color which the drag handle should use for drawing
/// in light user interface style (i.e. not dark mode). See the
/// ResizableStackViewController property
/// @e dragHandleColorLightUserInterfaceStyle for details.
@property (nonatomic, retain) UIColor* dragHandleColorLightUserInterfaceStyle;

/// @brief The fill/stroke color which the drag handle should use for drawing
/// in dark user interface style (i.e. dark mode). See the
/// ResizableStackViewController property
/// @e dragHandleColorDarkUserInterfaceStyle for details.
@property (nonatomic, retain) UIColor* dragHandleColorDarkUserInterfaceStyle;

/// @brief The size of an additional margin added to increase the grab area of
/// the drag handle. See the ResizableStackViewController properties
/// @e dragHandleThickness and @e dragHandleGrabAreaMargin for details.
@property (nonatomic, assign) CGFloat dragHandleGrabAreaMargin;

@end


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ResizableStackViewController.
// -----------------------------------------------------------------------------
@interface ResizableStackViewController()
@property (nonatomic, retain) NSArray* arrangingAutoLayoutConstraints;
@property (nonatomic, retain) NSMutableArray* sizingAutoLayoutConstraints;
@property (nonatomic, retain) NSMutableArray* dragHandleViews;
@property (nonatomic, retain) NSMutableArray* dragHandleAutoLayoutConstraints;
@property (nonatomic, retain) NSMutableArray* dragHandleGestureRecognizers;
@property (nonatomic, retain) UILongPressGestureRecognizer* noDragHandleGestureRecognizer;
@property (nonatomic, assign) struct GestureInfo gestureInfo;
@end


@implementation ResizableStackViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a ResizableStackViewController
/// configured to display the views of the child controllers @a viewControllers
/// arranged along the horizontal axis.
// -----------------------------------------------------------------------------
+ (ResizableStackViewController*) resizableStackViewControllerWithViewControllers:(NSArray*)viewControllers
{
  ResizableStackViewController* resizableStackViewController = [[[ResizableStackViewController alloc] init] autorelease];
  resizableStackViewController.viewControllers = viewControllers;
  return resizableStackViewController;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor that returns a ResizableStackViewController
/// configured to display the views of the child controllers @a viewControllers
/// arranged along axis @a axis.
// -----------------------------------------------------------------------------
+ (ResizableStackViewController*) resizableStackViewControllerWithViewControllers:(NSArray*)viewControllers
                                                                             axis:(UILayoutConstraintAxis)axis
{
  ResizableStackViewController* resizableStackViewController = [[[ResizableStackViewController alloc] init] autorelease];
  resizableStackViewController.viewControllers = viewControllers;
  resizableStackViewController.axis = axis;
  return resizableStackViewController;
}

// -----------------------------------------------------------------------------
/// @brief Initializes an ResizableStackViewController object that has no
/// child view controllers and arranges views horizontally.
///
/// @note This is the designated initializer of ResizableStackViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  self.viewControllers = @[];
  self.axis = UILayoutConstraintAxisHorizontal;
  self.sizes = @[];
  self.minimumSizes = @[];
  self.resizingEnabled = true;
  self.resizeStepSize = 100;
  self.dragHandleStyle = DragHandleStyleOverlay;
  self.dragHandlePresentationStyle = DragHandlePresentationStyleBar;
  self.dragHandleColorLightUserInterfaceStyle = [UIColor colorWithWhite:0.0 alpha:0.2f];
  self.dragHandleColorDarkUserInterfaceStyle = [UIColor colorWithWhite:1.0 alpha:0.7f];
  self.dragHandleThickness = 4.0f;
  self.dragHandleGrabAreaMargin = 4.0f;
  self.dragHandleSizePercentageCounterAxis = 0.25f;

  self.arrangingAutoLayoutConstraints = @[];
  self.sizingAutoLayoutConstraints = [NSMutableArray array];
  self.dragHandleViews = [NSMutableArray array];
  self.dragHandleAutoLayoutConstraints = [NSMutableArray array];
  self.dragHandleGestureRecognizers = [NSMutableArray array];
  self.noDragHandleGestureRecognizer = nil;

  struct GestureInfo gestureInfo;
  gestureInfo.gestureStartLocation = CGPointZero;
  self.gestureInfo = gestureInfo;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ResizableStackViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  if (self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
    [self removeSizingAutoLayoutConstraints];
  }
  [self removeArrangingAutoLayoutConstraints];
  [self removeChildViewsFromViewHierarchy];
  [self removeChildViewControllers];

  [_viewControllers release];
  _viewControllers = nil;

  [_sizes release];
  _sizes = nil;

  [_minimumSizes release];
  _minimumSizes = nil;

  [_dragHandleColorLightUserInterfaceStyle release];
  _dragHandleColorLightUserInterfaceStyle = nil;
  [_dragHandleColorDarkUserInterfaceStyle release];
  _dragHandleColorDarkUserInterfaceStyle = nil;

  self.arrangingAutoLayoutConstraints = nil;
  self.sizingAutoLayoutConstraints = nil;
  self.dragHandleViews = nil;
  self.dragHandleAutoLayoutConstraints = nil;
  self.dragHandleGestureRecognizers = nil;
  self.noDragHandleGestureRecognizer = nil;

  [super dealloc];
}

#pragma mark - View controller handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setViewControllers:(NSArray*)viewControllers
{
  if (! viewControllers)
    viewControllers = @[];

  if ([viewControllers isEqualToArray:_viewControllers])
    return;

  [self removeChildViewControllers];

  if (self.isViewLoaded)
  {
    if (self.resizingEnabled)
    {
      [self removeGestureHandling];
      [self removeDragHandles];
      [self removeSizingAutoLayoutConstraints];
    }
    [self removeArrangingAutoLayoutConstraints];
    [self removeChildViewsFromViewHierarchy];
  }

  [_viewControllers release];
  _viewControllers = [[NSArray alloc] initWithArray:viewControllers];

  [self setupChildViewControllers:_viewControllers];

  if (self.isViewLoaded)
  {
    [self addChildViewsToViewHierarchy];
    [self addArrangingAutoLayoutConstraints];
  }

  // Adjust minimum sizes before triggering the sizes property setter
  [self adjustMinimumSizesToNumberOfViewControllers];

  // We let the setter distribute all of the available size (100%) by not
  // specifying any size. The setter also triggers
  // addSizingAutoLayoutConstraints if the view is already loaded.
  self.sizes = @[];

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addDragHandles];
    [self addGestureHandling];
  }
}

// -----------------------------------------------------------------------------
/// @brief Adds all view controllers in @a viewControllers as child view
/// controllers to this controller.
// -----------------------------------------------------------------------------
- (void) setupChildViewControllers:(NSArray*)viewControllers
{
  for (UIViewController* controller in viewControllers)
  {
    // Automatically calls willMoveToParentViewController:
    [self addChildViewController:controller];
    [controller didMoveToParentViewController:self];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes all child view controllers from this controller.
// -----------------------------------------------------------------------------
- (void) removeChildViewControllers
{
  for (UIViewController* controller in self.childViewControllers)
  {
    [controller willMoveToParentViewController:nil];
    // Automatically calls didMoveToParentViewController:
    [controller removeFromParentViewController];
  }
}

#pragma mark - Axis handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setAxis:(UILayoutConstraintAxis)axis
{
  if (axis == _axis)
    return;

  if (self.isViewLoaded)
  {
    [self removeArrangingAutoLayoutConstraints];
    if (self.resizingEnabled)
    {
      [self removeGestureHandling];
      [self removeDragHandles];
      [self removeSizingAutoLayoutConstraints];
    }
  }

  _axis = axis;

  if (self.isViewLoaded)
  {
    [self addArrangingAutoLayoutConstraints];
    if (self.resizingEnabled)
    {
      [self addSizingAutoLayoutConstraints];
      [self addDragHandles];
      [self addGestureHandling];
    }
  }
}

#pragma mark - Sizes handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setSizes:(NSArray*)sizes
{
  sizes = [self validateSizes:sizes];

  if ([sizes isEqualToArray:_sizes])
    return;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
    [self removeSizingAutoLayoutConstraints];
  }

  [_sizes release];
  _sizes = [[NSArray alloc] initWithArray:sizes];

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addSizingAutoLayoutConstraints];
    [self addDragHandles];
    [self addGestureHandling];
  }
}

// -----------------------------------------------------------------------------
/// @brief Validates the data in @a sizes. Returns a new array with the
/// validated and - if necessary - corrected values. See the documentation of
/// the property @e sizes for details.
// -----------------------------------------------------------------------------
- (NSArray*) validateSizes:(NSArray*)sizes
{
  if (! sizes)
    sizes = @[];

  NSMutableArray* validatedSizes = [NSMutableArray array];

  NSUInteger numberOfExplicitlySpecifiedSizes = sizes.count;
  NSUInteger numberOfChildViews = self.viewControllers.count;
  NSUInteger numberOfSizesToKeep = MIN(numberOfExplicitlySpecifiedSizes, numberOfChildViews);
  NSUInteger numberOfMissingSizes = MAX(numberOfChildViews - numberOfExplicitlySpecifiedSizes, 0);
  double remainingSizeToDistribute = 1.0f;

  // Part 1: Validate explicitly specified sizes, but discard if too many were
  // specified
  for (NSUInteger indexOfSize = 0; indexOfSize < numberOfSizesToKeep; ++indexOfSize)
  {
    NSNumber* sizeAsNumber = [sizes objectAtIndex:indexOfSize];
    double size = sizeAsNumber.doubleValue;

    if (size < 0.0f)
    {
      size = 0.0f;
      sizeAsNumber = [NSNumber numberWithDouble:size];
    }
    else
    {
      double minimumSize = [self minimumSizeForChildViewAtIndex:indexOfSize];
      if (size < minimumSize)
      {
        size = minimumSize;
        sizeAsNumber = [NSNumber numberWithDouble:size];
      }
    }

    [validatedSizes addObject:sizeAsNumber];

    remainingSizeToDistribute -= size;
  }

  // Part 2: Generate unspecified sizes by distributing remaining size
  if (numberOfMissingSizes > 0)
  {
    // Generate missing array elements so that the iterative distribution
    // algorithm can work without a special case for the first pass. The
    // elements we generate here must have a size that will never be generated
    // by the distribution algorithm - anything larger than 100% is fine.
    double distributedSizePreviousPass = 1.1;
    NSNumber* sizeAsNumber = [NSNumber numberWithDouble:distributedSizePreviousPass];
    for (NSUInteger indexOfSize = numberOfExplicitlySpecifiedSizes; indexOfSize < numberOfChildViews; ++indexOfSize)
    {
      [validatedSizes addObject:sizeAsNumber];
    }

    bool needAnotherPass = true;
    while (needAnotherPass)
    {
      needAnotherPass = [self distributeMissingSizes:validatedSizes
                                      fromStartIndex:numberOfExplicitlySpecifiedSizes
                           remainingSizeToDistribute:&remainingSizeToDistribute
                                numberOfMissingSizes:&numberOfMissingSizes
                         distributedSizePreviousPass:&distributedSizePreviousPass];
    }
  }

  return validatedSizes;
}

// -----------------------------------------------------------------------------
/// @brief Distributes the amount of space in @a remainingSizeToDistribute among
/// the sizes in @a validatedSizes, in the range starting from @a startIndex
/// until the end of the array. @a remainingSizeToDistribute indicates the
/// number of sizes that still need to receive a value. The algorithm identifes
/// the actual sizes by their values, which must be equal to
/// @a equallyDistributedSizePreviousPass. Returns true if another pass is
/// needed, returns false if distribution is complete and no further passes are
/// needed.
///
/// This method is intended to be invoked iteratively, until it returns false.
/// Each invocation is one pass of the distribution algorithm. On each pass the
/// distribution algorithm replaces elements in @a validatedSizes and adjusts
/// the values of the in/out parameters @a remainingSizeToDistribute,
/// @a numberOfMissingSizes and @a equallyDistributedSizePreviousPass.
///
/// See the documentation of the property @e sizes for details.
// -----------------------------------------------------------------------------
- (bool) distributeMissingSizes:(NSMutableArray*)validatedSizes
                 fromStartIndex:(NSUInteger)startIndex
      remainingSizeToDistribute:(double*)remainingSizeToDistribute
           numberOfMissingSizes:(NSUInteger*)numberOfMissingSizes
    distributedSizePreviousPass:(double*)equallyDistributedSizePreviousPass
{
  // Defensive programming, but should not actually be necessary in the current
  // implementation
  if (*numberOfMissingSizes == 0)
    return false;

  double equallyDistributedSizeThisPass = 0.0f;
  double lastDistributedSizeThisPass = 0.0f;

  // The remaining size to distribute decreases continuously in each pass, but
  // may already be zero in the first pass if explicitly specified sizes use up
  // all the available size.
  // Note: In the current implementation the remaining size may become less
  // than zero!
  if (*remainingSizeToDistribute > 0.0f)
  {
    equallyDistributedSizeThisPass = *remainingSizeToDistribute / *numberOfMissingSizes;

    // The division may have left us with an arbitrary number of fractional
    // digits, so we round to make sure that the number of fractional digits
    // is reasonable and will not cause unsatisfiable constraints.
    // Note: Rounding is now more cosmetic than an actual necessity. Originally
    // child views were arranged by connecting them to their superview edges
    // like this:
    //   "H/V:-0-[view0]-0-[view1]-0- ... -0-|"
    // This caused the UIKit layout engine to issue warnings due to
    // unsatisfiable constraints. It was thought that the warnings could be
    // avoided by using less fractional digits, but although they became less
    // frequent ultimately there were still cases where they occurred. The
    // only sure way to avoid the warnings was to remove the connecting part
    // "-0-|" at the end of the visual format (see
    // addArrangingAutoLayoutConstraints). The rounding here was kept so that
    // users of ResizableStackViewController would not see ugly numbers like
    // 0.333333...
    equallyDistributedSizeThisPass = [self roundSize:equallyDistributedSizeThisPass steps:100];

    // If equallyDistributedSizeThisPass was actually rounded then we can't just
    // use the rounded value for all sizes, or we will end up with either more
    // or less size being distributed than was actually available (which one
    // it is depends on whether equallyDistributedSizeThisPass was rounded up or
    // down). To compensate for the rounding we therefore adjust the last size
    // that we distribute to be slightly larger or smaller than the other sizes.
    lastDistributedSizeThisPass = *remainingSizeToDistribute - equallyDistributedSizeThisPass * (*numberOfMissingSizes - 1);
  }

  bool minimumSizeDidOverride = false;
  NSUInteger numberOfSizes = validatedSizes.count;
  bool atLeastOneSizeWasDistributedInThisPass = false;
  NSUInteger indexOfLastDistributedSize = 0;

  // Iteration only touches sizes that are generated by the distribution
  // algorithm. The first of these sizes is at startIndex. Explicitly specified
  // sizes are not touched, which is important, for instance, for comparing
  // sizes with equallyDistributedSizePreviousPass.
  for (NSUInteger indexOfSize = startIndex; indexOfSize < numberOfSizes; ++indexOfSize)
  {
    NSNumber* sizeAsNumber = [validatedSizes objectAtIndex:indexOfSize];
    double size = sizeAsNumber.doubleValue;

    // We recognize sizes that need to be re-distributed by the value we gave
    // them in the previous pass. This cannot match other sizes because the
    // size to distribute becomes smaller with each pass.
    if (size != *equallyDistributedSizePreviousPass)
      continue;

    size = equallyDistributedSizeThisPass;

    double minimumSize = [self minimumSizeForChildViewAtIndex:indexOfSize];
    if (size < minimumSize)
    {
      size = minimumSize;

      minimumSizeDidOverride = true;

      // We almost certainly need another pass => decrease the remaining size
      // to distribute in the next pass, as well as the number of sizes that
      // still need a value
      *remainingSizeToDistribute -= minimumSize;
      *numberOfMissingSizes -= 1;
    }
    else
    {
      atLeastOneSizeWasDistributedInThisPass = true;
      indexOfLastDistributedSize = indexOfSize;
    }

    sizeAsNumber = [NSNumber numberWithDouble:size];
    [validatedSizes replaceObjectAtIndex:indexOfSize withObject:sizeAsNumber];
  }

  *equallyDistributedSizePreviousPass = equallyDistributedSizeThisPass;

  // Another pass is not needed if one of the following applies:
  // 1) The current pass succeeded in distributing sizes without hitting any
  //    minimum size override (minimumSizeDidOverride is false).
  // 2) The current pass, and all the previous passes, failed to distribute
  //    sizes without hitting any minimum size overrides. Effectively all sizes
  //    were determined by their minimum size (numberOfMissingSizes == 0)
  //    and we don't need further attempts at distribution.
  //
  // Another pass is needed if this pass hit a minimum size override
  // (minimumSizeDidOverride is true), but there is still at least one size left
  // which could be distributed (minimumSizeDidOverride != 0).
  bool needAnotherPass = numberOfMissingSizes == 0 ? false : minimumSizeDidOverride;
  needAnotherPass = ! minimumSizeDidOverride ? false : numberOfMissingSizes == 0;

  // Perform this final rounding adjustment only in the last pass. If we did
  // this in each pass then on the next pass the comparison with
  // equallyDistributedSizePreviousPass would fail.
  if (! needAnotherPass && atLeastOneSizeWasDistributedInThisPass)
  {
    double minimumSizeOfLastDistributedSize = [self minimumSizeForChildViewAtIndex:indexOfLastDistributedSize];
    if (lastDistributedSizeThisPass > minimumSizeOfLastDistributedSize)
    {
      [validatedSizes removeLastObject];
      NSNumber* lastDistributedSizeThisPassAsNumber = [NSNumber numberWithDouble:lastDistributedSizeThisPass];
      [validatedSizes addObject:lastDistributedSizeThisPassAsNumber];
    }
  }

  return needAnotherPass;
}

// -----------------------------------------------------------------------------
/// @brief Rounds @a size to the nearest "one @a steps'th" value.
///
/// If @a steps has a "10 to the power of <n>" value then the rounding causes
/// fractional digits to be truncated after the one that matches the exponent
/// <n>.
///
/// Examples:
/// - If @a steps is 10 then the rounding is to the nearest one tenth.
///   For instance 0.15 is rounded to 0.2.
/// - If @a steps is 20 then the rounding is to the nearest one twentieth.
///   For instance 0.125 is rounded to 0.15.
/// - If @a steps is 100 then the rounding is to the nearest one hundredth.
///   For instance 0.015 is rounded to 0.02.
/// - Etc.
// -----------------------------------------------------------------------------
- (double) roundSize:(double)size steps:(int)steps
{
  return round(size * steps) / steps;
}

// -----------------------------------------------------------------------------
/// @brief Returns the size of the view of the child view controller at the
/// index position @a indexOfChildView.
// -----------------------------------------------------------------------------
- (double) sizeForChildViewAtIndex:(NSUInteger)indexOfChildView
{
  NSNumber* sizeAsNumber = [self.sizes objectAtIndex:indexOfChildView];
  return sizeAsNumber.doubleValue;
}

// -----------------------------------------------------------------------------
/// @brief Resizes the views of the two child view controllers at the index
/// position @a indexOfChildView1 and  @a indexOfChildView2 to the new sizes
/// @a newSizeChildView1 and @a newSizeChildView2, respectively. Sizing
/// constraints are also updated.
///
/// This method expects that one of the two size values increases the size of
/// its corresponding view by an amount <n>, while the other decreases the size
/// of its corresponding view by the equal amount <n>.
///
/// If the size that is decreased falls below the minimum size of its
/// corresponding view it is increased back to the minimum size. The other size
/// is decreased accordingly so that the sum of the two sizes remains the same.
///
/// If after all adjustments are made the new sizes are the same as the old
/// sizes, this method does nothing.
///
/// This method is a helper for interactive resizing.
// -----------------------------------------------------------------------------
- (void) resizeChildView1AtIndex:(NSUInteger)indexOfChildView1
                          toSize:(double)newSizeChildView1
               childView2AtIndex:(NSUInteger)indexOfChildView2
                          toSize:(double)newSizeChildView2
{
  double oldSizeChildView1 = [self sizeForChildViewAtIndex:indexOfChildView1];
  double oldSizeChildView2 = [self sizeForChildViewAtIndex:indexOfChildView2];

  // One of the two views is becoming smaller => check if it becomes smaller
  // than the minimum size. If yes then we snap back its new size to the minimum
  // size, but we must also adjust the new size of the other view by the amount
  // that we snapped back.
  if (newSizeChildView1 < oldSizeChildView1)
  {
    double minimumSizeChildView1 = [self minimumSizeForChildViewAtIndex:indexOfChildView1];
    if (newSizeChildView1 < minimumSizeChildView1)
    {
      double snapBackSize = minimumSizeChildView1 - newSizeChildView1;
      newSizeChildView1 = minimumSizeChildView1;
      newSizeChildView2 -= snapBackSize;
    }
  }
  else
  {
    double minimumSizeChildView2 = [self minimumSizeForChildViewAtIndex:indexOfChildView2];
    if (newSizeChildView2 < minimumSizeChildView2)
    {
      double snapBackSize = minimumSizeChildView2 - newSizeChildView2;
      newSizeChildView2 = minimumSizeChildView2;
      newSizeChildView1 -= snapBackSize;
    }
  }

  bool childView1WillChangeSize = oldSizeChildView1 != newSizeChildView1;
  bool childView2WillChangeSize = oldSizeChildView2 != newSizeChildView2;
  if (! childView1WillChangeSize && ! childView2WillChangeSize)
    return;

  // The NSLayoutConstraint property multiplier is readonly, so new constraints
  // must be created. Make sure to deactivate BOTH of the old constraints first
  // to minimize the chance of getting a warning about unsatisfiable
  // constraints.
  if (childView1WillChangeSize)
  {
    NSLayoutConstraint* oldSizingConstraintChildView1 = [_sizingAutoLayoutConstraints objectAtIndex:indexOfChildView1];
    oldSizingConstraintChildView1.active = NO;
  }
  if (childView2WillChangeSize)
  {
    NSLayoutConstraint* oldSizingConstraintChildView2 = [_sizingAutoLayoutConstraints objectAtIndex:indexOfChildView2];
    oldSizingConstraintChildView2.active = NO;
  }

  NSMutableArray* newSizes = [NSMutableArray arrayWithArray:self.sizes];

  if (childView1WillChangeSize)
  {
    newSizes[indexOfChildView1] = [NSNumber numberWithDouble:newSizeChildView1];
    NSLayoutConstraint* newSizingConstraintChildView1 = [self createSizingConstraintForChildViewAtIndex:indexOfChildView1
                                                                                                   size:newSizeChildView1];
    _sizingAutoLayoutConstraints[indexOfChildView1] = newSizingConstraintChildView1;
  }
  if (childView2WillChangeSize)
  {
    newSizes[indexOfChildView2] = [NSNumber numberWithDouble:newSizeChildView2];
    NSLayoutConstraint* newSizingConstraintChildView2 = [self createSizingConstraintForChildViewAtIndex:indexOfChildView2
                                                                                                   size:newSizeChildView2];
    _sizingAutoLayoutConstraints[indexOfChildView2] = newSizingConstraintChildView2;
  }

  // Don't trigger the setter because it recreates constraints for all child
  // views
  [_sizes release];
  [newSizes retain];
  _sizes = newSizes;
}

#pragma mark - Minimum sizes handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setMinimumSizes:(NSArray*)minimumSizes
{
  minimumSizes = [self validateMinimumSizes:minimumSizes];

  if ([minimumSizes isEqualToArray:_minimumSizes])
    return;

  [_minimumSizes release];
  _minimumSizes = [[NSArray alloc] initWithArray:minimumSizes];
}

// -----------------------------------------------------------------------------
/// @brief Validates the data in @a minimumSizes. Returns a new array with the
/// validated and - if necessary - corrected values. See the documentation of
/// the property @e minimumSizes for details.
// -----------------------------------------------------------------------------
- (NSArray*) validateMinimumSizes:(NSArray*)minimumSizes
{
  if (! minimumSizes)
    minimumSizes = @[];

  NSMutableArray* validatedMinimumSizes = [NSMutableArray array];

  NSUInteger numberOfExplicitlySpecifiedMinimumSizes = minimumSizes.count;
  NSUInteger numberOfChildViews = self.viewControllers.count;
  NSUInteger numberOfMinimumSizesToKeep = MIN(numberOfExplicitlySpecifiedMinimumSizes, numberOfChildViews);
  NSUInteger numberOfMissingMinimumSizes = MAX(numberOfChildViews - numberOfExplicitlySpecifiedMinimumSizes, 0);

  // Part 1: Validate explicitly specified minimum sizes, but discard if too
  // many were specified
  for (NSUInteger indexOfMinimumSize = 0; indexOfMinimumSize < numberOfMinimumSizesToKeep; ++indexOfMinimumSize)
  {
    NSNumber* minimumSizeAsNumber = [minimumSizes objectAtIndex:indexOfMinimumSize];
    double minimumSize = minimumSizeAsNumber.doubleValue;

    if (minimumSize < 0.0f)
    {
      minimumSize = 0.0f;
      minimumSizeAsNumber = [NSNumber numberWithDouble:minimumSize];
    }

    [validatedMinimumSizes addObject:minimumSizeAsNumber];
  }

  // Part 2: Generate unspecified minimum sizes
  if (numberOfMissingMinimumSizes > 0)
  {
    NSNumber* zeroMinimumSizeAsNumber = [NSNumber numberWithDouble:0.0f];

    while (numberOfMissingMinimumSizes > 0)
    {
      [validatedMinimumSizes addObject:zeroMinimumSizeAsNumber];
      numberOfMissingMinimumSizes--;
    }
  }

  return validatedMinimumSizes;
}

// -----------------------------------------------------------------------------
/// @brief Returns the minimum size of the view of the child view controller at
/// the index position @a indexOfChildView.
// -----------------------------------------------------------------------------
- (double) minimumSizeForChildViewAtIndex:(NSUInteger)indexOfChildView
{
  NSNumber* minimumSizeAsNumber = [self.minimumSizes objectAtIndex:indexOfChildView];
  return minimumSizeAsNumber.doubleValue;
}

// -----------------------------------------------------------------------------
/// @brief Adjusts the value of the @e minimumSizes property so that it holds
/// the same number of elements as the value of the property @e viewControllers.
/// Minimum size values are created or discarded according to the documentation
/// of the @e viewControllers property.
// -----------------------------------------------------------------------------
- (void) adjustMinimumSizesToNumberOfViewControllers
{
  NSUInteger numberOfMinimumSizes = self.minimumSizes.count;
  NSUInteger numberOfViewControllers = self.viewControllers.count;
  if (numberOfMinimumSizes == numberOfViewControllers)
    return;

  NSMutableArray* newMinimumSizes = [NSMutableArray arrayWithArray:self.minimumSizes];

  if (numberOfMinimumSizes < numberOfViewControllers)
  {
    NSUInteger numberOfMissingMinimumSizes = numberOfViewControllers - numberOfMinimumSizes;
    while (numberOfMissingMinimumSizes > 0)
    {
      [newMinimumSizes addObject:[NSNumber numberWithDouble:0.0f]];
      numberOfMissingMinimumSizes--;
    }
  }
  else
  {
    NSUInteger numberOfSurplusMinimumSizes = numberOfMinimumSizes- numberOfViewControllers;
    while (numberOfSurplusMinimumSizes > 0)
    {
      [newMinimumSizes removeLastObject];
      numberOfSurplusMinimumSizes--;
    }
  }

  self.minimumSizes = newMinimumSizes;
}

#pragma mark - Allowing/disallowing resizing handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setResizingEnabled:(bool)resizingEnabled
{
  if (resizingEnabled == _resizingEnabled)
    return;

  _resizingEnabled = resizingEnabled;

  if (self.isViewLoaded)
  {
    if (! resizingEnabled)
    {
      [self removeGestureHandling];
      [self removeDragHandles];
      [self removeSizingAutoLayoutConstraints];
    }

    // The arranging constraints also change slightly when this property changes
    [self removeArrangingAutoLayoutConstraints];
    [self addArrangingAutoLayoutConstraints];

    if (resizingEnabled)
    {
      [self addSizingAutoLayoutConstraints];
      [self addDragHandles];
      [self addGestureHandling];
    }
  }
}

#pragma mark - Drag handle style handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleStyle:(enum DragHandleStyle)dragHandleStyle
{
  if (dragHandleStyle == _dragHandleStyle)
    return;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
  }

  _dragHandleStyle = dragHandleStyle;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addDragHandles];
    [self addGestureHandling];
  }
}

#pragma mark - Drag handle presentation handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandlePresentationStyle:(enum DragHandlePresentationStyle)dragHandlePresentationStyle
{
  if (dragHandlePresentationStyle == _dragHandlePresentationStyle)
    return;

  _dragHandlePresentationStyle = dragHandlePresentationStyle;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    for (DragHandleView* dragHandleView in self.dragHandleViews)
      dragHandleView.dragHandlePresentationStyle = dragHandlePresentationStyle;
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleColorLightUserInterfaceStyle:(UIColor*)dragHandleColorLightUserInterfaceStyle
{
  if (dragHandleColorLightUserInterfaceStyle == _dragHandleColorLightUserInterfaceStyle)
    return;

  if (_dragHandleColorLightUserInterfaceStyle)
    [_dragHandleColorLightUserInterfaceStyle release];

  _dragHandleColorLightUserInterfaceStyle = dragHandleColorLightUserInterfaceStyle;

  if (dragHandleColorLightUserInterfaceStyle)
    [dragHandleColorLightUserInterfaceStyle retain];

  if (self.isViewLoaded && self.resizingEnabled)
  {
    for (DragHandleView* dragHandleView in self.dragHandleViews)
      dragHandleView.dragHandleColorLightUserInterfaceStyle = dragHandleColorLightUserInterfaceStyle;
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleColorDarkUserInterfaceStyle:(UIColor*)dragHandleColorDarkUserInterfaceStyle
{
  if (dragHandleColorDarkUserInterfaceStyle == _dragHandleColorDarkUserInterfaceStyle)
    return;

  if (_dragHandleColorDarkUserInterfaceStyle)
    [_dragHandleColorDarkUserInterfaceStyle release];

  _dragHandleColorDarkUserInterfaceStyle = dragHandleColorDarkUserInterfaceStyle;

  if (dragHandleColorDarkUserInterfaceStyle)
    [dragHandleColorDarkUserInterfaceStyle retain];

  if (self.isViewLoaded && self.resizingEnabled)
  {
    for (DragHandleView* dragHandleView in self.dragHandleViews)
      dragHandleView.dragHandleColorDarkUserInterfaceStyle = dragHandleColorDarkUserInterfaceStyle;
  }
}

#pragma mark - Drag handle size handling

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleThickness:(CGFloat)dragHandleThickness
{
  if (dragHandleThickness == _dragHandleThickness)
    return;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
  }

  _dragHandleThickness = dragHandleThickness;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addDragHandles];
    [self addGestureHandling];
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleGrabAreaMargin:(CGFloat)dragHandleGrabAreaMargin
{
  if (dragHandleGrabAreaMargin == _dragHandleGrabAreaMargin)
    return;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
  }

  _dragHandleGrabAreaMargin = dragHandleGrabAreaMargin;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addDragHandles];
    [self addGestureHandling];
  }
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleSizePercentageCounterAxis:(CGFloat)dragHandleSizePercentageCounterAxis
{
  if (dragHandleSizePercentageCounterAxis == _dragHandleSizePercentageCounterAxis)
    return;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self removeGestureHandling];
    [self removeDragHandles];
  }

  _dragHandleSizePercentageCounterAxis = dragHandleSizePercentageCounterAxis;

  if (self.isViewLoaded && self.resizingEnabled)
  {
    [self addDragHandles];
    [self addGestureHandling];
  }
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self addChildViewsToViewHierarchy];
  [self addArrangingAutoLayoutConstraints];

  if (self.resizingEnabled)
  {
    [self addSizingAutoLayoutConstraints];
    [self addDragHandles];
    [self addGestureHandling];
  }
}

#pragma mark - Child view handling

// -----------------------------------------------------------------------------
/// @brief Adds the views of all child view controllers as subviews to the view
/// of this view controller.
// -----------------------------------------------------------------------------
- (void) addChildViewsToViewHierarchy
{
  for (UIViewController* childViewController in self.viewControllers)
  {
    [self.view addSubview:childViewController.view];
  }
}

// -----------------------------------------------------------------------------
/// @brief Removes the views of all child view controllers from the view of this
/// view controller.
// -----------------------------------------------------------------------------
- (void) removeChildViewsFromViewHierarchy
{
  for (UIViewController* childViewController in self.viewControllers)
  {
    [childViewController.view removeFromSuperview];
  }
}

#pragma mark - Auto layout constraint handling

// -----------------------------------------------------------------------------
/// @brief Creates the auto layout constraints that arrange the views of all
/// child view controllers along the current axis.
// -----------------------------------------------------------------------------
- (void) addArrangingAutoLayoutConstraints
{
  NSArray* viewControllers = self.viewControllers;
  NSUInteger numberOfChildViews = viewControllers.count;
  if (numberOfChildViews == 0)
    return;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionary];
  NSMutableArray* visualFormats = [NSMutableArray array];

  NSString* visualFormatAlongArrangedAxis = self.axis == UILayoutConstraintAxisHorizontal ? @"H:|-0-" : @"V:|-0-";
  NSString* visualFormatPrefixAlongOtherAxis = self.axis == UILayoutConstraintAxisHorizontal ? @"V:" : @"H:";

  for (int indexOfChildView = 0; indexOfChildView < numberOfChildViews; ++indexOfChildView)
  {
    UIViewController* childViewController = [viewControllers objectAtIndex:indexOfChildView];
    UIView* childView = childViewController.view;

    childView.translatesAutoresizingMaskIntoConstraints = NO;

    NSString* viewName = [NSString stringWithFormat:@"childView%d", indexOfChildView];
    viewsDictionary[viewName] = childView;

    visualFormatAlongArrangedAxis = [visualFormatAlongArrangedAxis stringByAppendingFormat:@"[%@]-0-", viewName];
    [visualFormats addObject:[visualFormatPrefixAlongOtherAxis stringByAppendingFormat:@"|-0-[%@]-0-|", viewName]];
  }

  // When sizing constraints are created we don't want to connect the last
  // child view to the superview edge, because this can trigger the following
  // warning (displayed in the Xcode debug view):
  //   Unable to simultaneously satisfy constraints
  // The warning is probably due to rounding errors accumulating so that the
  // child views try to occupy slightly less or more than 100% of the size of
  // their superview along the arrange axis.
  if (! self.resizingEnabled)
    [visualFormats addObject:[visualFormatAlongArrangedAxis stringByAppendingString:@"|"]];
  else
    [visualFormats addObject:[visualFormatAlongArrangedAxis substringWithRange:NSMakeRange(0, visualFormatAlongArrangedAxis.length - @"-0-".length)]];

  self.arrangingAutoLayoutConstraints = [AutoLayoutUtility installVisualFormats:visualFormats
                                                                      withViews:viewsDictionary
                                                                         inView:self.view];
}

// -----------------------------------------------------------------------------
/// @brief Removes the auto layout constraints that arrange the views of all
/// child view controllers along the current axis.
// -----------------------------------------------------------------------------
- (void) removeArrangingAutoLayoutConstraints
{
  if (self.arrangingAutoLayoutConstraints.count == 0)
    return;

  for (NSLayoutConstraint* arrangingConstraint in self.arrangingAutoLayoutConstraints)
  {
    arrangingConstraint.active = NO;
  }

  self.arrangingAutoLayoutConstraints = @[];
}

// -----------------------------------------------------------------------------
/// @brief Creates the auto layout constraints that size the views of all
/// child view controllers along the current axis.
// -----------------------------------------------------------------------------
- (void) addSizingAutoLayoutConstraints
{
  NSArray* sizes = self.sizes;
  NSUInteger numberOfSizes = sizes.count;
  if (numberOfSizes == 0)
    return;

  NSMutableArray* sizingAutoLayoutConstraints = [NSMutableArray array];

  for (int indexOfSize = 0; indexOfSize < numberOfSizes; ++indexOfSize)
  {
    NSNumber* sizeAsNumber = [sizes objectAtIndex:indexOfSize];
    double size = sizeAsNumber.doubleValue;

    NSLayoutConstraint* sizingConstraint = [self createSizingConstraintForChildViewAtIndex:indexOfSize
                                                                                      size:size];

    [sizingAutoLayoutConstraints addObject:sizingConstraint];
  }

  self.sizingAutoLayoutConstraints = sizingAutoLayoutConstraints;
}

// -----------------------------------------------------------------------------
/// @brief Creates the sizing Auto Layout constraint for the view of the child
/// view controller at the index position @a indexOfChildView. @a size is the
/// multiplier to be used by the constraint.
// -----------------------------------------------------------------------------
- (NSLayoutConstraint*) createSizingConstraintForChildViewAtIndex:(NSUInteger)indexOfChildView
                                                             size:(double)size
{
  NSLayoutAttribute sizeAttribute = self.axis == UILayoutConstraintAxisHorizontal ? NSLayoutAttributeWidth : NSLayoutAttributeHeight;

  UIViewController* childViewController = [self.viewControllers objectAtIndex:indexOfChildView];
  UIView* childView = childViewController.view;

  NSLayoutConstraint* sizingConstraint = [AutoLayoutUtility alignFirstView:childView
                                                            withSecondView:self.view
                                                               onAttribute:sizeAttribute
                                                            withMultiplier:size
                                                          constraintHolder:self.view];

  return sizingConstraint;
}

/// -----------------------------------------------------------------------------
/// @brief Removes the auto layout constraints that size the views of all
/// child view controllers along the current axis.
// -----------------------------------------------------------------------------
- (void) removeSizingAutoLayoutConstraints
{
  if (self.sizingAutoLayoutConstraints.count == 0)
    return;

  for (NSLayoutConstraint* sizingConstraint in self.sizingAutoLayoutConstraints)
  {
    sizingConstraint.active = NO;
  }

  self.arrangingAutoLayoutConstraints = [NSMutableArray array];
}

#pragma mark - Drag handle view handling

// -----------------------------------------------------------------------------
/// @brief Adds drag handles according to the currently used style. Both views
/// and their Auto Layout constraints are created.
// -----------------------------------------------------------------------------
- (void) addDragHandles
{
  if (self.dragHandleStyle == DragHandleStyleNone)
    return;

  NSArray* viewControllers = self.viewControllers;
  NSUInteger numberOfChildViews = viewControllers.count;
  NSUInteger numberOfDragHandles = numberOfChildViews - 1;
  if (numberOfDragHandles <= 0)
    return;

  NSMutableArray* dragHandleAutoLayoutConstraints = [NSMutableArray array];

  for (int indexOfChildView = 0; indexOfChildView < numberOfDragHandles; ++indexOfChildView)
  {
    UIViewController* childViewController = [viewControllers objectAtIndex:indexOfChildView];
    UIView* childView = childViewController.view;

    UIView* dragHandleView = [self createDragHandleView];
    [self.dragHandleViews addObject:dragHandleView];

    [self.view addSubview:dragHandleView];
    NSArray* constraints = [self createAutoLayoutConstraintsForDragHandleView:dragHandleView afterChildView:childView];
    [dragHandleAutoLayoutConstraints addObjectsFromArray:constraints];
  }

  self.dragHandleAutoLayoutConstraints = dragHandleAutoLayoutConstraints;
}

// -----------------------------------------------------------------------------
/// @brief Removes drag handles. Both views and their Auto Layout constraints
/// are removed.
// -----------------------------------------------------------------------------
- (void) removeDragHandles
{
  if (self.dragHandleStyle == DragHandleStyleNone)
    return;

  for (UIView* dragHandleView in self.dragHandleViews)
  {
    [dragHandleView removeFromSuperview];
  }
  [self.dragHandleViews removeAllObjects];

  for (NSLayoutConstraint* constraint in self.dragHandleAutoLayoutConstraints)
  {
    constraint.active = NO;
  }
  [self.dragHandleAutoLayoutConstraints removeAllObjects];
}

// -----------------------------------------------------------------------------
/// @brief Creates a drag handle view according to the currently used style.
// -----------------------------------------------------------------------------
- (UIView*) createDragHandleView
{
  if (self.dragHandleStyle == DragHandleStyleNone)
    return nil;

  DragHandleView* dragHandleView = [[[DragHandleView alloc] initWithFrame:CGRectZero] autorelease];
  dragHandleView.dragHandlePresentationStyle = self.dragHandlePresentationStyle;
  dragHandleView.dragHandleColorLightUserInterfaceStyle = self.dragHandleColorLightUserInterfaceStyle;
  dragHandleView.dragHandleColorDarkUserInterfaceStyle = self.dragHandleColorDarkUserInterfaceStyle;
  dragHandleView.dragHandleGrabAreaMargin = self.dragHandleGrabAreaMargin;

  return dragHandleView;
}

// -----------------------------------------------------------------------------
/// @brief Creates the Auto Layout constraints for the drag handle view
/// @a dragHandleView, which should be positioned so that it appears after
/// @a childView along the current axis.
// -----------------------------------------------------------------------------
- (NSArray*) createAutoLayoutConstraintsForDragHandleView:(UIView*)dragHandleView
                                           afterChildView:(UIView*)childView
{
  dragHandleView.translatesAutoresizingMaskIntoConstraints = NO;

  UIView* referenceViewPositioningAlongAxis = childView;
  UIView* referenceViewPositioningCounterAxis = dragHandleView.superview;

  NSLayoutAttribute dragHandleViewAttributeSizingThickness;
  NSLayoutAttribute dragHandleViewAttributeSizingCounterAxis;
  NSLayoutAttribute dragHandleViewAttributePositioningAlongAxis;
  NSLayoutAttribute referenceViewAttributePositioningAlongAxis;
  NSLayoutAttribute dragHandleViewAttributePositioningCounterAxis;
  NSLayoutAttribute referenceViewAttributePositioningCounterAxis;
  if (self.axis == UILayoutConstraintAxisHorizontal)
  {
    dragHandleViewAttributeSizingThickness = NSLayoutAttributeWidth;
    dragHandleViewAttributeSizingCounterAxis = NSLayoutAttributeHeight;
    dragHandleViewAttributePositioningAlongAxis = NSLayoutAttributeCenterX;
    referenceViewAttributePositioningAlongAxis = NSLayoutAttributeRight;
    dragHandleViewAttributePositioningCounterAxis = NSLayoutAttributeCenterY;
    referenceViewAttributePositioningCounterAxis = NSLayoutAttributeCenterY;
  }
  else
  {
    dragHandleViewAttributeSizingThickness = NSLayoutAttributeHeight;
    dragHandleViewAttributeSizingCounterAxis = NSLayoutAttributeWidth;
    dragHandleViewAttributePositioningAlongAxis = NSLayoutAttributeCenterY;
    referenceViewAttributePositioningAlongAxis = NSLayoutAttributeBottom;
    dragHandleViewAttributePositioningCounterAxis = NSLayoutAttributeCenterX;
    referenceViewAttributePositioningCounterAxis = NSLayoutAttributeCenterX;
  }

  CGFloat totalThickness = self.dragHandleThickness + 2 * self.dragHandleGrabAreaMargin;
  NSLayoutConstraint* constraintSizingThickness = [NSLayoutConstraint constraintWithItem:dragHandleView
                                                                               attribute:dragHandleViewAttributeSizingThickness
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1.0f
                                                                                constant:totalThickness];
  constraintSizingThickness.active = YES;
  NSLayoutConstraint* constraintSizingCounterAxis = [NSLayoutConstraint constraintWithItem:dragHandleView
                                                                                 attribute:dragHandleViewAttributeSizingCounterAxis
                                                                                 relatedBy:NSLayoutRelationEqual
                                                                                    toItem:dragHandleView.superview
                                                                                 attribute:dragHandleViewAttributeSizingCounterAxis
                                                                                multiplier:self.dragHandleSizePercentageCounterAxis
                                                                                  constant:0.0f];
  constraintSizingCounterAxis.active = YES;


  NSLayoutConstraint* constraintPositioningAlongAxis = [NSLayoutConstraint constraintWithItem:dragHandleView
                                                                                    attribute:dragHandleViewAttributePositioningAlongAxis
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:referenceViewPositioningAlongAxis
                                                                                    attribute:referenceViewAttributePositioningAlongAxis
                                                                                   multiplier:1.0f
                                                                                     constant:0.0f];
  constraintPositioningAlongAxis.active = YES;
  NSLayoutConstraint* constraintPositioningCounterAxis = [NSLayoutConstraint constraintWithItem:dragHandleView
                                                                                    attribute:dragHandleViewAttributePositioningCounterAxis
                                                                                    relatedBy:NSLayoutRelationEqual
                                                                                       toItem:referenceViewPositioningCounterAxis
                                                                                    attribute:referenceViewAttributePositioningCounterAxis
                                                                                   multiplier:1.0f
                                                                                     constant:0.0f];
  constraintPositioningCounterAxis.active = YES;

  return @[constraintSizingThickness, constraintSizingCounterAxis,
           constraintPositioningAlongAxis, constraintPositioningCounterAxis];
}

#pragma mark - Gesture handling

// -----------------------------------------------------------------------------
/// @brief Enables gesture recognizing for the resizing gesture.
// -----------------------------------------------------------------------------
- (void) addGestureHandling
{
  if (self.dragHandleStyle == DragHandleStyleNone)
  {
    self.noDragHandleGestureRecognizer = [self createGestureRecognizer];
    [self.view addGestureRecognizer:self.noDragHandleGestureRecognizer];
  }
  else
  {
    for (UIView* dragHandleView in self.dragHandleViews)
    {
      UILongPressGestureRecognizer* gestureRecognizer = [self createGestureRecognizer];
      [dragHandleView addGestureRecognizer:gestureRecognizer];
      [self.dragHandleGestureRecognizers addObject:gestureRecognizer];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Disables gesture recognizing for the resizing gesture.
// -----------------------------------------------------------------------------
- (void) removeGestureHandling
{
  if (self.dragHandleStyle == DragHandleStyleNone)
  {
    [self.noDragHandleGestureRecognizer.view removeGestureRecognizer:self.noDragHandleGestureRecognizer];
    self.noDragHandleGestureRecognizer = nil;
  }
  else
  {
    for (UILongPressGestureRecognizer* gestureRecognizer in self.dragHandleGestureRecognizers)
    {
      [gestureRecognizer.view removeGestureRecognizer:gestureRecognizer];
    }
    [self.dragHandleGestureRecognizers removeAllObjects];
  }
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (UILongPressGestureRecognizer*) createGestureRecognizer
{
  UILongPressGestureRecognizer* gestureRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragFrom:)] autorelease];
  gestureRecognizer.delegate = self;
  CGFloat infiniteMovement = CGFLOAT_MAX;
  gestureRecognizer.allowableMovement = infiniteMovement;  // let the user pan as long as he wants
  gestureRecognizer.minimumPressDuration = gGoBoardLongPressDelay;
  return gestureRecognizer;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when a resize gesture begins and drag handle style is
/// #DragHandleStyleNone. Finds the two child views that will be affected by
/// the resize gesture, which starts at @a gestureStartLocation. Returns true
/// if the child views were found and fills the out parameters
/// @a childViewGestureInfo1 and @a childViewGestureInfo2 with information about
/// the two child views. Returns false if the child views could not be found.
// -----------------------------------------------------------------------------
- (bool) findChildView1:(struct ChildViewGestureInfo*)childViewGestureInfo1
             childView2:(struct ChildViewGestureInfo*)childViewGestureInfo2
   gestureStartLocation:(CGPoint)gestureStartLocation
{
  // Need to collect information about all child views because we don't know
  // which one will be the one whose edge is closest to the gesture start
  // location.
  NSUInteger numberOfChildViews = self.viewControllers.count;
  struct ChildViewGestureInfo childViewGestureInfos[numberOfChildViews];

  // This will identify which child view is the one whose edge is closest to
  // the gesture start location
  struct ChildViewGestureInfo closestChildViewGestureInfo;

  for (int indexOfChildView = 0; indexOfChildView < numberOfChildViews; ++indexOfChildView)
  {
    childViewGestureInfos[indexOfChildView] = [self gestureInfoForChildViewAtIndex:indexOfChildView
                                                              gestureStartLocation:gestureStartLocation];
    if (indexOfChildView == 0 ||
        childViewGestureInfos[indexOfChildView].gestureStartLocationDistanceFromEdge < closestChildViewGestureInfo.gestureStartLocationDistanceFromEdge)
    {
      closestChildViewGestureInfo = childViewGestureInfos[indexOfChildView];
    }
  }

  bool closestChildViewIsChildView1;
  if (closestChildViewGestureInfo.gestureStartLocationIsCloserToStartEdge)
  {
    if (closestChildViewGestureInfo.indexOfChildView == 0)
      closestChildViewIsChildView1 = true;
    else
      closestChildViewIsChildView1 = false;
  }
  else
  {
    if (closestChildViewGestureInfo.indexOfChildView + 1 == numberOfChildViews)
      closestChildViewIsChildView1 = false;
    else
      closestChildViewIsChildView1 = true;
  }

  if (closestChildViewIsChildView1)
  {
    *childViewGestureInfo1 = closestChildViewGestureInfo;
    *childViewGestureInfo2 = childViewGestureInfos[closestChildViewGestureInfo.indexOfChildView + 1];
  }
  else
  {
    *childViewGestureInfo1 = childViewGestureInfos[closestChildViewGestureInfo.indexOfChildView - 1];
    *childViewGestureInfo2 = closestChildViewGestureInfo;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when a resize gesture begins and the current drag handle
/// style is not #DragHandleStyleNone. Finds the two child views that will be
/// affected by the resize gesture. The drag handle being moved by the gesture
/// is @a dragHandleView. Returns true if the child views were found and fills
/// the out parameters @a childViewGestureInfo1 and @a childViewGestureInfo2
/// with information about the two child views. Returns false if the child views
/// could not be found.
// -----------------------------------------------------------------------------
- (bool) findChildView1:(struct ChildViewGestureInfo*)childViewGestureInfo1
             childView2:(struct ChildViewGestureInfo*)childViewGestureInfo2
   gestureStartLocation:(CGPoint)gestureStartLocation
         dragHandleView:(UIView*)dragHandleView
{
  NSUInteger indexOfDragHandleView = [self.dragHandleViews indexOfObject:dragHandleView];
  if (indexOfDragHandleView == NSNotFound)
    return false;

  NSUInteger indexOfChildView1 = indexOfDragHandleView;
  NSUInteger indexOfChildView2 = indexOfDragHandleView + 1;

  *childViewGestureInfo1 = [self gestureInfoForChildViewAtIndex:indexOfChildView1
                                           gestureStartLocation:gestureStartLocation];
  *childViewGestureInfo2 = [self gestureInfoForChildViewAtIndex:indexOfChildView2
                                           gestureStartLocation:gestureStartLocation];

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Is invoked when a resize gesture begins to calculate the values in a
/// ChildViewGestureInfo struct for one of the two child views that will be
/// affected by the resize gesture. @a indexOfChildView identifies which view
/// the calculations should be made for. @a gestureStartLocation is the location
/// where the gesture starts.
// -----------------------------------------------------------------------------
- (struct ChildViewGestureInfo) gestureInfoForChildViewAtIndex:(NSUInteger)indexOfChildView
                                          gestureStartLocation:(CGPoint)gestureStartLocation
{
  UIViewController* childViewController = [self.viewControllers objectAtIndex:indexOfChildView];
  UIView* childView = childViewController.view;
  CGRect childViewFrame = childView.frame;
  CGRect convertedChildViewFrame = [childView.superview convertRect:childViewFrame toView:self.view];

  CGFloat startEdgeAlongAxis;
  CGFloat endEdgeAlongAxis;
  CGFloat initialExtentAlongAxis;
  CGFloat gestureStartLocationAlongAxis;
  if (self.axis == UILayoutConstraintAxisHorizontal)
  {
    startEdgeAlongAxis = CGRectGetMinX(convertedChildViewFrame);
    endEdgeAlongAxis = CGRectGetMaxX(convertedChildViewFrame);
    initialExtentAlongAxis = convertedChildViewFrame.size.width;
    gestureStartLocationAlongAxis = gestureStartLocation.x;
  }
  else
  {
    startEdgeAlongAxis = CGRectGetMinY(convertedChildViewFrame);
    endEdgeAlongAxis = CGRectGetMaxY(convertedChildViewFrame);
    initialExtentAlongAxis = convertedChildViewFrame.size.height;
    gestureStartLocationAlongAxis = gestureStartLocation.y;
  }

  CGFloat distanceToStartEdge = fabs(startEdgeAlongAxis - gestureStartLocationAlongAxis);
  CGFloat distanceToEndEdge = fabs(endEdgeAlongAxis - gestureStartLocationAlongAxis);

  struct ChildViewGestureInfo childViewGestureInfo;
  childViewGestureInfo.indexOfChildView = indexOfChildView;
  childViewGestureInfo.initialStartEdgeAlongAxis = startEdgeAlongAxis;
  childViewGestureInfo.initialEndEdgeAlongAxis = endEdgeAlongAxis;
  childViewGestureInfo.initialExtentAlongAxis = initialExtentAlongAxis;
  childViewGestureInfo.gestureStartLocationDistanceFromEdge = distanceToStartEdge <= distanceToEndEdge ? distanceToStartEdge : distanceToEndEdge;
  childViewGestureInfo.gestureStartLocationIsCloserToStartEdge = distanceToStartEdge <= distanceToEndEdge;

  return childViewGestureInfo;
}

// -----------------------------------------------------------------------------
/// @brief Cancels the gesture that is currently in progress on the supplied
/// gesture recognizer.
// -----------------------------------------------------------------------------
- (void) cancelGestureInProgress:(UILongPressGestureRecognizer*)gestureRecognizer
{
  gestureRecognizer.enabled = NO;
  gestureRecognizer.enabled = YES;
}

#pragma mark - UIGestureRecognizerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) handleDragFrom:(UILongPressGestureRecognizer*)longPressGestureRecognizer
{
  CGPoint gestureLocation = [longPressGestureRecognizer locationInView:self.view];

  UIGestureRecognizerState recognizerState = longPressGestureRecognizer.state;
  switch (recognizerState)
  {
    case UIGestureRecognizerStateBegan:
    {
      // TODO xxx Disable rotation? [LayoutManager sharedManager].shouldAutorotate = false;

      struct GestureInfo gestureInfo;
      gestureInfo.gestureStartLocation = gestureLocation;

      bool didFindChildViews;
      struct ChildViewGestureInfo childViewGestureInfo1;
      struct ChildViewGestureInfo childViewGestureInfo2;
      if (self.dragHandleStyle == DragHandleStyleNone)
        didFindChildViews = [self findChildView1:&childViewGestureInfo1 childView2:&childViewGestureInfo2 gestureStartLocation:gestureInfo.gestureStartLocation];
      else
        didFindChildViews = [self findChildView1:&childViewGestureInfo1 childView2:&childViewGestureInfo2 gestureStartLocation:gestureInfo.gestureStartLocation dragHandleView:longPressGestureRecognizer.view];

      if (! didFindChildViews)
      {
        [self cancelGestureInProgress:longPressGestureRecognizer];
        return;
      }

      gestureInfo.indexOfChildView1 = childViewGestureInfo1.indexOfChildView;
      gestureInfo.indexOfChildView2 = childViewGestureInfo2.indexOfChildView;
      gestureInfo.initialExtentAlongAxisChildView1 = childViewGestureInfo1.initialExtentAlongAxis;
      gestureInfo.initialExtentAlongAxisChildView2 = childViewGestureInfo2.initialExtentAlongAxis;
      gestureInfo.totalExtentAlongAxisToDistribute = gestureInfo.initialExtentAlongAxisChildView1 + gestureInfo.initialExtentAlongAxisChildView2;
      gestureInfo.totalSizeToDistribute = ([self sizeForChildViewAtIndex:childViewGestureInfo1.indexOfChildView] +
                                           [self sizeForChildViewAtIndex:childViewGestureInfo2.indexOfChildView]);
      self.gestureInfo = gestureInfo;

      break;
    }
    case UIGestureRecognizerStateChanged:
    {
      struct GestureInfo gestureInfo = self.gestureInfo;

      CGFloat gestureDelta;
      if (self.axis == UILayoutConstraintAxisHorizontal)
        gestureDelta = gestureLocation.x - gestureInfo.gestureStartLocation.x;
      else
        gestureDelta = gestureLocation.y - gestureInfo.gestureStartLocation.y;

      CGFloat newExtentAlongAxisChildView1 = gestureInfo.initialExtentAlongAxisChildView1 + gestureDelta;
      if (newExtentAlongAxisChildView1 < 0.0f)
        newExtentAlongAxisChildView1 = 0.0f;
      else if (newExtentAlongAxisChildView1 > gestureInfo.totalExtentAlongAxisToDistribute)
        newExtentAlongAxisChildView1 = gestureInfo.totalExtentAlongAxisToDistribute;

      CGFloat newExtentPercentageChildView1 = newExtentAlongAxisChildView1 / gestureInfo.totalExtentAlongAxisToDistribute;

      double newSizeChildView1 = gestureInfo.totalSizeToDistribute * newExtentPercentageChildView1;
      newSizeChildView1 = [self roundSize:newSizeChildView1 steps:self.resizeStepSize];
      double newSizeChildView2 = gestureInfo.totalSizeToDistribute - newSizeChildView1;

      [self resizeChildView1AtIndex:gestureInfo.indexOfChildView1
                             toSize:newSizeChildView1
                  childView2AtIndex:gestureInfo.indexOfChildView2
                             toSize:newSizeChildView2];

      break;
    }
    case UIGestureRecognizerStateEnded:
    // Occurs, for instance, if an alert is displayed while a gesture is
    // being handled, or if the gesture recognizer was disabled.
    case UIGestureRecognizerStateCancelled:
    {
      struct GestureInfo gestureInfo;
      gestureInfo.gestureStartLocation = CGPointZero;
      self.gestureInfo = gestureInfo;

      // TODO xxx Re-enable rotation? [LayoutManager sharedManager].shouldAutorotate = true;

      break;
    }
    default:
    {
      DDLogDebug(@"handleDragFrom, unhandled recognizerState = %ld", (long)recognizerState);

      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief UIGestureRecognizerDelegate protocol method.
// -----------------------------------------------------------------------------
- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer*)gestureRecognizer
{
  return YES;
}

@end

@implementation DragHandleView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an DragHandleView object.
///
/// @note This is the designated initializer of DragHandleView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.dragHandlePresentationStyle = DragHandlePresentationStyleBar;
  self.dragHandleColorLightUserInterfaceStyle = [UIColor blackColor];
  self.dragHandleColorDarkUserInterfaceStyle = [UIColor whiteColor];
  self.dragHandleGrabAreaMargin = 0.0f;

  self.opaque = NO;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DragHandleView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.dragHandleColorLightUserInterfaceStyle = nil;
  self.dragHandleColorDarkUserInterfaceStyle = nil;

  [super dealloc];
}

#pragma mark - Property setters

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandlePresentationStyle:(enum DragHandlePresentationStyle)dragHandlePresentationStyle
{
  if (dragHandlePresentationStyle == _dragHandlePresentationStyle)
    return;

  _dragHandlePresentationStyle = dragHandlePresentationStyle;

  [self setNeedsDisplay];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleColorLightUserInterfaceStyle:(UIColor*)dragHandleColorLightUserInterfaceStyle
{
  if (dragHandleColorLightUserInterfaceStyle == _dragHandleColorLightUserInterfaceStyle)
    return;

  if (_dragHandleColorLightUserInterfaceStyle)
    [_dragHandleColorLightUserInterfaceStyle release];

  _dragHandleColorLightUserInterfaceStyle = dragHandleColorLightUserInterfaceStyle;

  if (dragHandleColorLightUserInterfaceStyle)
    [dragHandleColorLightUserInterfaceStyle retain];

  [self setNeedsDisplay];
}

// -----------------------------------------------------------------------------
// Property is documented in the header file.
// -----------------------------------------------------------------------------
- (void) setDragHandleColorDarkUserInterfaceStyle:(UIColor*)dragHandleColorDarkUserInterfaceStyle
{
  if (dragHandleColorDarkUserInterfaceStyle == _dragHandleColorDarkUserInterfaceStyle)
    return;

  if (_dragHandleColorDarkUserInterfaceStyle)
    [_dragHandleColorDarkUserInterfaceStyle release];

  _dragHandleColorDarkUserInterfaceStyle = dragHandleColorDarkUserInterfaceStyle;

  if (dragHandleColorDarkUserInterfaceStyle)
    [dragHandleColorDarkUserInterfaceStyle retain];

  [self setNeedsDisplay];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// Drawing for #DragHandlePresentationStyleLine is simple - just stroke the
/// line.
///
/// Drawing for #DragHandlePresentationStyleBar is more complicated due to the
/// rounded cap. The following diagram shows points A-D which define the path
/// that is being filled for a horizontal drag handle. Points X and Y are the
/// center points of the arcs used to draw the rounded caps.
/// @verbatim
///      -A--------------B-     <---+
///    /                    \       | radius
///   |                      |      |
///  +    X              Y    +  <--+
///   |                      |      |
///    \                    / ^     | radius
///      -D--------------C-   | <---+
///       ^              ^    |
///       +--------------+    |
///       lineLength     ^    |
///                      +----+
///                      radius
/// @endverbatim
// -----------------------------------------------------------------------------
- (void) drawRect:(CGRect)rect
{
  CGContextRef context = UIGraphicsGetCurrentContext();

  bool isLightUserInterfaceStyle = [UiUtilities isLightUserInterfaceStyle:self.traitCollection];
  UIColor* dragHandleColor = (isLightUserInterfaceStyle
                              ? self.dragHandleColorLightUserInterfaceStyle
                              : self.dragHandleColorDarkUserInterfaceStyle);

  CGPoint rectCenter = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));

  bool rotate;
  CGFloat smallerDimension;
  CGFloat largerDimension;
  if (rect.size.width >= rect.size.height)
  {
    smallerDimension = rect.size.height;
    largerDimension = rect.size.width;
    rotate = false;
  }
  else
  {
    smallerDimension = rect.size.width;
    largerDimension = rect.size.height;
    rotate = true;
  }

  CGFloat dragHandleThickness = smallerDimension - 2.0f * self.dragHandleGrabAreaMargin;

  if (rotate)
  {
    // TODO xxx Implement drawing for vertical drag handles
  }

  if (self.dragHandlePresentationStyle == DragHandlePresentationStyleLine)
  {
    CGContextMoveToPoint(context, 0.0f, rectCenter.y);
    CGContextAddLineToPoint(context, CGRectGetMaxX(rect), rectCenter.y);

    CGContextSetLineWidth(context, dragHandleThickness);
    CGContextSetStrokeColorWithColor(context, dragHandleColor.CGColor);
    CGContextStrokePath(context);
  }
  else
  {
    CGFloat radius = dragHandleThickness / 2.0f;
    CGFloat lineLength = largerDimension - radius * 2.0f;
    CGPoint centerLeftArc = CGPointMake(radius, rectCenter.y);
    CGPoint centerRightArc = CGPointMake(centerLeftArc.x + lineLength, centerLeftArc.y);

    // Move to point A
    CGContextMoveToPoint(context, centerLeftArc.x, centerLeftArc.y - radius);

    // Adds line from point A to B, then draws arc from point B to C
    const CGFloat startAngleRightArc = [UiUtilities radians:270];
    const CGFloat endAngleRightArc = [UiUtilities radians:90];
    const int clockwiseRightArc = 0;
    CGContextAddArc(context,
                    centerRightArc.x,
                    centerRightArc.y,
                    radius,
                    startAngleRightArc,
                    endAngleRightArc,
                    clockwiseRightArc);

    // Adds line from point C to D, then draws arc from point D to A
    const CGFloat startAngleLeftArc = [UiUtilities radians:90];
    const CGFloat endAngleLeftArc = [UiUtilities radians:270];
    const int clockwiseLeftArc = 0;
    CGContextAddArc(context,
                    centerLeftArc.x,
                    centerLeftArc.y,
                    radius,
                    startAngleLeftArc,
                    endAngleLeftArc,
                    clockwiseLeftArc);

    CGContextSetFillColorWithColor(context, dragHandleColor.CGColor);
    CGContextFillPath(context);
  }
}

@end

