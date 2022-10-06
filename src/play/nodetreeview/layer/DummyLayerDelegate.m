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
#import "DummyLayerDelegate.h"
#import "../../../ui/Tile.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for DummyLayerDelegate.
// -----------------------------------------------------------------------------
@interface DummyLayerDelegate()
@end


@implementation DummyLayerDelegate

// -----------------------------------------------------------------------------
/// @brief Initializes a DummyLayerDelegate object.
///
/// @note This is the designated initializer of DummyLayerDelegate.
// -----------------------------------------------------------------------------
- (id) initWithTile:(id<Tile>)tile metrics:(NodeTreeViewMetrics*)metrics
{
  // Call designated initializer of superclass (BoardViewLayerDelegateBase)
  self = [super initWithTile:tile metrics:metrics];
  if (! self)
    return nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DummyLayerDelegate object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief BoardViewLayerDelegate method.
// -----------------------------------------------------------------------------
- (void) notify:(enum NodeTreeViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  switch (event)
  {
    case NTVLDEventNodeTreeGeometryChanged:
    case NTVLDEventInvalidateContent:
    {
      self.dirty = true;
      break;
    }
    default:
    {
      break;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief CALayerDelegate method.
// -----------------------------------------------------------------------------
- (void) drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
  UIFont* font = [UIFont systemFontOfSize:12];

  UIColor* textColor = [UIColor whiteColor];

  NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
  shadow.shadowColor = [UIColor blackColor];
  shadow.shadowBlurRadius = 5.0;
  shadow.shadowOffset = CGSizeMake(1.0, 1.0);

  NSMutableParagraphStyle* paragraphStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
  paragraphStyle.alignment = NSTextAlignmentCenter;

  NSDictionary* textAttributes = @{ NSFontAttributeName : font,
                                    NSForegroundColorAttributeName : textColor,
                                    NSShadowAttributeName: shadow,
                                    NSParagraphStyleAttributeName : paragraphStyle };

  CGRect dummyTextRect = CGRectZero;
  dummyTextRect.size = CGSizeMake(100, 20);
  dummyTextRect.origin = CGPointMake(10, 10);

  NSString* dummyText = [NSString stringWithFormat:@"%02d / %02d", self.tile.row, self.tile.column];

  UIGraphicsPushContext(context);
  [dummyText drawInRect:dummyTextRect withAttributes:textAttributes];
  UIGraphicsPopContext();  // balance UIGraphicsPushContext()
}

@end
