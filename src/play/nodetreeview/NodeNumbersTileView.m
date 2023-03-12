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
#import "NodeNumbersTileView.h"
#import "NodeTreeViewMetrics.h"
#import "layer/NodeNumbersLayerDelegate.h"
#import "../../go/GoGame.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeNumbersTileView.
// -----------------------------------------------------------------------------
@interface NodeNumbersTileView()
@property(nonatomic, assign) NodeTreeViewMetrics* nodeTreeViewMetrics;
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
/// @brief Prevents double-unregistering of notification responders by
/// willMoveToSuperview: followed by dealloc, or double-registering by two
/// consecutive invocations of willMoveToSuperview: where the argument is not
/// nil. Also the method removeNotificationResponders() is in the public API,
/// so if an external actor performs the unregistering there is no need to do
/// it again in dealloc.
///
/// With the current tiling implementation these precautions are probably
/// unnecessary because the two scenarios should never occur. The keyword is
/// "should" - we are not entirely sure how things might behave in production,
/// so we are playing it safe. Also, we guard against future implementation
/// changes.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, retain) NodeNumbersLayerDelegate* nodeNumbersLayerDelegate;
@property(nonatomic, assign) bool drawLayerWasDelayed;
@end


@implementation NodeNumbersTileView

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeNumbersTileView object with frame rectangle
/// @a rect.
///
/// @note This is the designated initializer of NodeNumbersTileView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
             metrics:(NodeTreeViewMetrics*)nodeTreeViewMetrics
              canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
               model:(NodeTreeViewModel*)nodeTreeViewModel
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.nodeTreeViewMetrics = nodeTreeViewMetrics;
  self.nodeTreeViewCanvas = nodeTreeViewCanvas;
  self.nodeTreeViewModel = nodeTreeViewModel;

  self.row = -1;
  self.column = -1;
  self.notificationRespondersAreSetup = false;
  self.drawLayerWasDelayed = false;
  [self setupLayer];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeNumbersTileView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.nodeTreeViewMetrics = nil;
  self.nodeTreeViewCanvas = nil;
  self.nodeTreeViewModel = nil;

  [self.nodeNumbersLayerDelegate.layer removeFromSuperlayer];

  [super dealloc];
}

#pragma mark - View setup

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupLayer
{
  self.nodeNumbersLayerDelegate = [[[NodeNumbersLayerDelegate alloc] initWithTile:self
                                                                          metrics:self.nodeTreeViewMetrics
                                                                           canvas:self.nodeTreeViewCanvas
                                                                            model:self.nodeTreeViewModel] autorelease];
  [self.layer addSublayer:self.nodeNumbersLayerDelegate.layer];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(nodeTreeViewContentDidChange:) name:nodeTreeViewContentDidChange object:nil];
  [center addObserver:self selector:@selector(nodeTreeViewCondenseMoveNodesDidChange:) name:nodeTreeViewCondenseMoveNodesDidChange object:nil];
  [center addObserver:self selector:@selector(nodeTreeViewAlignMoveNodesDidChange:) name:nodeTreeViewAlignMoveNodesDidChange object:nil];
  [center addObserver:self selector:@selector(nodeTreeViewBranchingStyleDidChange:) name:nodeTreeViewBranchingStyleDidChange object:nil];
  [center addObserver:self selector:@selector(nodeTreeViewSelectedNodeDidChange:) name:nodeTreeViewSelectedNodeDidChange object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];

  // KVO observing
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"abstractCanvasSize" options:0 context:NULL];
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"nodeNumberViewCellSize" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"abstractCanvasSize"];
  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"nodeNumberViewCellSize"];
}

