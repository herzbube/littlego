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


// Forward declarations
@class NodeTreeViewMetrics;
@class NodeTreeViewModel;
@protocol NodeTreeViewCanvasDataProvider;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewMetricsUpdater class is responsible for updating a
/// NodeTreeViewMetrics object when changes in underlying model objects occur.
///
/// NodeTreeViewMetricsUpdater acts as an intermediary so that:
/// - NodeTreeViewMetrics does not have to know the sources from which update
///   triggers are coming.
/// - NodeTreeViewMetrics does not need to contain dynamic behaviour.
///
/// The benefit is that NodeTreeViewMetrics can be re-used for static drawing
/// of some UI elements such as node symbols.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetricsUpdater : NSObject
{
}

- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
  canvasDataProvider:(NSObject<NodeTreeViewCanvasDataProvider>*)canvasDataProvider
             metrics:(NodeTreeViewMetrics*)metrics;

- (void) removeNotificationResponders;

@end
