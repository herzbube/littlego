// -----------------------------------------------------------------------------
// Copyright 2013-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "FontRange.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for FontRange.
// -----------------------------------------------------------------------------
@interface FontRange()
/// @brief Stores the fonts that were precalculated when FontRange was
/// initialized.
///
/// Each entry in the @e precalculatedFonts array is another array with three
/// elements: The first element is the font object (an UIFont object), the
/// second and third elements are the rectangle width and height (both NSNumber
/// object with a float value).
///
/// Entries in @e precalculatedFonts appear ordered by font size. The first
/// entry is the one with the largest font size.
@property(nonatomic, retain) NSArray* precalculatedFonts;
@end


@implementation FontRange

// -----------------------------------------------------------------------------
/// @brief Initializes a FontRange object.
///
/// @note This is the designated initializer of FontRange.
// -----------------------------------------------------------------------------
- (id) initWithText:(NSString*)text
     monospacedFont:(bool)monospacedFont
    minimumFontSize:(int)minimumFontSize
    maximumFontSize:(int)maximumFontSize
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  [self setupFontsWithText:text
            monospacedFont:monospacedFont
           minimumFontSize:minimumFontSize
           maximumFontSize:maximumFontSize];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a FontRange object with the default system font.
// -----------------------------------------------------------------------------
- (id) initWithText:(NSString*)text
    minimumFontSize:(int)minimumFontSize
    maximumFontSize:(int)maximumFontSize
{
  return [self initWithText:text
             monospacedFont:false
            minimumFontSize:minimumFontSize
            maximumFontSize:maximumFontSize];
}

// -----------------------------------------------------------------------------
/// @brief Initializes a FontRange object with the default monospaced system
/// font.
// -----------------------------------------------------------------------------
- (id) initWithMonospacedFontAndText:(NSString*)text
                     minimumFontSize:(int)minimumFontSize
                     maximumFontSize:(int)maximumFontSize
{
  return [self initWithText:text
             monospacedFont:true
            minimumFontSize:minimumFontSize
            maximumFontSize:maximumFontSize];
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this FontRange object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.precalculatedFonts = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupFontsWithText:(NSString*)text
             monospacedFont:(bool)monospacedFont
            minimumFontSize:(int)minimumFontSize
            maximumFontSize:(int)maximumFontSize
{
  NSMutableArray* precalculatedFonts = [NSMutableArray arrayWithCapacity:0];
  for (int fontSize = maximumFontSize; fontSize >= minimumFontSize; --fontSize)
  {
    UIFont* font;
    if (monospacedFont)
    {
      if (@available(iOS 13, *))
        font = [UIFont monospacedSystemFontOfSize:fontSize weight:UIFontWeightRegular];
      else
        font = [UIFont fontWithName:@"Menlo" size:fontSize];
    }
    else
    {
      font = [UIFont systemFontOfSize:fontSize];
    }
    NSDictionary* textAttributes = @{ NSFontAttributeName : font };
    // If more control over how the drawing takes place is needed, another
    // useful NSString method is
    // boundingRectWithSize:options:attributes:context(). See the history of
    // this file how to use it.
    CGSize boundingBoxSize = [text sizeWithAttributes:textAttributes];
    boundingBoxSize.width = ceilf(boundingBoxSize.width);
    boundingBoxSize.height = ceilf(boundingBoxSize.height);
    NSArray* array = [NSArray arrayWithObjects:font,
                                               [NSNumber numberWithFloat:boundingBoxSize.width],
                                               [NSNumber numberWithFloat:boundingBoxSize.height],
                                               nil];
    [precalculatedFonts addObject:array];
  }
  self.precalculatedFonts = precalculatedFonts;
}

// -----------------------------------------------------------------------------
/// @brief Returns a font that is suitable for drawing the text specified when
/// this FontRange instance was created, in a manner so that the drawing result
/// is as wide as possible, but not wider than @a width. Returns @e nil if no
/// suitable font was found.
// -----------------------------------------------------------------------------
- (UIFont*) queryForWidth:(CGFloat)width
{
  CGSize textSize;
  UIFont* font;
  bool didFindFont = [self queryForWidth:width font:&font textSize:&textSize];
  return didFindFont ? font : nil;
}

// -----------------------------------------------------------------------------
/// @brief Fills the out variables @a font and @a textSize with values that are
/// suitable for drawing the text specified when this FontRange instance was
/// created, in a manner so that the drawing result is as wide as possible, but
/// not wider than @a width.
///
/// Returns true if suitable values were found. Returns false if no suitable
/// value were found (the content of @a font and @a textSize in this case is not
/// specified).
///
/// If you intend to draw a text that is smaller than the one specified when
/// this FontRange instance was created, you could horizontally center the text
/// in @a textSize.
// -----------------------------------------------------------------------------
- (bool) queryForWidth:(CGFloat)width
                  font:(UIFont**)font
              textSize:(CGSize*)textSize
{
  for (NSArray* array in self.precalculatedFonts)
  {
    CGFloat minimumRequiredWidth = [[array objectAtIndex:1] floatValue];
    if (minimumRequiredWidth > width)
      continue;
    CGFloat minimumRequiredHeight = [[array objectAtIndex:2] floatValue];
    *textSize = CGSizeMake(minimumRequiredWidth, minimumRequiredHeight);
    *font = [array objectAtIndex:0];
    return true;
  }
  return false;
}

@end