#pragma mark - Handle delayed drawing

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed drawing of the view
/// layer. NodeNumbersTileView methods that need a view update should
/// invoke this helper instead of drawLayer().
///
/// If no long-running actions are in progress, this helper invokes
/// drawLayer(), thus triggering the update in UIKit.
///
/// If any long-running actions are in progress, this helper sets
/// @e drawLayerWasDelayed to true.
// -----------------------------------------------------------------------------
- (void) delayedDrawLayer
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayerWasDelayed = true;
  else
    [self drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the view layer that it needs to update now if it is dirty.
/// This marks one update cycle.
// -----------------------------------------------------------------------------
- (void) drawLayer
{
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(drawLayer) withObject:nil waitUntilDone:YES];
    return;
  }

  self.drawLayerWasDelayed = false;
  [self.nodeNumbersLayerDelegate drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies the view layer that @a event has occurred. The event
/// info object supplied to the delegate is @a eventInfo.
///
/// The delegate will ignore the event, or react to the event, as appropriate
/// for the content that it manages.
// -----------------------------------------------------------------------------
- (void) notifyLayerDelegate:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  [self.nodeNumbersLayerDelegate notify:event eventInfo:eventInfo];
}

#pragma mark - Tile protocol overrides

// -----------------------------------------------------------------------------
/// @brief Tile protocol method
// -----------------------------------------------------------------------------
- (void) invalidateContent
{
  [self notifyLayerDelegate:NTVLDEventInvalidateContent eventInfo:nil];
  [self delayedDrawLayer];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewContentDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewContentDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegate:NTVLDEventNodeTreeContentChanged eventInfo:nil];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewCondenseMoveNodesDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewCondenseMoveNodesDidChange:(NSNotification*)notification
{
  // If the condense move nodes user preference changes the cell size also
  // changes => see KVO responder. To avoid a dependency on event ordering it
  // is best to handle the two things separately.

  [self notifyLayerDelegate:NTVLDEventNodeTreeCondenseMoveNodesChanged eventInfo:nil];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewAlignMoveNodesDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewAlignMoveNodesDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegate:NTVLDEventNodeTreeAlignMoveNodesChanged eventInfo:nil];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewBranchingStyleDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewBranchingStyleDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegate:NTVLDEventNodeTreeBranchingStyleChanged eventInfo:nil];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewSelectedNodeDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewSelectedNodeDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegate:NTVLDEventNodeTreeSelectedNodeChanged eventInfo:notification.object];
  [self delayedDrawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayerWasDelayed)
    [self drawLayer];
}

#pragma mark - KVO responder

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if (object == self.nodeTreeViewMetrics)
  {
    if ([keyPath isEqualToString:@"abstractCanvasSize"])
    {
      [self notifyLayerDelegate:NTVLDEventAbstractCanvasSizeChanged eventInfo:nil];
      [self delayedDrawLayer];
    }
    else if ([keyPath isEqualToString:@"nodeNumberViewCellSize"])
    {
      // There are several reasons why the cell size could have changed.
      // Typical examples: The zoom scale did change, or the condense move nodes
      // user preference did change.
      [self notifyLayerDelegate:NTVLDEventNodeTreeGeometryChanged eventInfo:nil];
      [self delayedDrawLayer];
    }
  }
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// If this NodeNumbersTileView is added to a superview (i.e.
/// @a newSuperview is not nil), this NodeNumbersTileView registers to
/// receive notifications so that it can participate in drawing. It also
/// invalidates the content of its layers so that it redraws in the next
/// drawing cycle. This make sures that the tile view is drawing its content
/// the first time after it is newly allocated, or after it is reused.
///
/// If this NodeNumbersTileView is removed from its superview (i.e.
/// @a newSuperview is nil), this NodeNumbersTileView unregisters from all
/// notifications so that it no longer takes part in the drawing process.
// -----------------------------------------------------------------------------
- (void) willMoveToSuperview:(UIView*)newSuperview
{
  if (newSuperview)
  {
    [self setupNotificationResponders];
    [self invalidateContent];
  }
  else
  {
    [self removeNotificationResponders];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// This implementation is not strictly required because
/// NodeNumbersTileView is currently not used in conjunction with Auto
/// Layout.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  return self.nodeTreeViewMetrics.tileSize;
}

@end
