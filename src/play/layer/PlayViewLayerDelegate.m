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


// Project includes
#import "PlayViewLayerDelegate.h"
#import "../PlayViewMetrics.h"

// System includes
#import <QuartzCore/QuartzCore.h>


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayViewLayerDelegate.
// -----------------------------------------------------------------------------
@interface PlayViewLayerDelegate()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name Notification responders
//@{
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Re-declaration of properties to make them readwrite privately
//@{
@property(nonatomic, retain, readwrite) CALayer* layer;
@property(nonatomic, retain, readwrite) PlayViewMetrics* playViewMetrics;
@property(nonatomic, retain, readwrite) PlayViewMetrics* playViewModel;
//@}
@end


@implementation PlayViewLayerDelegate

@synthesize layer;
@synthesize playViewMetrics;
@synthesize playViewModel;


// -----------------------------------------------------------------------------
/// @brief Initializes a PlayViewLayerDelegate object.
///
/// @note This is the designated initializer of PlayViewLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithLayer:(CALayer*)aLayer metrics:(PlayViewMetrics*)metrics model:(PlayViewModel*)model
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.layer = aLayer;
  self.playViewMetrics = metrics;
  self.playViewModel = model;

  self.layer.delegate = self;

  // KVO observing
  [self.playViewMetrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayViewLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self.playViewMetrics removeObserver:self forKeyPath:@"rect"];
  self.layer = nil;
  self.playViewMetrics = nil;
  self.playViewModel = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  self.layer.frame = playViewMetrics.rect;
  [self.layer setNeedsDisplay];
}

@end
