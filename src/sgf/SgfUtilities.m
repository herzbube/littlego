// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "SgfUtilities.h"
#import "../go/GoGameInfoRound.h"
#import "../go/GoGameResult.h"
#import "../go/GoTimeSettings.h"
#import "../go/GoTimeSystem.h"
#import "../play/model/TimeSettingsModel.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"


@implementation SgfUtilities

// -----------------------------------------------------------------------------
/// @brief Returns true if the load operation that resulted in @a readResult
/// is successful when @a loadSuccessType is active. Returns false if the load
/// operation was not successful.
// -----------------------------------------------------------------------------
+ (bool) isLoadOperationSuccessful:(SGFCDocumentReadResult*)readResult
               withLoadSuccessType:(enum SgfLoadSuccessType)loadSuccessType
{
  if (! readResult.isSgfDataValid)
    return false;

  // It doesn't matter what kind of messages we have - all are acceptable
  if (loadSuccessType == SgfLoadSuccessTypeWithCriticalWarningsOrErrors)
    return true;

  NSArray* parseResult = readResult.parseResult;

  // It doesn't matter what kind of messages we have - none are acceptable
  if (loadSuccessType == SgfLoadSuccessTypeNoWarningsOrErrors)
    return (parseResult.count == 0);

  for (SGFCMessage* message in readResult.parseResult)
  {
    if (message.isCriticalMessage)
      return false;
  }

  return true;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of the content of @a sgfBoardSize.
/// Returns an empty string if the board size is not valid.
// -----------------------------------------------------------------------------
+ (NSString*) stringForSgfBoardSize:(SGFCBoardSize)sgfBoardSize
{
  if (SGFCBoardSizeIsValid(sgfBoardSize, SGFCGameTypeGo))
    return [NSString stringWithFormat:@"%ld x %ld", (long)sgfBoardSize.Columns, (long)sgfBoardSize.Rows];
  else
    return @"";
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoBoardSize enumeration value that corresponds to
/// @a sgfBoardSize. Returns #GoBoardSizeUndefined if conversion is not
/// possible.
///
/// If conversion is not possible, and if the out parameter @a errorMessage is
/// not @e nil, also sets @a errorMessage to an error message that describes why
/// the conversion is not possible.
// -----------------------------------------------------------------------------
+ (enum GoBoardSize) goBoardSizeForSgfBoardSize:(SGFCBoardSize)sgfBoardSize errorMessage:(NSString**)errorMessage
{
  if (! SGFCBoardSizeIsValid(sgfBoardSize, SGFCGameTypeGo))
  {
    if (errorMessage)
      *errorMessage = [NSString stringWithFormat:@"The board size is not valid: %ld x %ld.", (long)sgfBoardSize.Columns, (long)sgfBoardSize.Rows];
    return GoBoardSizeUndefined;
  }

  if (! SGFCBoardSizeIsSquare(sgfBoardSize))
  {
    if (errorMessage)
      *errorMessage = [NSString stringWithFormat:@"The board size is not supported because it is not square: %ld x %ld.", (long)sgfBoardSize.Columns, (long)sgfBoardSize.Rows];
    return GoBoardSizeUndefined;
  }

  switch (sgfBoardSize.Columns)
  {
    case 7:
    case 9:
    case 11:
    case 13:
    case 15:
    case 17:
    case 19:
    {
      return (enum GoBoardSize)sgfBoardSize.Columns;
    }
    default:
    {
      if (errorMessage)
        *errorMessage = [NSString stringWithFormat:@"The board size is not supported: %ld x %ld.", (long)sgfBoardSize.Columns, (long)sgfBoardSize.Rows];
      return GoBoardSizeUndefined;
    }
  }
}


// -----------------------------------------------------------------------------
/// @brief Parses @e sgfGameDates, whose elements must be NSValue objects
/// wrapping SGFCDate values, and fills the result into the out variables
/// @a dateArray (elements are NSDate objects) and @a stringArray (elements are
/// NSString objects).
///
/// SGFCDate values found in @a sgfGameDates for which
/// SGFCDateIsValidCalendarDate() returns NO are ignored.
// -----------------------------------------------------------------------------
+ (void) parseSgfGameDates:(NSArray*)sgfGameDates dateArray:(NSArray**)dateArray stringArray:(NSArray**)stringArray
{
  NSMutableArray* mutableDateArray = [NSMutableArray array];
  NSMutableArray* mutableStringArray = [NSMutableArray array];

  NSCalendar* calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
  NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
  [dateFormatter setLocale:[NSLocale currentLocale]];
  [dateFormatter setDateStyle:NSDateFormatterMediumStyle];

  for (NSValue* sgfGameDateAsValue in sgfGameDates)
  {
    SGFCDate sgfGameDate = sgfGameDateAsValue.sgfcDateValue;
    if (! SGFCDateIsValidCalendarDate(sgfGameDate))
      continue;

    NSDateComponents* gameDateComponents = [[[NSDateComponents alloc] init] autorelease];
    gameDateComponents.year = sgfGameDate.Year;
    gameDateComponents.month = sgfGameDate.Month;
    gameDateComponents.day = sgfGameDate.Day;

    NSDate* gameDate = [calendar dateFromComponents:gameDateComponents];
    NSString* gameDateAsString = [dateFormatter stringFromDate:gameDate];

    [mutableDateArray addObject:gameDateAsString];
    [mutableStringArray addObject:gameDateAsString];
  }

  *dateArray = mutableDateArray;
  *stringArray = mutableStringArray;
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of the content of @a sgfGoPlayerRank.
/// Returns an empty string if the SGFCGoPlayerRank is not valid.
// -----------------------------------------------------------------------------
+ (NSString*) stringForSgfGoPlayerRank:(SGFCGoPlayerRank)sgfGoPlayerRank
{
  if (! sgfGoPlayerRank.IsValid)
    return @"";

  NSString* rankTypeAsString;
  switch (sgfGoPlayerRank.RankType)
  {
    case SGFCGoPlayerRankTypeKyu:
      rankTypeAsString = @"kyu";
      break;
    case SGFCGoPlayerRankTypeAmateurDan:
      rankTypeAsString = @"dan";
      break;
    case SGFCGoPlayerRankTypeProfessionalDan:
      rankTypeAsString = @"p";
      break;
    default:
      assert(0);
      return @"";
  }

  NSString* ratingTypeAsString;
  switch (sgfGoPlayerRank.RatingType)
  {
    case SGFCGoPlayerRatingTypeUncertain:
      ratingTypeAsString = @" (uncertain)";
      break;
    case SGFCGoPlayerRatingTypeEstablished:
      ratingTypeAsString = @" (established)";
      break;
    case SGFCGoPlayerRatingTypeUnspecified:
      ratingTypeAsString = @"";
      break;
    default:
      assert(0);
      return @"";
  }

  return [NSString stringWithFormat:@"%ld %@%@", (long)sgfGoPlayerRank.Rank, rankTypeAsString, ratingTypeAsString];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color that represents a load result with no messages.
// -----------------------------------------------------------------------------
+ (UIColor*) colorForLoadResultWithNoMessages
{
  return [UIColor malachiteColor];
}

// -----------------------------------------------------------------------------
/// @brief Returns a color that represents a load result that contains messages
/// with message type @a messageType and criticality @a isCriticalMessage.
// -----------------------------------------------------------------------------
+ (UIColor*) colorForLoadResultWithMessagesOfType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage
{
  if (messageType == SGFCMessageTypeFatalError || isCriticalMessage)
    return [UIColor pantoneRedColor];
  else if (messageType == SGFCMessageTypeError)
    return [UIColor orangeColor];
  else
    return [UIColor ncsYellowColor];
}

// -----------------------------------------------------------------------------
/// @brief Returns a colored indicator that can be used as the image of a
/// table view cell that, in some way or other, shows an overall classification
/// of @a loadResult.
// -----------------------------------------------------------------------------
+ (UIImage*) coloredIndicatorForLoadResult:(SGFCDocumentReadResult*)loadResult
{
  static UIImage* noWarningsAndErrorsImage = nil;
  static UIImage* someNonCriticalWarningsImage = nil;
  static UIImage* someNonCriticalErrorsImage = nil;
  static UIImage* criticalWarningsOrErrorsOrFatalErrorsImage = nil;

  int numberOfNonCriticalWarnings = 0;
  int numberOfNonCriticalErrors = 0;
  int numberCriticalMessages = 0;
  int numberOfFatalErrors = 0;
  for (SGFCMessage* message in loadResult.parseResult)
  {
    if (message.isCriticalMessage)
      numberCriticalMessages++;
    else if (message.messageType == SGFCMessageTypeWarning)
      numberOfNonCriticalWarnings++;
    else if (message.messageType == SGFCMessageTypeError)
      numberOfNonCriticalErrors++;
    else
      numberOfFatalErrors++;
  }

  if (loadResult.parseResult.count == 0)
  {
    if (! noWarningsAndErrorsImage)
    {
      UIColor* color = [SgfUtilities colorForLoadResultWithNoMessages];
      noWarningsAndErrorsImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return noWarningsAndErrorsImage;
  }
  else if (numberOfFatalErrors > 0 || numberCriticalMessages > 0)
  {
    if (! criticalWarningsOrErrorsOrFatalErrorsImage)
    {
      UIColor* color = [SgfUtilities colorForLoadResultWithMessagesOfType:SGFCMessageTypeFatalError isCriticalMessage:false];
      criticalWarningsOrErrorsOrFatalErrorsImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return criticalWarningsOrErrorsOrFatalErrorsImage;
  }
  else if (numberOfNonCriticalErrors > 0)
  {
    if (! someNonCriticalErrorsImage)
    {
      UIColor* color = [SgfUtilities colorForLoadResultWithMessagesOfType:SGFCMessageTypeError isCriticalMessage:false];
      someNonCriticalErrorsImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return someNonCriticalErrorsImage;
  }
  else
  {
    if (! someNonCriticalWarningsImage)
    {
      UIColor* color = [SgfUtilities colorForLoadResultWithMessagesOfType:SGFCMessageTypeWarning isCriticalMessage:false];
      someNonCriticalWarningsImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return someNonCriticalWarningsImage;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a color that represents an SGFCMessage with message type
/// @a messageType and criticality @a isCriticalMessage.
// -----------------------------------------------------------------------------
+ (UIColor*) colorForMessageType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage
{
  return [SgfUtilities colorForLoadResultWithMessagesOfType:messageType isCriticalMessage:isCriticalMessage];
}

// -----------------------------------------------------------------------------
/// @brief Returns a colored indicator that can be used as the image of a
/// table view cell that, in some way or other, shows the classification of
/// @a message.
// -----------------------------------------------------------------------------
+ (UIImage*) coloredIndicatorForMessage:(SGFCMessage*)message
{
  static UIImage* nonCriticalWarningImage = nil;
  static UIImage* nonCriticalErrorImage = nil;
  static UIImage* criticalWarningOrErrorOrFatalErrorImage = nil;

  if (message.messageType == SGFCMessageTypeFatalError || message.isCriticalMessage)
  {
    if (! criticalWarningOrErrorOrFatalErrorImage)
    {
      UIColor* color = [SgfUtilities colorForMessageType:message.messageType isCriticalMessage:message.isCriticalMessage];
      criticalWarningOrErrorOrFatalErrorImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return criticalWarningOrErrorOrFatalErrorImage;
  }
  else if (message.messageType == SGFCMessageTypeError)
  {
    if (! nonCriticalErrorImage)
    {
      UIColor* color = [SgfUtilities colorForMessageType:message.messageType isCriticalMessage:message.isCriticalMessage];
      nonCriticalErrorImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return nonCriticalErrorImage;
  }
  else
  {
    if (! nonCriticalWarningImage)
    {
      UIColor* color = [SgfUtilities colorForMessageType:message.messageType isCriticalMessage:message.isCriticalMessage];
      nonCriticalWarningImage = [[UiUtilities circularTableCellViewIndicatorWithColor:color] retain];
    }
    return nonCriticalWarningImage;
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string that identifies @a timeSystemType when used as part
/// of the value of the SGF property OT. Returns @e nil if there is no such
/// identifier. This is notably the case for #GoTimeSystemTypeCustom - the
/// SGF property value here must be the entire description.
// -----------------------------------------------------------------------------
+ (NSString*) sgfTimeSystemIdentifierForTimeSystemType:(enum GoTimeSystemType)timeSystemType
{
  switch (timeSystemType)
  {
    case GoTimeSystemTypeCanadian:
      return @"Canadian";
    case GoTimeSystemTypeJapanese:
      return @"byo-yomi";
    case GoTimeSystemTypeFischer:
      return @"Fischer";
    case GoTimeSystemTypeSteadyAverage:
      return @"SteadyAverage";
    case GoTimeSystemTypeTotalAverage:
      return @"TotalAverage";
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Attempts to detect a time system type in @a sgfTimeSystemIdentifier.
/// @a sgfTimeSystemIdentifier is a part of the value of the SGF property OT.
/// Returns #GoTimeSystemTypeCustom if the time system type cannot be detected.
///
/// The detection logic performs a case-insensitive search for certain keywords
/// in @a sgfTimeSystemIdentifier.
// -----------------------------------------------------------------------------
+ (enum GoTimeSystemType) timeSystemTypeForSgfTimeSystemIdentifier:(NSString*)sgfTimeSystemIdentifier
{
  NSString* sgfTimeSystemIdentifierLowerCase = [sgfTimeSystemIdentifier lowercaseString];

  if ([sgfTimeSystemIdentifierLowerCase containsString:@"canadian"] ||
      [sgfTimeSystemIdentifierLowerCase containsString:@"canada"])
  {
    return GoTimeSystemTypeCanadian;
  }
  else if ([sgfTimeSystemIdentifierLowerCase containsString:@"byo-yomi"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"byoyomi"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"byo yomi"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"japanese"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"japan"])
  {
    return GoTimeSystemTypeJapanese;
  }
  else if ([sgfTimeSystemIdentifierLowerCase containsString:@"fischer"])
  {
    return GoTimeSystemTypeFischer;
  }
  else if ([sgfTimeSystemIdentifierLowerCase containsString:@"steadyaverage"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"steady average"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"steady"])
  {
    return GoTimeSystemTypeSteadyAverage;
  }
  else if ([sgfTimeSystemIdentifierLowerCase containsString:@"totalaverage"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"total average"] ||
           [sgfTimeSystemIdentifierLowerCase containsString:@"total"])
  {
    return GoTimeSystemTypeTotalAverage;
  }
  else
  {
    return GoTimeSystemTypeCustom;
  }
}

// -----------------------------------------------------------------------------
/// @brief Converts the data in @a periodBasedTimeSystem to a string that can
/// be stored in the SGF property OT. Returns @e nil if @a periodBasedTimeSystem
/// has a time system type that cannot be encoded in the SGF property OT.
// -----------------------------------------------------------------------------
+ (NSString*) sgfOvertimeStringForPeriodBasedTimeSystem:(GoTimeSystem*)periodBasedTimeSystem
{
  NSString* sgfTimeSystemIdentifier = [SgfUtilities sgfTimeSystemIdentifierForTimeSystemType:periodBasedTimeSystem.goTimeSystemType];

  switch (periodBasedTimeSystem.goTimeSystemType)
  {
    case GoTimeSystemTypeCustom:
      return periodBasedTimeSystem.customTimeSystemDescription;
    case GoTimeSystemTypeCanadian:
      // Both KGS and online-go.com use "/" as separator
      return [NSString stringWithFormat:@"%lu/%@ %@",
              periodBasedTimeSystem.minimumNumberOfMovesPerPeriod,
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.periodDurationInSeconds],
              sgfTimeSystemIdentifier];
    case GoTimeSystemTypeJapanese:
      // Both KGS and online-go.com use "x" as separator
      return [NSString stringWithFormat:@"%lux%@ %@",
              periodBasedTimeSystem.numberOfPeriods,
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.periodDurationInSeconds],
              sgfTimeSystemIdentifier];
    case GoTimeSystemTypeFischer:
      // Only online-go.com supports Fischer Timing. Unlike online-go.com we
      // encode the initial duration in the SGF property OT, not in TM, because
      // we want to be able to combine Fischer Timing with Absolute Timing.
      return [NSString stringWithFormat:@"%@/%@ %@",
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.extraTimeDurationInSeconds],
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.periodDurationInSeconds],
              sgfTimeSystemIdentifier];
    case GoTimeSystemTypeSteadyAverage:
      // Neither KGS nor online-go.com support Steady Average Timing
      return [NSString stringWithFormat:@"%lu/%@ %@",
              periodBasedTimeSystem.minimumNumberOfMovesPerPeriod,
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.periodDurationInSeconds],
              sgfTimeSystemIdentifier];
    case GoTimeSystemTypeTotalAverage:
      // Neither KGS nor online-go.com support Total Average Timing
      return [NSString stringWithFormat:@"%lu/%@ %@",
              periodBasedTimeSystem.minimumNumberOfMovesPerPeriod,
              [SgfUtilities sgfDurationStringForDurationValue:periodBasedTimeSystem.periodDurationInSeconds],
              sgfTimeSystemIdentifier];
    case GoTimeSystemTypeAbsolute:
    case GoTimeSystemTypeNone:
    default:
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief Parses @a sgfOvertimeString (assumed to be the value of the SGF
/// property OT) and returns the result as GoTimeSystem object.
///
/// The returned object has #GoTimeSystemTypeCustom if @a sgfOvertimeString is
/// not recognized as a time system that the app supports, or if the values
/// that result from parsing are invalid (e.g. period duration zero).
///
/// In some cases, if this method is unable to find a duration in
/// @a sgfOvertimeString, it will try to use the value of
/// @a absoluteTimeDuration as a substitute. If the caller passes @e nil for
/// @a absoluteTimeDuration then this method will not attempt a substitution.
///
/// This method sets @a didConsumeAbsoluteTimeDuration to indicate whether or
/// not it performed substitution. The caller may pass @e nil for
/// @a didConsumeAbsoluteTimeDuration if it is not interested in whether
/// or not substitution takes place.
///
/// @note This method attempts substitution only if it identifies the time
/// system as #GoTimeSystemTypeFischer. This is to support SGF content
/// produced by online-go.com: that platform encodes the initial duration in
/// the SGF property TM, even though that property is intended to be used for
/// absolute time.
// -----------------------------------------------------------------------------
+ (GoTimeSystem*) periodBasedTimeSystemForSgfOvertimeString:(NSString*)sgfOvertimeString
                                       absoluteTimeDuration:(double*)absoluteTimeDuration
                             didConsumeAbsoluteTimeDuration:(bool*)didConsumeAbsoluteTimeDuration
{
  if (didConsumeAbsoluteTimeDuration)
    *didConsumeAbsoluteTimeDuration = false;

  GoTimeSystem* timeSystem = [SgfUtilities canadianTimeSystemForSgfOvertimeStringInSgfNotation:sgfOvertimeString];
  if (timeSystem.goTimeSystemType == GoTimeSystemTypeCanadian)
    return timeSystem;

  return [SgfUtilities periodBasedTimeSystemForSgfOvertimeStringInAppNotation:sgfOvertimeString
                                                         absoluteTimeDuration:absoluteTimeDuration
                                               didConsumeAbsoluteTimeDuration:didConsumeAbsoluteTimeDuration];
}

// -----------------------------------------------------------------------------
/// @brief Parses @a sgfOvertimeString (assumed to be the value of the SGF
/// property OT) and returns the result as GoTimeSystem object. The parsing
/// assumes that one of the notations is used that is shown in the examples in
/// the FF4 SGF specification. Note that not all example notations are
/// supported.
///
/// The returned object has #GoTimeSystemTypeCanadian if parsing of
/// @a sgfOvertimeString succeeds and the values that result from parsing are
/// valid. The returned object has #GoTimeSystemTypeCustom if parsing of
/// @a sgfOvertimeString fails, or if the values that result from parsing are
/// invalid (e.g. period duration zero).
///
/// The FF4 SGF specification shows the following examples for OT strings:
/// - "5 mins Japanese style, 1 move / min"
/// - "25 moves / 10 min"
///
/// The first of these notations is ambiguous and not supported by the current
/// implementation of this method. Is the period duration 1 minute (as implied
/// by "1 move / min") or 5 minutes (as implied by "5 mins")? If the period
/// duration is 5 minutes, what then does "1 move / min" mean? If the period
/// duration is 1 minute, does "5 mins" then actually mean "5 periods"?
///
/// The second of these notations does not specify the time system, but assuming
/// that Canadian Timing is used, it can be considered as complete. GoGui has
/// been observed to use this notation, with the variation of using different
/// time units:
/// - "<n> moves / <n> min"
/// - "<n> moves / <n> sec"
///
/// The current implementation of this method expands on this and recognizes
/// these patterns:
/// - "<n> moves / <n> h", indicating "hours" as the time unit
/// - "<n> moves / <n> m", indicating "minutes" as the time unit
/// - "<n> moves / <n> s", indicating "seconds" as the time unit
///
/// To remain flexible, the current implementation accepts any amount of
/// whitespace (minimum 1 character) in between the tokens, "moves" can also
/// be "move" (singular), and any characters after the single time unit
/// character are ignored. Sensible values would be "hour", "hours", "minute",
/// "minutes", "second" or "seconds".
///
/// For future implementations, an attempt to recognize data in a poorly
/// structured @a sgfOvertimeString might look for regex patterns like these:
/// - "[0-9\.]+ min(s)?" => indicates a period duration
/// - "[0-9]+ move(s)?" => indicates a minimum number of moves
/// - "[0-9]+ period(s)?" => indicates a number of periods
/// - "[0-9]+ extra" => indicates an extra time duration
/// - The time system could be derived if a keyword is found anywhere in the
///   string.
// -----------------------------------------------------------------------------
+ (GoTimeSystem*) canadianTimeSystemForSgfOvertimeStringInSgfNotation:(NSString*)sgfOvertimeString
{
  NSString* pattern = @"^([0-9]+)(\\s+moves?\\s+/\\s+)([0-9\\.]+)(\\s+)((s|m|h))(.*)$";
  //                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //                     |       |                    |          |     |       +-- Rest of time unit
  //                     |       |                    |          |     +-- Time unit identifier
  //                     |       |                    |          +-- Whitespace separator, minimum 1 character
  //                     |       |                    +-- Second number
  //                     |       |
  //                     |       +-- Blurb separator " moves / "
  //                     +-- First number
  //
  // Notes:
  // - The first and second number patterns don't accept negative numbers.
  // - The second number pattern accepts fractional values.
  // - The second number pattern matches on ".", i.e. no digits. Below
  //   this will be converted into the double value 0.0.
  // - The blurb separator pattern accepts any amount of whitespace (minimum 1
  //   character), not just single space characters.
  // - The blurb separator pattern matches "move" as well as "moves" (although
  //   "moves" is the expected case).
  // - The time unit identifier pattern results in "s", "m" or "h", indicating
  //   the respective time units "seconds", "minutes" and "hours".

  NSError* error = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
  NSRange entireString = NSMakeRange(0, sgfOvertimeString.length);
  NSArray* matches = [regex matchesInString:sgfOvertimeString
                                    options:0
                                      range:entireString];
  if (matches.count == 0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSTextCheckingResult* theMatch = matches[0];

  NSRange minimumNumberOfMovesRange = [theMatch rangeAtIndex:1];
  NSString* minimumNumberOfMovesString = [sgfOvertimeString substringWithRange:minimumNumberOfMovesRange];
  NSInteger minimumNumberOfMoves = [minimumNumberOfMovesString integerValue];
  if (minimumNumberOfMoves == 0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSRange periodDurationRange = [theMatch rangeAtIndex:3];
  NSString* periodDurationString = [sgfOvertimeString substringWithRange:periodDurationRange];
  double periodDuration = [periodDurationString doubleValue];
  if (periodDuration == 0.0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSRange timeUnitIdentifierRange = [theMatch rangeAtIndex:5];
  NSString* timeUnitIdentifierString = [sgfOvertimeString substringWithRange:timeUnitIdentifierRange];
  double periodDurationInSeconds;
  if ([timeUnitIdentifierString isEqualToString:@"s"])
    periodDurationInSeconds = periodDuration;
  else if ([timeUnitIdentifierString isEqualToString:@"m"])
    periodDurationInSeconds = periodDuration * 60;
  else
    periodDurationInSeconds = periodDuration * 3600;

  return [[[GoTimeSystem alloc] initWithGoTimeSystemType:GoTimeSystemTypeCanadian
                                 periodDurationInSeconds:periodDurationInSeconds
                           minimumNumberOfMovesPerPeriod:minimumNumberOfMoves] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Parses @a sgfOvertimeString (assumed to be the value of the SGF
/// property OT) and returns the result as GoTimeSystem object. The parsing
/// assumes that a notation is used that is partially also supported by KGS and
/// online-go.com, but was enhanced for this app to also support
/// #GoTimeSystemTypeSteadyAverage and #GoTimeSystemTypeTotalAverage.
///
/// The returned object has #GoTimeSystemTypeCustom if @a sgfOvertimeString is
/// not recognized as a time system that the app supports, or if the values
/// that result from parsing are invalid (e.g. period duration zero).
///
/// In some cases, if this method is unable to find a duration in
/// @a sgfOvertimeString, it will try to use the value of
/// @a absoluteTimeDuration as a substitute. If the caller passes @e nil for
/// @a absoluteTimeDuration then this method will not attempt a substitution.
///
/// This method sets @a didConsumeAbsoluteTimeDuration to indicate whether or
/// not it performed substitution. The caller may pass @e nil for
/// @a didConsumeAbsoluteTimeDuration if it is not interested in whether
/// or not substitution takes place.
///
/// @note This method attempts substitution only if it identifies the time
/// system as #GoTimeSystemTypeFischer. This is to support SGF content
/// produced by online-go.com: that platform encodes the initial duration in
/// the SGF property TM, even though that property is intended to be used for
/// absolute time.
///
/// The current implementation of this method recognizes these patterns:
/// - "<number-of-moves-or-periods>/<period-duration> <time-system-identifier>"
/// - "<number-of-moves-or-periods>x<period-duration> <time-system-identifier>"
/// - "<extra-time-duration> <time-system-identifier>"
///
/// Japanese Timing is the only time system expected to use the "x" separator,
/// but the current implementation does not enforce this. Fischer Timing is
/// the only time system expected to use the third pattern. Time system
/// identifiers are parsed in timeSystemTypeForSgfTimeSystemIdentifier:().
// -----------------------------------------------------------------------------
+ (GoTimeSystem*) periodBasedTimeSystemForSgfOvertimeStringInAppNotation:(NSString*)sgfOvertimeString
                                                    absoluteTimeDuration:(double*)absoluteTimeDuration
                                          didConsumeAbsoluteTimeDuration:(bool*)didConsumeAbsoluteTimeDuration
{
  NSString* pattern = @"^([0-9\\.]+)(([/x])([0-9\\.]+))?(\\s+)(.+)$";
  //                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  //                     |          ||     |            |     +-- Time system identifier, minimum 1 character
  //                     |          ||     |            +-- Whitespace separator, minimum 1 character
  //                     |          ||     +-- Second number
  //                     |          |+-- Separator between first and second number
  //                     |          +-- Separator + second number are optional
  //                     +-- First number
  //
  // Notes:
  // - The first and second number patterns don't accept negative numbers.
  // - The first and second number patterns accept fractional values. Below we
  //   make sure that fractional values are only allowed for durations.
  // - The first and second number patterns match on ".", i.e. no digits. Below
  //   this will be converted into the double value 0.0.
  // - Separator characters between the first and second number are restricted
  //   to "/" and "x". Japanese Timing is expected to use "x", while the other
  //   time systems are expected to use "/". Below we're not validating this,
  //   though.
  NSError* error = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                         options:0
                                                                           error:&error];
  NSRange entireString = NSMakeRange(0, sgfOvertimeString.length);
  NSArray* matches = [regex matchesInString:sgfOvertimeString
                                    options:0
                                      range:entireString];
  if (matches.count == 0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSTextCheckingResult* theMatch = matches[0];

  NSRange timeSystemIdentifierRange = [theMatch rangeAtIndex:6];
  NSString* timeSystemIdentifier = [sgfOvertimeString substringWithRange:timeSystemIdentifierRange];
  enum GoTimeSystemType timeSystemType = [SgfUtilities timeSystemTypeForSgfTimeSystemIdentifier:timeSystemIdentifier];
  if (timeSystemType == GoTimeSystemTypeCustom)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSRange firstNumberRange = [theMatch rangeAtIndex:1];
  NSString* firstNumberString = [sgfOvertimeString substringWithRange:firstNumberRange];
  double firstNumber = [firstNumberString doubleValue];
  if (firstNumber == 0.0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  NSRange secondNumberRange = [theMatch rangeAtIndex:4];
  NSRange notFoundRange = NSMakeRange(NSNotFound, 0);
  if (NSEqualRanges(secondNumberRange, notFoundRange))
  {
    if (timeSystemType != GoTimeSystemTypeFischer ||
        ! absoluteTimeDuration ||
        *absoluteTimeDuration <= 0)
    {
      return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];
    }

    if (didConsumeAbsoluteTimeDuration)
      *didConsumeAbsoluteTimeDuration = true;

    return [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:*absoluteTimeDuration
                                                   extraTimeDurationInSeconds:firstNumber] autorelease];
  }

  NSString* secondNumberString = [sgfOvertimeString substringWithRange:secondNumberRange];
  double secondNumber = [secondNumberString doubleValue];
  if (secondNumber == 0)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  if (timeSystemType == GoTimeSystemTypeFischer)
  {
    return [[[GoTimeSystem alloc] initWithFischerTimeInitialDurationInSeconds:secondNumber
                                                   extraTimeDurationInSeconds:firstNumber] autorelease];
  }

  bool firstNumberHasFractionalValue = (firstNumber != trunc(firstNumber));
  if (firstNumberHasFractionalValue)
    return [[[GoTimeSystem alloc] initWithCustomTimeSystemDescription:sgfOvertimeString] autorelease];

  if (timeSystemType == GoTimeSystemTypeJapanese)
  {
    return [[[GoTimeSystem alloc] initWithJapaneseTimeNumberOfPeriods:firstNumber
                                              periodDurationInSeconds:secondNumber] autorelease];
  }

  return [[[GoTimeSystem alloc] initWithGoTimeSystemType:timeSystemType
                                 periodDurationInSeconds:secondNumber
                           minimumNumberOfMovesPerPeriod:firstNumber] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Converts @a durationValue to a string that can be incorporated into
/// an SGF text property. The counterpart of this method is
/// durationValueFromSgfDurationString:().
///
/// A precision of 2 digits after the decimal point is used for the conversion.
/// @a durationValue is rounded to the nearest 2 digits. Any trailing "0" (zero)
/// and "." (decimal point) characters are removed. Examples:
/// - Double value 2.0 is converted to "2"
/// - Double value 2.5 is converted to "2.5"
/// - Double value 2.50 is converted to "2.5"
/// - Double value 2.555 is converted to "2.56"
// -----------------------------------------------------------------------------
+ (NSString*) sgfDurationStringForDurationValue:(double)durationValue
{
  static NSRegularExpression* regex = nil;
  if (! regex)
  {
    NSString* pattern = @"^([0-9]+)(\\.0*)$";
    NSError* error = nil;
    regex = [[NSRegularExpression regularExpressionWithPattern:pattern
                                                       options:0
                                                         error:&error] retain];
  }

  NSString* durationValueAsString = [NSString stringWithFormat:@"%.2f", durationValue];

  // Remove a sole trailing decimal point (".") without digits, or a decimal
  // point (".") with one or more 0 (zero) digits
  return [regex stringByReplacingMatchesInString:durationValueAsString
                                         options:0
                                           range:NSMakeRange(0, durationValueAsString.length)
                                    withTemplate:@"$1"];
}

// -----------------------------------------------------------------------------
/// @brief Converts @a sgfDurationString to a double value. The counterpart of
/// this method is sgfDurationStringForDurationValue:().
///
/// To remain in sync with sgfDurationStringForDurationValue:(), the value
/// returned is rounded to the nearest 2 digits after the decimal point.
// -----------------------------------------------------------------------------
+ (double) durationValueFromSgfDurationString:(NSString*)sgfDurationString
{
  double durationValue = [sgfDurationString doubleValue];
  return round(durationValue * 100.0) / 100.0;
}

// -----------------------------------------------------------------------------
/// @brief Returns a TimeSettingsModel object that is populated with the time
/// settings (if any) stored in @a sgfGameInfoNode.
// -----------------------------------------------------------------------------
+ (TimeSettingsModel*) timeSettingsFromSgfGameInfoNode:(SGFCNode*)sgfGameInfoNode
{
  double tmPropertyValue = 0.0;
  double* tmPropertyValuePointer = nil;
  SGFCProperty* tmProperty = [sgfGameInfoNode propertyWithType:SGFCPropertyTypeTM];
  if (tmProperty)
  {
    tmPropertyValue = tmProperty.propertyValue.toSingleValue.toRealValue.realValue;
    tmPropertyValuePointer = &tmPropertyValue;
  }

  SGFCProperty* otProperty = [sgfGameInfoNode propertyWithType:SGFCPropertyTypeOT];
  NSString* otPropertyValue = (otProperty
                               ? otProperty.propertyValue.toSingleValue.toSimpleTextValue.simpleTextValue
                               : nil);

  return [SgfUtilities timeSettingsFromTmPropertyValue:tmPropertyValuePointer
                                       otPropertyValue:otPropertyValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns a TimeSettingsModel object that is populated with the time
/// settings (if any) stored in @a sgfGameInfo.
///
/// Implementation note: Unfortunately SGFCGameInfo does not unambiguously
/// indicate the presence or absence of the TM and OT properties. We need to
/// determine the presence or absence by comparing the values provided by
/// SGFCGameInfo with conventional defaults, i.e. 0 (zero) duration for TM and
/// an empty string for OT.
// -----------------------------------------------------------------------------
+ (TimeSettingsModel*) timeSettingsFromSgfGameInfo:(SGFCGameInfo*)sgfGameInfo
{
  // The value 0 (zero) conventionally indicates property absence. Strictly
  // speaking a TM property could be present and have value zero, but it is
  // unlikely that any Go application which writes SGF would operate with a
  // zero duration for absolute time. Also, this app is not designed to work
  // with a zero duration (e.g. the GoTimeSystem initializer would throw an
  // exception).
  double tmPropertyValue = sgfGameInfo.timeLimitInSeconds;
  double* tmPropertyValuePointer = (sgfGameInfo.timeLimitInSeconds != 0.0
                                    ? &tmPropertyValue
                                    : nil);

  // An empty string conventionally indicates property absence. Strictly
  // speaking an OT property could be present and have an empty string value,
  // but it is unlikely that any Go application which writes SGF would use an
  // empty string to describe the time system that they used. This app would be
  // capable of working with an empty description, but from a user perspective
  // it would not make much sense.
  NSString* otPropertyValue = (sgfGameInfo.overtimeInformation.length > 0
                               ? sgfGameInfo.overtimeInformation
                               : nil);

  return [SgfUtilities timeSettingsFromTmPropertyValue:tmPropertyValuePointer
                                       otPropertyValue:otPropertyValue];
}

// -----------------------------------------------------------------------------
/// @brief Returns a TimeSettingsModel object that is populated with the time
/// settings taken from the values of @a tmPropertyValue and @a otPropertyValue.
///
/// The two parameters refer to the values of the SGF game info properties TM
/// and OT. The value @e nil indicates that the respective property is not
/// present.
// -----------------------------------------------------------------------------
+ (TimeSettingsModel*) timeSettingsFromTmPropertyValue:(double*)tmPropertyValue
                                       otPropertyValue:(NSString*)otPropertyValue
{
  bool absoluteTimingEnabled = false;
  double absoluteTimingDurationInSeconds = 0;
  if (tmPropertyValue && *tmPropertyValue > 0)
  {
    absoluteTimingEnabled = true;
    absoluteTimingDurationInSeconds = *tmPropertyValue;
  }

  GoTimeSystem* periodBasedTimeSystem = [[[GoTimeSystem alloc] init] autorelease];
  if (otPropertyValue)
  {
    double* absoluteTimeDurationPointer = (absoluteTimingEnabled
                                           ? &absoluteTimingDurationInSeconds
                                           : nil);
    bool didConsumeAbsoluteTimeDuration;
    periodBasedTimeSystem = [SgfUtilities periodBasedTimeSystemForSgfOvertimeString:otPropertyValue
                                                               absoluteTimeDuration:absoluteTimeDurationPointer
                                                     didConsumeAbsoluteTimeDuration:&didConsumeAbsoluteTimeDuration];
    if (didConsumeAbsoluteTimeDuration)
    {
      absoluteTimingEnabled = false;
      absoluteTimingDurationInSeconds = 0.0;
    }
  }

  GoTimeSystem* absoluteTimeSystem = nil;
  if (absoluteTimingEnabled)
    absoluteTimeSystem = [[[GoTimeSystem alloc] initWithAbsoluteTimeDurationInSeconds:absoluteTimingDurationInSeconds] autorelease];
  else
    absoluteTimeSystem = [[[GoTimeSystem alloc] init] autorelease];

  GoTimeSettings* goTimeSettings = [[[GoTimeSettings alloc] initWithAbsoluteTimeSystem:absoluteTimeSystem
                                                                 periodBasedTimeSystem:periodBasedTimeSystem] autorelease];


  TimeSettingsModel* timeSettingsModel = [[[TimeSettingsModel alloc] init] autorelease];
  [timeSettingsModel updateWithGoTimeSettings:goTimeSettings];
  return timeSettingsModel;
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoGameResult object that is populated with the game result
/// taken from the value of @a rePropertyValue.
///
/// @a rePropertyValue refers to the value of the SGF game info property RE.
/// The value @e nil indicates that the property is not present.
///
/// If @a rePropertyValue is an empty string, this is also treated as the
/// absence of the property, assuming that the value in this case is not coming
/// directly from the SGF data but has passed through some intermediate
/// processing (e.g. SGFCGameInfo).
// -----------------------------------------------------------------------------
+ (GoGameResult*) gameResultFromSgfString:(NSString*)rePropertyValue
{
  if (! rePropertyValue || rePropertyValue.length == 0)
    return [[[GoGameResult alloc] init] autorelease];

  SGFCGameResult gameResult = SGFCGameResultFromPropertyValue(rePropertyValue);
  if (! gameResult.IsValid)
    return [[[GoGameResult alloc] initWithSgfString:rePropertyValue] autorelease];

  switch (gameResult.GameResultType)
  {
    case SGFCGameResultTypeBlackWin:
    case SGFCGameResultTypeWhiteWin:
    {
      bool blackPlayerWins = (gameResult.GameResultType == SGFCGameResultTypeBlackWin);
      switch (gameResult.WinType)
      {
        case SGFCWinTypeWinWithScore:
          return [[[GoGameResult alloc] initWithPlayerWin:blackPlayerWins score:gameResult.Score] autorelease];
        case SGFCWinTypeWinWithoutScore:
          return [[[GoGameResult alloc] initWithNoScorePlayerWin:blackPlayerWins winType:GoGameResultWinTypeWinWithoutScore] autorelease];
        case SGFCWinTypeWinByResignation:
          return [[[GoGameResult alloc] initWithNoScorePlayerWin:blackPlayerWins winType:GoGameResultWinTypeWinByResignation] autorelease];
        case SGFCWinTypeWinOnTime:
          return [[[GoGameResult alloc] initWithNoScorePlayerWin:blackPlayerWins winType:GoGameResultWinTypeWinOnTime] autorelease];
        case SGFCWinTypeWinByForfeit:
          return [[[GoGameResult alloc] initWithNoScorePlayerWin:blackPlayerWins winType:GoGameResultWinTypeWinByForfeit] autorelease];
      }
      break;
    }
    case SGFCGameResultTypeDraw:
    {
      return [[[GoGameResult alloc] initWithNoPlayerWin:GoGameResultTypeDraw] autorelease];
    }
    case SGFCGameResultTypeNoResult:
    {
      return [[[GoGameResult alloc] initWithNoPlayerWin:GoGameResultTypeNoResult] autorelease];}
    case SGFCGameResultTypeUnknownResult:
    {
      return [[[GoGameResult alloc] initWithNoPlayerWin:GoGameResultTypeUnknownResult] autorelease];
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representing @a gameResult that can be used as the
/// value of the SGF property RE. Returns @e nil if the @e dataType property
/// of @a gameResult has the value #GoGameResultDataTypeNoResult.
// -----------------------------------------------------------------------------
+ (NSString*) sgfStringFromGameResult:(GoGameResult*)gameResult
{
  switch (gameResult.dataType)
  {
    case GoGameResultDataTypeNoResult:
    {
      return nil;
    }
    case GoGameResultDataTypeSgfString:
    {
      return gameResult.sgfString;
    }
    case GoGameResultDataTypeStructuredData:
    {
      SGFCGameResultType sgfcGameResultType;
      switch (gameResult.gameResultType)
      {
        case GoGameResultTypeBlackWin:
          sgfcGameResultType = SGFCGameResultTypeBlackWin;
          break;
        case GoGameResultTypeWhiteWin:
          sgfcGameResultType = SGFCGameResultTypeWhiteWin;
          break;
        case GoGameResultTypeDraw:
          sgfcGameResultType = SGFCGameResultTypeDraw;
          break;
        case GoGameResultTypeNoResult:
          sgfcGameResultType = SGFCGameResultTypeNoResult;
          break;
        case GoGameResultTypeUnknownResult:
          sgfcGameResultType = SGFCGameResultTypeUnknownResult;
          break;
      }

      SGFCWinType sgfcWinType;
      switch (gameResult.winType)
      {
        case GoGameResultWinTypeWinWithScore:
          sgfcWinType = SGFCWinTypeWinWithScore;
          break;
        case GoGameResultWinTypeWinWithoutScore:
          sgfcWinType = SGFCWinTypeWinWithoutScore;
          break;
        case GoGameResultWinTypeWinByResignation:
          sgfcWinType = SGFCWinTypeWinByResignation;
          break;
        case GoGameResultWinTypeWinOnTime:
          sgfcWinType = SGFCWinTypeWinOnTime;
          break;
        case GoGameResultWinTypeWinByForfeit:
          sgfcWinType = SGFCWinTypeWinByForfeit;
          break;
      }

      SGFCGameResult sgfcGameResult = SGFCGameResultMake(sgfcGameResultType, sgfcWinType, gameResult.score, true);
      return SGFCGameResultToPropertyValue(sgfcGameResult);
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoGameInfoRound object that is populated with the round
/// information (if any) stored in @a sgfGameInfo.
// -----------------------------------------------------------------------------
+ (GoGameInfoRound*) gameInfoRoundFromSgfGameInfo:(SGFCGameInfo*)sgfGameInfo
{
  if (sgfGameInfo.roundInformation.IsValid)
  {
    return [[[GoGameInfoRound alloc] initWithRoundType:sgfGameInfo.roundInformation.RoundType
                                           roundNumber:sgfGameInfo.roundInformation.RoundNumber] autorelease];
  }
  else if (sgfGameInfo.rawRoundInformation && sgfGameInfo.rawRoundInformation.length > 0)
  {
    return [[[GoGameInfoRound alloc] initWithSgfString:sgfGameInfo.rawRoundInformation] autorelease];
  }
  else
  {
    return [[[GoGameInfoRound alloc] init] autorelease];
  }
}

@end
