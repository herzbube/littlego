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


// Forward declarations
@class NSString;
@class UIColor;


// -----------------------------------------------------------------------------
/// @brief The UIColorAdditions category enhances UIColor by adding string
/// conversion methods, and a new predefined color "slate blue".
///
/// Inspiration for this category comes from
/// - String conversion: http://arstechnica.com/apple/guides/2009/02/iphone-development-accessing-uicolor-components.ars
/// - Slate blue color: http://stackoverflow.com/questions/3943607/iphone-need-the-dark-blue-color-as-a-uicolor-used-on-tables-details-text-3366
// -----------------------------------------------------------------------------
@interface UIColor(UIColorAdditions)
+ (NSString*) stringFromUIColor:(UIColor*)color;
+ (NSString*) hexStringFromUIColor:(UIColor*)color;
+ (UIColor*) colorFromString:(NSString*)string;
+ (UIColor*) colorFromHexString:(NSString*)hexString;
- (CGFloat) red;
- (CGFloat) green;
- (CGFloat) blue;
- (CGFloat) alpha;

+ (UIColor*) slateBlueColor;
@end
