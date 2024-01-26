// -----------------------------------------------------------------------------
// Copyright 2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewMetricsUpdater.h"
#import "NodeTreeViewMetrics.h"
#import "canvas/NodeTreeViewCanvas.h"
#import "../model/NodeTreeViewModel.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// NodeTreeViewMetricsUpdater.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetricsUpdater()
@property(nonatomic, assign) NodeTreeViewMetrics* nodeTreeViewMetrics;
@property(nonatomic, assign) NodeTreeViewModel* nodeTreeViewModel;
// Declaration uses NSObject<>* instead of the usual id<> because in addition
// to the protocol methods we also need methods from NSKeyValueObserving, and
// NSObject adopts NSKeyValueObserving.
@property(nonatomic, assign) NSObject<NodeTreeViewCanvasDataProvider>* canvasDataProvider;
/// @brief Prevents double-unregistering of notification responders by
/// an external actor followed by dealloc. This is possible because
/// removeNotificationResponders() is in the public API of this class.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@end


@implementation NodeTreeViewMetricsUpdater

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewMetricsUpdater object.
///
/// @note This is the designated initializer of NodeTreeViewMetricsUpdater.
// -----------------------------------------------------------------------------
- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
  canvasDataProvider:(NSObject<NodeTreeViewCanvasDataProvider>*)canvasDataProvider
             metrics:(NodeTreeViewMetrics*)metrics
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.nodeTreeViewMetrics = metrics;
  self.nodeTreeViewModel = nodeTreeViewModel;
  self.canvasDataProvider = canvasDataProvider;

  self.notificationRespondersAreSetup = false;

  [self setupNotificationResponders];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewMetricsUpdater
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  self.nodeTreeViewModel = nil;
  self.canvasDataProvider = nil;
  self.nodeTreeViewMetrics = nil;

  [super dealloc];
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Sets up notification responders and KVO registrations.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  if (self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = true;

  [self.canvasDataProvider addObserver:self forKeyPath:@"canvasSize" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"displayNodeNumbers" options:0 context:NULL];
  [self.nodeTreeViewModel addObserver:self forKeyPath:@"condenseMoveNodes" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Removes notification responders and KVO registrations.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  if (! self.notificationRespondersAreSetup)
    return;
  self.notificationRespondersAreSetup = false;

  [self.canvasDataProvider removeObserver:self forKeyPath:@"canvasSize"];
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"displayNodeNumbers"];
  [self.nodeTreeViewModel removeObserver:self forKeyPath:@"condenseMoveNodes"];
}

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"canvasSize"])
  {
    [self.nodeTreeViewMetrics updateWithAbstractCanvasSize:self.canvasDataProvider.canvasSize];
  }
  else if ([keyPath isEqualToString:@"displayNodeNumbers"])
  {
    [self.nodeTreeViewMetrics updateWithDisplayNodeNumbers:self.nodeTreeViewModel.displayNodeNumbers];
  }
  else if ([keyPath isEqualToString:@"condenseMoveNodes"])
  {
    [self.nodeTreeViewMetrics updateWithCondenseMoveNodes:self.nodeTreeViewModel.condenseMoveNodes];
  }
}

@end
