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
#import "NodeTreeViewMetrics.h"
#import "../../shared/LayoutManager.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetrics()
@end


@implementation NodeTreeViewMetrics

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewMetrics object.
///
/// @note This is the designated initializer of NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  [self setupStaticProperties];
  [self setupFontRanges];
  [self setupMainProperties];
  [self setupNotificationResponders];
  // Remaining properties are initialized by this updater
  [self updateWithCanvasSize:self.canvasSize];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewMetrics object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];

  [super dealloc];
}

#pragma mark - Setup during initialization

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupStaticProperties
{
  self.contentsScale = [UIScreen mainScreen].scale;
  self.tileSize = CGSizeMake(128, 128);
  self.minimumAbsoluteZoomScale = 1.0f;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    self.maximumAbsoluteZoomScale = iPhoneMaximumZoomScale;
  else
    self.maximumAbsoluteZoomScale = iPadMaximumZoomScale;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupFontRanges
{
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupMainProperties
{
  self.baseSize = CGSizeZero;
  self.absoluteZoomScale = 1.0f;
  self.canvasSize = CGSizeMake(self.baseSize.width * self.absoluteZoomScale,
                               self.baseSize.height * self.absoluteZoomScale);
}

#pragma mark - Setup/remove notification responders

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
}

#pragma mark - Public API - Updaters

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newBaseSize.
///
/// The new canvas size will be the new base size multiplied by the current
/// absolute zoom scale.
// -----------------------------------------------------------------------------
- (void) updateWithBaseSize:(CGSize)newBaseSize
{
  if (CGSizeEqualToSize(newBaseSize, self.baseSize))
    return;
  CGSize newCanvasSize = CGSizeMake(newBaseSize.width * self.absoluteZoomScale,
                                    newBaseSize.height * self.absoluteZoomScale);
  [self updateWithCanvasSize:newCanvasSize];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.baseSize = newBaseSize;
  self.canvasSize = newCanvasSize;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newRelativeZoomScale.
///
/// NodeTreeViewMetrics uses an absolute zoom scale for its calculations. This
/// zoom scale is also available as the public property @e absoluteZoomScale.
/// The zoom scale specified here is a @e relative zoom scale that is multiplied
/// with the current absolute zoom to get the new absolute zoom scale.
///
/// Example: The current absolute zoom scale is 2.0, i.e. the canvas size is
/// double the size of the base size. A new relative zoom scale of 1.5 results
/// in the new absolute zoom scale 2.0 * 1.5 = 3.0, i.e. the canvas size will
/// be triple the size of the base size.
///
/// @attention This method may make adjustments so that the final absolute
/// zoom scale can be different from the result of the multiplication described
/// above. For instance, if rounding errors would cause the absolute zoom scale
/// to fall outside of the minimum/maximum range, an adjustment is made so that
/// the absolute zoom scale hits the range boundary.
// -----------------------------------------------------------------------------
- (void) updateWithRelativeZoomScale:(CGFloat)newRelativeZoomScale
{
  if (1.0f == newRelativeZoomScale)
    return;
  CGFloat newAbsoluteZoomScale = self.absoluteZoomScale * newRelativeZoomScale;
  if (newAbsoluteZoomScale < self.minimumAbsoluteZoomScale)
    newAbsoluteZoomScale = self.minimumAbsoluteZoomScale;
  else if (newAbsoluteZoomScale > self.maximumAbsoluteZoomScale)
    newAbsoluteZoomScale = self.maximumAbsoluteZoomScale;
  CGSize newCanvasSize = CGSizeMake(self.baseSize.width * newAbsoluteZoomScale,
                                    self.baseSize.height * newAbsoluteZoomScale);
  [self updateWithCanvasSize:newCanvasSize];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.absoluteZoomScale = newAbsoluteZoomScale;
  self.canvasSize = newCanvasSize;
}

#pragma mark - Private backend invoked from all public API updaters

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newCanvasSize.
///
/// This is the internal backend for the various public updater methods.
// -----------------------------------------------------------------------------
- (void) updateWithCanvasSize:(CGSize)newCanvasSize
{
  // ----------------------------------------------------------------------
  // All calculations in this method must use newCanvasSize.
  // The corresponding property self.newCanvasSize
  // must not be used because, due
  // to the way how this update method is invoked, at least one of these
  // properties is guaranteed to be not up-to-date.
  // ----------------------------------------------------------------------
}

#pragma mark - Public API - Calculators

#pragma mark - Notification responders

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
}

#pragma mark - Private helpers

@end
