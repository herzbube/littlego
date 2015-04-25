// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "NSStringAdditions.h"
#import "UIDeviceAdditions.h"


@implementation NSString(NSStringAdditions)

// -----------------------------------------------------------------------------
/// @brief Returns a string UUID. Example: C42B7FB8-F5DC-4D07-877E-AA583EFECF80.
///
/// The code for this method was copied more or less verbatim from
/// http://www.cocoabuilder.com/archive/cocoa/217665-how-to-create-guid.html
// -----------------------------------------------------------------------------
+ (NSString*) UUIDString
{
  CFUUIDRef UUIDRef = CFUUIDCreate(NULL);
  NSString* uuidString = (NSString*)CFUUIDCreateString(NULL, UUIDRef);
  CFRelease(UUIDRef);
  return [uuidString autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Returns an image whose sole content is a rendered version of the
/// receiver.
///
/// If @a font is nil the font used for rendering is
/// [UIFont systemFontOfSize:[UIFont labelFontSize]].
///
/// If @a drawShadow is true the rendered text floats on a light gray shadow.
/// The image size increases slightly when a shadow is used.
///
/// The code for this method is based on
/// http://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text
// -----------------------------------------------------------------------------
- (UIImage*) imageWithFont:(UIFont*)font drawShadow:(bool)drawShadow
{
  if (nil == font)
    font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  NSDictionary* textAttributes = @{ NSFontAttributeName : font };
  CGSize size = [self sizeWithAttributes:textAttributes];
  size.width = ceilf(size.width);
  size.height = ceilf(size.height);

  const CGSize shadowOffset = CGSizeMake(1, 1);
  // Increase the context size to avoid clipping the shadow
  if (drawShadow)
  {
    size.width += shadowOffset.width;
    size.height += shadowOffset.height;
  }

  UIGraphicsBeginImageContextWithOptions(size, NO, 0);
  if (drawShadow)
  {
    CGContextRef context = UIGraphicsGetCurrentContext();
    const CGFloat shadowBlur = 5.0;
    UIColor* shadowColor = [UIColor grayColor];
    // From now on, all objects drawn subsequently will be shadowed
    CGContextSetShadowWithColor(context, shadowOffset, shadowBlur, shadowColor.CGColor);
  }

  [self drawAtPoint:CGPointMake(0, 0) withAttributes:textAttributes];
  UIImage* outputImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  return outputImage;
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string for the komi value @a komi.
///
/// The string that is returned generally has the same format as described in
/// the method documentation of stringWithFractionValue:().
///
/// A special case is the value 0.0 which, if @a numericZeroValue is false, is
/// represented as "No komi".
// -----------------------------------------------------------------------------
+ (NSString*) stringWithKomi:(double)komi numericZeroValue:(bool)numericZeroValue
{
  if (0.0 == komi)
  {
    if (numericZeroValue)
      return @"0";
    else
      return @"No komi";
  }
  else
    return [NSString stringWithFractionValue:komi];
}

// -----------------------------------------------------------------------------
/// @brief Returns a nicely formatted string for the fraction value @a value.
///
/// The fractional part of @a value is expected to be one of the following:
/// 0.0, 0.5, 0.25, 0.75, 0.2, 0.4, 0.6, 0.8, 0.125, 0.375, 0.625, 0.875,
/// 0.1666..., 0.333..., 0.666..., or 0.8333...
///
/// Generally, if the fractional part is 0.0, the string representation returned
/// by this method omits the fraction. If the fractional part is among those
/// recognized by this method, it is represented using the corresponding unicode
/// fraction character.
///
/// Examples: A value of 6.5 results in the string representation "6½". A value
/// of 6.0 results in "6".
///
/// A special case are values whose integral part is 0 (e.g. 0.5): These values
/// are represented with the integral part omitted (e.g. 0.5 becomes "½", @b not
/// "0½").
// -----------------------------------------------------------------------------
+ (NSString*) stringWithFractionValue:(double)value
{
  static const double oneThird = 1.0 / 3.0;
  static const double twoThirds = 2.0 / 3.0;
  static const double oneSixth = 1.0 / 6.0;
  static const double fiveSixths = 5.0 / 6.0;

  double valueIntegerPart;
  double valueFractionalPart = modf(value, &valueIntegerPart);
  NSString* stringFractionalPart;
  if (0.0 == valueFractionalPart)
    return [NSString stringWithFormat:@"%.0f", valueIntegerPart];
  else if (0.125 == valueFractionalPart)
    stringFractionalPart = @"⅛";
  else if (0.2 == valueFractionalPart)
    stringFractionalPart = @"⅕";
  else if (0.25 == valueFractionalPart)
    stringFractionalPart = @"¼";
  else if (0.375 == valueFractionalPart)
    stringFractionalPart = @"⅜";
  else if (0.4 == valueFractionalPart)
    stringFractionalPart = @"⅖";
  else if (0.5 == valueFractionalPart)
    stringFractionalPart = @"½";
  else if (0.6 == valueFractionalPart)
    stringFractionalPart = @"⅗";
  else if (0.625 == valueFractionalPart)
    stringFractionalPart = @"⅝";
  else if (0.75 == valueFractionalPart)
    stringFractionalPart = @"¾";
  else if (0.8 == valueFractionalPart)
    stringFractionalPart = @"⅘";
  else if (0.875 == valueFractionalPart)
    stringFractionalPart = @"⅞";
  else if (oneThird == valueFractionalPart)
    stringFractionalPart = @"⅓";
  else if (twoThirds == valueFractionalPart)
    stringFractionalPart = @"⅔";
  else if (oneSixth == valueFractionalPart)
    stringFractionalPart = @"⅙";
  else if (fiveSixths == valueFractionalPart)
    stringFractionalPart = @"⅚";
  else
    return [NSString stringWithFormat:@"%f", value];  // got an unexpected fraction

  if (0 == valueIntegerPart)
    return stringFractionalPart;
  else
    return [NSString stringWithFormat:@"%.0f%@", valueIntegerPart, stringFractionalPart];
}

// -----------------------------------------------------------------------------
/// @brief Returns a new string made by appending the current device-specific
/// suffix (as returned by UIDevice::currentDeviceSuffix()) to the receiver.
///
/// @note This is a convenience method for clients that prefer to work with
/// NSStringAdditions.h instead of UIDeviceAdditions.h.
// -----------------------------------------------------------------------------
- (NSString*) stringByAppendingDeviceSuffix
{
  return [self stringByAppendingString:[UIDevice currentDeviceSuffix]];
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a koRule.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithKoRule:(enum GoKoRule)koRule
{
  switch (koRule)
  {
    case GoKoRuleSimple:
      return @"Simple";
    case GoKoRuleSuperkoPositional:
      return @"Positional superko";
    case GoKoRuleSuperkoSituational:
      return @"Situational superko";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a scoringSystem.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithScoringSystem:(enum GoScoringSystem)scoringSystem
{
  switch (scoringSystem)
  {
    case GoScoringSystemAreaScoring:
      return @"Area scoring";
    case GoScoringSystemTerritoryScoring:
      return @"Territory scoring";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a lifeAndDeathSettlingRule.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithLifeAndDeathSettlingRule:(enum GoLifeAndDeathSettlingRule)lifeAndDeathSettlingRule
{
  switch (lifeAndDeathSettlingRule)
  {
    case GoLifeAndDeathSettlingRuleTwoPasses:
      return @"2 passes";
    case GoLifeAndDeathSettlingRuleThreePasses:
      return @"3 passes";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a disputeResolutionRule.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithDisputeResolutionRule:(enum GoDisputeResolutionRule)disputeResolutionRule
{
  switch (disputeResolutionRule)
  {
    case GoDisputeResolutionRuleAlternatingPlay:
      return @"Alternating play";
    case GoDisputeResolutionRuleNonAlternatingPlay:
      return @"Non-alternating play";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a fourPassesRule.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithFourPassesRule:(enum GoFourPassesRule)fourPassesRule
{
  switch (fourPassesRule)
  {
    case GoFourPassesRuleFourPassesEndTheGame:
      return @"End game";
    case GoFourPassesRuleFourPassesHaveNoSpecialMeaning:
      return @"No special meaning";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a reason.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithMoveIsIllegalReason:(enum GoMoveIsIllegalReason)reason
{
  switch (reason)
  {
    case GoMoveIsIllegalReasonIntersectionOccupied:
      return @"Intersection is occupied";
    case GoMoveIsIllegalReasonSuicide:
      return @"Suicide";
    case GoMoveIsIllegalReasonSimpleKo:
      return @"Ko";
    case GoMoveIsIllegalReasonSuperko:
      return @"Superko";
    case GoMoveIsIllegalReasonUnknown:
    default:
      return @"Unknown reason";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a color.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithGoColor:(enum GoColor)color
{
  switch (color)
  {
    case GoColorBlack:
      return @"Black";
    case GoColorWhite:
      return @"White";
    case GoColorNone:
      return @"None";
    default:
      return @"Unknown";
  }
}

@end
