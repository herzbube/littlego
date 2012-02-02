// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
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


@class CALayer;
@class PlayViewMetrics;
@class PlayViewModel;


// -----------------------------------------------------------------------------
/// @brief The PlayViewLayerDelegate class is the base class for all layer
/// delegates that manage one of the layers that make up the Play view.
// -----------------------------------------------------------------------------
@interface PlayViewLayerDelegate : NSObject
{
}

- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model;

/// @brief The layer managed by the delegate.
@property(nonatomic, retain, readonly) CALayer* layer;
/// @brief Object that provides the metrics for drawing elements on the Play
/// view.
@property(nonatomic, retain, readonly) PlayViewMetrics* playViewMetrics;
/// @brief Model object that provides additional drawing information obtained
/// from the user defaults.
@property(nonatomic, retain, readonly) PlayViewModel* playViewModel;

@end
