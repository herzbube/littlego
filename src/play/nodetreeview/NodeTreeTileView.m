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
#import "NodeTreeTileView.h"
#import "NodeTreeViewMetrics.h"
#import "layer/LinesLayerDelegate.h"
#import "layer/NodeSymbolLayerDelegate.h"
#import "layer/SelectedNodeLayerDelegate.h"
#import "../../go/GoGame.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeTileView.
// -----------------------------------------------------------------------------
@interface NodeTreeTileView()
@property(nonatomic, assign) NodeTreeViewMetrics* nodeTreeViewMetrics;
@property(nonatomic, assign) NodeTreeViewCanvas* nodeTreeViewCanvas;
/// @brief Prevents double-unregistering of notification responders by
/// willMoveToSuperview: followed by dealloc, or double-registering by two
/// consecutive invocations of willMoveToSuperview: where the argument is not
/// nil.
///
/// With the current tiling implementation these precautions are probably
/// unnecessary because the two scenarios should never occur. The keyword is
/// "should" - we are not entirely sure how things might behave in production,
/// so we are playing it safe. Also, we guard against future implementation
/// changes.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, assign) bool drawLayersWasDelayed;
@property(nonatomic, retain) NSArray* layerDelegates;
@property(nonatomic, assign) LinesLayerDelegate* linesLayerDelegate;
@property(nonatomic, assign) NodeSymbolLayerDelegate* nodeSymbolLayerDelegate;
@property(nonatomic, assign) SelectedNodeLayerDelegate* selectedNodeLayerDelegate;
//@}
@end


@implementation NodeTreeTileView

#pragma mark - Synthesize properties

// Auto-synthesizing does not work for properties declared in a protocol, so we
// have to explicitly synthesize these properties that are declared in the
// Tile protocol.
@synthesize row = _row;
@synthesize column = _column;

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeTileView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of NodeTreeTileView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
             metrics:(NodeTreeViewMetrics*)nodeTreeViewMetrics
              canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.nodeTreeViewMetrics = nodeTreeViewMetrics;
  self.nodeTreeViewCanvas = nodeTreeViewCanvas;

  self.row = -1;
  self.column = -1;
  self.notificationRespondersAreSetup = false;
  self.drawLayersWasDelayed = false;
  self.layerDelegates = nil;
  self.linesLayerDelegate = nil;
  self.nodeSymbolLayerDelegate = nil;
  self.selectedNodeLayerDelegate = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeTileView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.nodeTreeViewMetrics = nil;
  self.nodeTreeViewCanvas = nil;

  for (id<NodeTreeViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate.layer removeFromSuperlayer];

  self.layerDelegates = nil;
  self.linesLayerDelegate = nil;
  self.nodeSymbolLayerDelegate = nil;
  self.selectedNodeLayerDelegate = nil;

  [super dealloc];
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
  [self.nodeTreeViewMetrics addObserver:self forKeyPath:@"nodeTreeViewCellSize" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for dealloc.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];

  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"abstractCanvasSize"];
  [self.nodeTreeViewMetrics removeObserver:self forKeyPath:@"nodeTreeViewCellSize"];
}

#pragma mark - Manage layers and layer delegates

// -----------------------------------------------------------------------------
/// @brief Sets up this NodeTreeTileView with layers that match the current
/// application state.
///
/// The process consists of these actions:
/// - Layers that are required but do not exist are created
/// - Layers that are not required but that exist are deallocated
/// - Layers that are required and that already exist are kept as-is
///
/// Due to the last point, a caller may need to invalidate all layers' contents
/// by invoking invalidateContent().
///
/// @note If this method is invoked two times in a row without any application
/// state changes in between, the second invocation does not have any effect.
// -----------------------------------------------------------------------------
- (void) setupLayerDelegates
{
  [self setupLinesLayerDelegate];
  [self setupNodeSymbolLayerDelegate];
  [self setupSelectedNodeLayerDelegate];

  [self updateLayers];
}

