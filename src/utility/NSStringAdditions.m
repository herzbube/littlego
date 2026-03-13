// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
/// https://stackoverflow.com/questions/2765537/how-do-i-use-the-nsstring-draw-functionality-to-create-a-uiimage-from-text
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
/// @brief Returns a nicely formatted string for the fraction value @a value,
/// using a maximum precision of 6 decimal digits. The returned string does not
/// use thousands separators, which makes this method unsuitable for
/// representing large numbers. This method is designed to provide a nice
/// representation of komi and score values.
///
/// The fractional part of @a value is expected to be one of the following:
/// 0.0, 0.5, 0.25, 0.75, 0.2, 0.4, 0.6, 0.8, 0.125, 0.375, 0.625, 0.875,
/// 0.1666..., 0.333..., 0.666..., or 0.8333...
///
/// Generally, if the fractional part is 0.0, the string representation returned
/// by this method omits the fraction. If the fractional part is among those
/// recognized by this method, it is represented using the corresponding unicode
/// fraction character. If the fractional part is not among those recognized by
/// this method, it is rendered with a precision of up to 6 decimal digits
/// (trailing zero digits are removed).
///
/// Examples:
/// - A value of 6.5 results in the string representation "6½".
/// - A value of 6.0 results in "6".
/// - A value of 6.456 results in "6.456". If the maximum precision for double
///   values (std::numeric_limits<double>::max_digits10) were used for string
///   formatting, this would result in "6.4560000000000004". Because the
///   formatting precision is only 6 decimal digits, the formatting results in
///   "6.456000" from which the trailing zero digits are then removed.
///
/// A special case are values whose integral part is 0 and whose fractional
/// part is recognized by this method (e.g. 0.5): These values are represented
/// with the integral part omitted (e.g. 0.5 becomes "½", @b not "0½"). If the
/// fractional part is not recognized by this method, the usual "0." prefix
/// is used to represent the zero integral part.
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
  bool fractionIsRecognized = true;
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
  {
    fractionIsRecognized = false;
    // Perform string formatting with precision 6. Precision 6 is used because
    // that is also the default precision that the format specifier "%f" uses.
    stringFractionalPart = [NSString stringWithFormat:@"%.6f", valueFractionalPart];
    // Remove the zero digits at the end. Also remove the "0." prefix - this is
    // added back below.
    NSCharacterSet* characterSet = [NSCharacterSet characterSetWithCharactersInString:@"0."];
    stringFractionalPart = [stringFractionalPart stringByTrimmingCharactersInSet:characterSet];
  }

  if (0 == valueIntegerPart)
  {
    return (fractionIsRecognized
            ? stringFractionalPart
            : [@"0." stringByAppendingString:stringFractionalPart]);
  }
  else
  {
    return (fractionIsRecognized
            ? [NSString stringWithFormat:@"%.0f%@", valueIntegerPart, stringFractionalPart]
            : [NSString stringWithFormat:@"%.0f.%@", valueIntegerPart, stringFractionalPart]);
  }
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
    case GoMoveIsIllegalReasonTooManyMoves:
      return @"Too many moves";
    case GoMoveIsIllegalReasonUnknown:
    default:
      return @"Unknown reason";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes why placing a setup stone with stone
