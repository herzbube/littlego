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
#import "SpacerView.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for SpacerView.
// -----------------------------------------------------------------------------
@interface SpacerView()
/// @brief Don't use the property name intrinsicContentSize to avoid a name
/// clash with the property in the UIView base class.
@property(nonatomic, assign) CGSize internalIntrinsicContentSize;
@end


@implementation SpacerView

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a SpacerView object.
///
/// @note This is the designated initializer of SpacerView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.internalIntrinsicContentSize = CGSizeZero;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SpacerView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

#pragma mark - Changing the intrinsic content size

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) changeIntrinsicContentSize:(CGSize)intrinsicContentSize;
{
  self.internalIntrinsicContentSize = intrinsicContentSize;
  [self setNeedsLayout];
}

#pragma mark - UIView overrides

// -----------------------------------------------------------------------------
/// @brief UIView method.
// -----------------------------------------------------------------------------
- (CGSize) intrinsicContentSize
{
  return self.internalIntrinsicContentSize;
}

@end