// -----------------------------------------------------------------------------
/// @brief Creates the node symbol layer delegate, or resets it to nil,
/// depending on the current application state.
// -----------------------------------------------------------------------------
- (void) setupLinesLayerDelegate
{
  if (self.linesLayerDelegate)
    return;

  self.linesLayerDelegate = [[[LinesLayerDelegate alloc] initWithTile:self
                                                              metrics:self.nodeTreeViewMetrics
                                                               canvas:self.nodeTreeViewCanvas] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Creates the node symbol layer delegate, or resets it to nil,
/// depending on the current application state.
// -----------------------------------------------------------------------------
- (void) setupNodeSymbolLayerDelegate
{
  if (self.nodeSymbolLayerDelegate)
    return;

  self.nodeSymbolLayerDelegate = [[[NodeSymbolLayerDelegate alloc] initWithTile:self
                                                                        metrics:self.nodeTreeViewMetrics
                                                                         canvas:self.nodeTreeViewCanvas] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Creates the node symbol layer delegate, or resets it to nil,
/// depending on the current application state.
// -----------------------------------------------------------------------------
- (void) setupSelectedNodeLayerDelegate
{
  if (self.selectedNodeLayerDelegate)
    return;

  self.selectedNodeLayerDelegate = [[[SelectedNodeLayerDelegate alloc] initWithTile:self
                                                                            metrics:self.nodeTreeViewMetrics
                                                                             canvas:self.nodeTreeViewCanvas] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Updates the layers of this NodeTreeTileView based on the layer
/// delegates that currently exist.
// -----------------------------------------------------------------------------
- (void) updateLayers
{
  NSArray* oldLayerDelegates = self.layerDelegates;
  NSMutableArray* newLayerDelegates = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  // The order in which layer delegates are added to the array is important: It
  // determines the order in which layers are stacked.
  [newLayerDelegates addObject:self.linesLayerDelegate];
  [newLayerDelegates addObject:self.nodeSymbolLayerDelegate];
  [newLayerDelegates addObject:self.selectedNodeLayerDelegate];

  // Removing/adding layers does not cause them to redraw. Only layers that
  // are newly created are redrawn.
  for (id<NodeTreeViewLayerDelegate> oldLayerDelegate in oldLayerDelegates)
    [oldLayerDelegate.layer removeFromSuperlayer];
  for (id<NodeTreeViewLayerDelegate> newLayerDelegate in newLayerDelegates)
    [self.layer addSublayer:newLayerDelegate.layer];

  // Replace the old array at the very end. The old array is now deallocated,
  // including any layer delegates that are no longer in newLayerDelegates
  self.layerDelegates = newLayerDelegates;
}

#pragma mark - Handle delayed drawing

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed drawing of layers.
/// NodeTreeTileView methods that need a view update should invoke this helper
/// instead of drawLayers().
///
/// If no long-running actions are in progress, this helper invokes
/// drawLayers(), thus triggering the update in UIKit.
///
/// If any long-running actions are in progress, this helper sets
/// @e drawLayersWasDelayed to true.
// -----------------------------------------------------------------------------
- (void) delayedDrawLayers
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayersWasDelayed = true;
  else
    [self drawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layers that they need to update now if they are dirty.
/// This marks one update cycle.
// -----------------------------------------------------------------------------
- (void) drawLayers
{
  // No game -> no nodes -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;

  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(drawLayers) withObject:nil waitUntilDone:YES];
    return;
  }

  self.drawLayersWasDelayed = false;

  for (id<NodeTreeViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate drawLayer];
}

// -----------------------------------------------------------------------------
/// @brief Notifies all layer delegates that @a event has occurred. The event
/// info object supplied to the delegates is @a eventInfo.
///
/// Delegates will ignore the event, or react to the event, as appropriate for
/// the layer that they manage.
// -----------------------------------------------------------------------------
- (void) notifyLayerDelegates:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id<NodeTreeViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate notify:event eventInfo:eventInfo];
}

#pragma mark - Tile protocol overrides

// -----------------------------------------------------------------------------
/// @brief Tile protocol method
// -----------------------------------------------------------------------------
- (void) invalidateContent
{
  [self notifyLayerDelegates:NTVLDEventInvalidateContent eventInfo:nil];
  [self delayedDrawLayers];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewContentDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewContentDidChange:(NSNotification*)notification
{
  // TODO xxx arrives on main thread when application starts up => test if this also happens when game is loaded
  [self notifyLayerDelegates:NTVLDEventNodeTreeContentChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewCondenseMoveNodesDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewCondenseMoveNodesDidChange:(NSNotification*)notification
{
  // If the condense move nodes user preference changes the cell size also
  // changes => see KVO responder. To avoid a dependency on event ordering it
  // is best to handle the two things separately.

  [self notifyLayerDelegates:NTVLDEventNodeTreeCondenseMoveNodesChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewAlignMoveNodesDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewAlignMoveNodesDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegates:NTVLDEventNodeTreeAlignMoveNodesChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewBranchingStyleDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewBranchingStyleDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegates:NTVLDEventNodeTreeBranchingStyleChanged eventInfo:nil];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #nodeTreeViewSelectedNodeDidChange notification.
// -----------------------------------------------------------------------------
- (void) nodeTreeViewSelectedNodeDidChange:(NSNotification*)notification
{
  [self notifyLayerDelegates:NTVLDEventNodeTreeSelectedNodeChanged eventInfo:notification.object];
  [self delayedDrawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #longRunningActionEnds notification.
// -----------------------------------------------------------------------------
- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayersWasDelayed)
    [self drawLayers];
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
      [self notifyLayerDelegates:NTVLDEventAbstractCanvasSizeChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"nodeTreeViewCellSize"])
    {
      // There are several reasons why the cell size could have changed.
      // Typical examples: The zoom scale did change, or the condense move nodes
      // user preference did change.
      [self notifyLayerDelegates:NTVLDEventNodeTreeGeometryChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
///
/// If this NodeTreeTileView is added to a superview (i.e. @a newSuperview is
/// not @e nil), this BoardTileView registers to receive notifications so that
/// it can participate in drawing. It also sets up all layers and invalidates
/// their content so that they redraw in the next drawing cycle. This make sures
/// that 1) the tile view is drawing its content the first time after it is
/// newly allocated, or 2) re-drawing its content according to the current
/// application state after it is reused.
///
/// If this NodeTreeTileView is removed from its superview (i.e. @a newSuperview
/// is @e nil), this NodeTreeTileView unregisters from all notifications so that
/// it no longer takes part in the drawing process. Layers that currently exist
/// are frozen.
// -----------------------------------------------------------------------------
- (void) willMoveToSuperview:(UIView*)newSuperview
{
  if (newSuperview)
  {
    [self setupNotificationResponders];
    // If the view is reused: Layers may have come and gone since the view was
    // frozen
    [self setupLayerDelegates];
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
/// This implementation is not strictly required because NodeTreeTileView is
/// currently not used in conjunction with Auto Layout.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  return self.nodeTreeViewMetrics.tileSize;
}

@end