/// color @a stoneColor on intersection @a setupStoneIntersection would create
/// an illegal board position. @a reason specifies the kind of illegal board
/// position that would be created. If @a reason specifies that a stone or stone
/// group would be made illegal by placing the setup stone, then
/// @a illegalStoneOrGroupIntersection identifies the stone or stone group.
/// Otherwise @a illegalStoneOrGroupIntersection is ignored and can be nil.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithBoardSetupIsIllegalReason:(enum GoBoardSetupIsIllegalReason)reason
                                       setupStone:(NSString*)setupStoneIntersection
                                  setupStoneColor:(enum GoColor)setupStoneColor
                       createsIllegalStoneOrGroup:(NSString*)illegalStoneOrGroupIntersection
{
  NSString* friendlyColorName;
  NSString* opposingColorName;
  if (setupStoneColor == GoColorBlack)
  {
    friendlyColorName = @"black";
    opposingColorName = @"white";
  }
  else
  {
    opposingColorName = @"black";
    friendlyColorName = @"white";
  }

  NSString* mainMessage = [NSString stringWithFormat:@"Cannot place a %@ stone on intersection %@.", friendlyColorName, setupStoneIntersection];

  NSString* supplementalMessage;
  switch (reason)
  {
    case GoBoardSetupIsIllegalReasonSuicideSetupStone:
      supplementalMessage = @"The stone would have no liberties.";
      break;
    case GoBoardSetupIsIllegalReasonSuicideFriendlyStoneGroup:
      supplementalMessage = [NSString stringWithFormat:@"The stone would connect to the %@ stone group with %@ in it and take away that stone group's last liberty.", friendlyColorName, illegalStoneOrGroupIntersection];
      break;
    case GoBoardSetupIsIllegalReasonSuicideOpposingStone:
      supplementalMessage = [NSString stringWithFormat:@"The stone would take away all liberties from the %@ stone at intersection %@.", opposingColorName, illegalStoneOrGroupIntersection];
      break;
    case GoBoardSetupIsIllegalReasonSuicideOpposingStoneGroup:
      supplementalMessage = [NSString stringWithFormat:@"The stone would take away all liberties from the %@ stone group with %@ in it.", opposingColorName, illegalStoneOrGroupIntersection];
      break;
    case GoBoardSetupIsIllegalReasonSuicideOpposingColorSubgroup:
      supplementalMessage = [NSString stringWithFormat:@"The stone would split up a %@ stone group and take away all liberties from one of the resulting sub-groups (the one with %@ in it).", opposingColorName, illegalStoneOrGroupIntersection];
      break;
    default:
      supplementalMessage = @"The reason is unknown.";
      break;
  }

  return [NSString stringWithFormat:@"%@\n\n%@", mainMessage, supplementalMessage];
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

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a boardPositionValuation.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithBoardPositionValuation:(enum GoBoardPositionValuation)boardPositionValuation
{
  switch (boardPositionValuation)
  {
    case GoBoardPositionValuationGoodForBlack:
      return @"Good for black";
    case GoBoardPositionValuationVeryGoodForBlack:
      return @"Very good for black";
    case GoBoardPositionValuationGoodForWhite:
      return @"Good for white";
    case GoBoardPositionValuationVeryGoodForWhite:
      return @"Very good for white";
    case GoBoardPositionValuationEven:
      return @"Even";
    case GoBoardPositionValuationVeryEven:
      return @"Very even";
    case GoBoardPositionValuationUnclear:
      return @"Unclear";
    case GoBoardPositionValuationVeryUnclear:
      return @"Very unclear";
    case GoBoardPositionValuationNone:
      return @"No position valuation";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a moveValuation.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithMoveValuation:(enum GoMoveValuation)moveValuation
{
  switch (moveValuation)
  {
    case GoMoveValuationGood:
      return @"Good move";
    case GoMoveValuationVeryGood:
      return @"Very good move";
    case GoMoveValuationBad:
      return @"Bad move";
    case GoMoveValuationVeryBad:
      return @"Very bad move";
    case GoMoveValuationInteresting:
      return @"Interesting move";
    case GoMoveValuationDoubtful:
      return @"Doubtful move";
    case GoMoveValuationNone:
      return @"No move valuation";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a scoreSummary.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithScoreSummary:(enum GoScoreSummary)scoreSummary
{
  switch (scoreSummary)
  {
    case GoScoreSummaryBlackWins:
      return @"Black wins";
    case GoScoreSummaryWhiteWins:
      return @"White wins";
    case GoScoreSummaryTie:
      return @"Tie";
    case GoScoreSummaryNone:
      return @"No score information";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a scoreSummary and @a scoreValue.
// -----------------------------------------------------------------------------
+ (NSString*) shortStringWithScoreSummary:(enum GoScoreSummary)scoreSummary scoreValue:(double)scoreValue
{
  switch (scoreSummary)
  {
    case GoScoreSummaryBlackWins:
      return [@"B+" stringByAppendingString:[NSString stringWithFractionValue:scoreValue]];
    case GoScoreSummaryWhiteWins:
      return [@"W+" stringByAppendingString:[NSString stringWithFractionValue:scoreValue]];
    case GoScoreSummaryTie:
      return @"Tie";
    case GoScoreSummaryNone:
      return @"-";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a scoreSummary and @a scoreValue.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithScoreSummary:(enum GoScoreSummary)scoreSummary scoreValue:(double)scoreValue
{
  switch (scoreSummary)
  {
    case GoScoreSummaryBlackWins:
      return [@"Black wins by " stringByAppendingString:[NSString stringWithFractionValue:scoreValue]];
    case GoScoreSummaryWhiteWins:
      return [@"White wins by " stringByAppendingString:[NSString stringWithFractionValue:scoreValue]];
    case GoScoreSummaryTie:
      return @"Game is a tie";
    case GoScoreSummaryNone:
      return @"No score information";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a boardPositionHotspotDesignation.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithBoardPositionHotspotDesignation:(enum GoBoardPositionHotspotDesignation)boardPositionHotspotDesignation
{
  switch (boardPositionHotspotDesignation)
  {
    case GoBoardPositionHotspotDesignationYes:
      return @"Position is a hot spot";
    case GoBoardPositionHotspotDesignationYesEmphasized:
      return @"Position is an intense hot spot";
    case GoBoardPositionHotspotDesignationNone:
      return @"Position is not a hotspot";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a markupType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithMarkupType:(enum MarkupType)markupType
{
  switch (markupType)
  {
    case MarkupTypeSymbolCircle:
      return @"Circle symbol";
    case MarkupTypeSymbolSquare:
      return @"Square symbol";
    case MarkupTypeSymbolTriangle:
      return @"Triangle symbol";
    case MarkupTypeSymbolX:
      return @"\"X\" symbol";
    case MarkupTypeSymbolSelected:
      return @"\"Selected\" symbol";
    case MarkupTypeMarkerNumber:
      return @"Number marker";
    case MarkupTypeMarkerLetter:
      return @"Letter marker";
    case MarkupTypeLabel:
      return @"Label";
    case MarkupTypeConnectionLine:
      return @"Line";
    case MarkupTypeConnectionArrow:
      return @"Arrow";
    case MarkupTypeEraser:
      return @"Eraser";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns YES if @a string1 and @a string2 are both not @e nil and
/// are equal using a literal Unicode-based comparison. Also returns YES if
/// @a string1 and @a string2 are both @e nil. Returns NO in all other cases.
// -----------------------------------------------------------------------------
+ (BOOL) nullableString:(NSString*)string1 isEqualToNullableString:(NSString*)string2
{
  if (string1 && string2)
    return [string1 isEqualToString:string2];
  else
    return string1 == string2;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a periodBasedTimeSystemType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithPeriodBasedTimeSystemType:(enum GoTimeSystemType)periodBasedTimeSystemType
{
  switch (periodBasedTimeSystemType)
  {
    case GoTimeSystemTypeCanadian:
      return @"Canadian Timing";
    case GoTimeSystemTypeJapanese:
      return @"Japanese Timing";
    case GoTimeSystemTypeFischer:
      return @"Fischer Timing";
    case GoTimeSystemTypeSteadyAverage:
      return @"Steady Average Timing";
    case GoTimeSystemTypeTotalAverage:
      return @"Total Average Timing";
    case GoTimeSystemTypeNone:
      return @"No time system";
    case GoTimeSystemTypeCustom:
      return @"Custom time system";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a periodBasedTimeSystemType.
// -----------------------------------------------------------------------------
+ (NSString*) shortStringWithPeriodBasedTimeSystemType:(enum GoTimeSystemType)periodBasedTimeSystemType
{
  switch (periodBasedTimeSystemType)
  {
    case GoTimeSystemTypeCanadian:
      return @"Canadian";
    case GoTimeSystemTypeJapanese:
      return @"Japanese";
    case GoTimeSystemTypeFischer:
      return @"Fischer";
    case GoTimeSystemTypeSteadyAverage:
      return @"Steady Average";
    case GoTimeSystemTypeTotalAverage:
      return @"Total Average";
    case GoTimeSystemTypeNone:
      return @"None";
    case GoTimeSystemTypeCustom:
      return @"Custom";
    default:
      return @"Unknown";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a gameResultType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithGameResultType:(enum GoGameResultType)gameResultType
{
  switch (gameResultType)
  {
    case GoGameResultTypeBlackWin:
      return @"Black wins";
    case GoGameResultTypeWhiteWin:
      return @"White wins";
    case GoGameResultTypeDraw:
      return @"Game is a tie";
    case GoGameResultTypeNoResult:
      return @"No result / Suspended play";
    case GoGameResultTypeUnknownResult:
      return @"Unknown result";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a winType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithWinType:(enum GoGameResultWinType)winType
{
  switch (winType)
  {
    case GoGameResultWinTypeWinWithScore:
      return @"With score";
    case GoGameResultWinTypeWinWithoutScore:
      return @"Without score";
    case GoGameResultWinTypeWinByResignation:
      return @"By resignation";
    case GoGameResultWinTypeWinOnTime:
      return @"On time";
    case GoGameResultWinTypeWinByForfeit:
      return @"By forfeit";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns @a doubleValue represented as string, using a maximum
/// precision of 6 decimal digits. This method is designed to provide a string
/// that looks like the user would probably enter it into an input field, thus
/// making it suitable for providing a default value for such an input field.
///
/// The string returned by this method uses the "x.y" notation, where both
/// "x" and "y" consist of a series of digits 0-9. Notes:
/// - If "x" is 0, then the string returned by this method prefixes the
///   fractional part with "0.".
/// - If "y" is 0 then the string returned by this method omits the fractional
///   part.
/// - The returned string notably does not use thousands separators, and it
///   does not contain any "beautified" fractional values such as provided by
///   stringWithFractionValue:().
// -----------------------------------------------------------------------------
+ (NSString*) stringWithDouble:(double)doubleValue
{
  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  // The default after setting NSNumberFormatterDecimalStyle is 3. We prefer
  // to use the default precision of 6 that is also used by the "%f" format
  // specifier.
  numberFormatter.maximumFractionDigits = 6;
  numberFormatter.usesGroupingSeparator = NO;
  return [numberFormatter stringFromNumber:[NSNumber numberWithDouble:doubleValue]];
}

// -----------------------------------------------------------------------------
/// @brief Tries to convert this string into an int value. If conversion is
/// successful, returns @e true and fills @a intValue with the conversion
/// result (@a intValue must not be @e nil). If conversion fails, returns
/// @e false and does not change the value of @a intValue.
// -----------------------------------------------------------------------------
- (bool) tryConvertToIntValue:(int*)intValue
{
  if (self.length == 0)
    return false;

  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as an integer number. 1234.5678 is parsed as 1234.
  numberFormatter.numberStyle = NSNumberFormatterNoStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:self];
  if (! number)
    return false;

  *intValue = [number intValue];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Tries to convert this string into a double value. If conversion is
/// successful, returns @e true and fills @a doubleValue with the conversion
/// result (@a doubleValue must not be @e nil). If conversion fails, returns
/// @e false and does not change the value of @a doubleValue.
// -----------------------------------------------------------------------------
- (bool) tryConvertToDoubleValue:(double*)doubleValue
{
  if (self.length == 0)
    return false;

  NSNumberFormatter* numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
  // Parses the text as a decimal number
  numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
  // If the string contains any characters other than numerical digits or
  // locale-appropriate group or decimal separators, parsing will fail.
  // Leading/trailing space is ignored.
  // Returns nil if parsing fails.
  NSNumber* number = [numberFormatter numberFromString:self];
  if (! number)
    return false;

  *doubleValue = [number doubleValue];
  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a gameInfoRule.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithGameInfoRule:(enum GoGameInfoRule)gameInfoRule
{
  switch (gameInfoRule)
  {
    case GoGameInfoRuleNone:
      return @"No game rules";
    case GoGameInfoRuleSgfString:
      return @"Custom rule set name";
    case GoGameInfoRuleAGA:
      return @"AGA (American Go Association) rules";
    case GoGameInfoRuleIng:
      return @"Ing rules";
    case GoGameInfoRuleJapanese:
      return @"Nihon-Kiin rule set";
    case GoGameInfoRuleNewZealand:
      return @"New Zealand rules";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns an abbreviation string that describes @a rankType.
// -----------------------------------------------------------------------------
+ (NSString*) abbreviationStringWithRankType:(enum GoGameInfoRankType)rankType
{
  switch (rankType)
  {
    case GoGameInfoRankTypeKyu:
      return @"k";
    case GoGameInfoRankTypeAmateurDan:
      return @"d";
    case GoGameInfoRankTypeProfessionalDan:
      return @"p";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a rankType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithRankType:(enum GoGameInfoRankType)rankType
{
  switch (rankType)
  {
    case GoGameInfoRankTypeKyu:
      return @"Kyu";
    case GoGameInfoRankTypeAmateurDan:
      return @"Amateur Dan";
    case GoGameInfoRankTypeProfessionalDan:
      return @"Professional Dan";
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that describes @a ratingType.
// -----------------------------------------------------------------------------
+ (NSString*) stringWithRatingType:(enum GoGameInfoRatingType)ratingType
{
  switch (ratingType)
  {
    case GoGameInfoRatingTypeUncertain:
      return @"Uncertain";
    case GoGameInfoRatingTypeEstablished:
      return @"Established";
    case GoGameInfoRatingTypeUnspecified:
      return @"Unspecified";
  }
}

@end
