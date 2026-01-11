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
/// @brief Returns a string representation of the content of @a sgfGameResult.
/// Returns an empty string if the game result is not valid.
// -----------------------------------------------------------------------------
+ (NSString*) stringForSgfGameResult:(SGFCGameResult)sgfGameResult
{
  if (! sgfGameResult.IsValid)
    return @"";

  switch (sgfGameResult.GameResultType)
  {
    case SGFCGameResultTypeBlackWin:
    case SGFCGameResultTypeWhiteWin:
    {
      NSString* gameResultAsString;
      if (sgfGameResult.GameResultType == SGFCGameResultTypeBlackWin)
        gameResultAsString = @"Black wins";
      else
        gameResultAsString = @"White wins";

      switch (sgfGameResult.WinType)
      {
        case SGFCWinTypeWinWithScore:
          gameResultAsString = [gameResultAsString stringByAppendingFormat:@" by %.1f", sgfGameResult.Score];
          break;
        case SGFCWinTypeWinWithoutScore:
          break;
        case SGFCWinTypeWinByResignation:
          gameResultAsString = [gameResultAsString stringByAppendingString:@" by resignation"];
          break;
        case SGFCWinTypeWinOnTime:
          gameResultAsString = [gameResultAsString stringByAppendingString:@" on time"];
          break;
        case SGFCWinTypeWinByForfeit:
          gameResultAsString = [gameResultAsString stringByAppendingString:@" by forfeit"];
          break;
        default:
          assert(0);
          break;
      }

      return gameResultAsString;
    }
    case SGFCGameResultTypeDraw:
    {
      return @"Game is a tie";
    }
    case SGFCGameResultTypeNoResult:
    {
      return @"No result / Suspended play";
    }
    case SGFCGameResultTypeUnknownResult:
    {
      return @"Unknown result";
    }
    default:
    {
      assert(0);
      break;
    }
  }

  // If this happens there is a coding error above
  return @"";
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
/// @brief Maps the app-specific enum value @a goGameHasEndedReason to an
/// SGFCGameResult struct. If no mapping is possible the returned struct has
/// the @e IsValid property set to NO.
// -----------------------------------------------------------------------------
+ (SGFCGameResult) gameResultForGoGameHasEndedReason:(enum GoGameHasEndedReason)goGameHasEndedReason
{
  SGFCGameResultType gameResultType;
  SGFCWinType winType;
  BOOL isValid;
  switch (goGameHasEndedReason)
  {
    case GoGameHasEndedReasonBlackWinsByResignation:
      gameResultType = SGFCGameResultTypeBlackWin;
      winType = SGFCWinTypeWinByResignation;
      isValid = YES;
      break;
    case GoGameHasEndedReasonWhiteWinsByResignation:
      gameResultType = SGFCGameResultTypeWhiteWin;
      winType = SGFCWinTypeWinByResignation;
      isValid = YES;
      break;
    case GoGameHasEndedReasonBlackWinsOnTime:
      gameResultType = SGFCGameResultTypeBlackWin;
      winType = SGFCWinTypeWinOnTime;;
      isValid = YES;
      break;
    case GoGameHasEndedReasonWhiteWinsOnTime:
      gameResultType = SGFCGameResultTypeWhiteWin;
      winType = SGFCWinTypeWinOnTime;
      isValid = YES;
      break;
    case GoGameHasEndedReasonBlackWinsByForfeit:
      gameResultType = SGFCGameResultTypeBlackWin;
      winType = SGFCWinTypeWinByForfeit;
      isValid = YES;
      break;
    case GoGameHasEndedReasonWhiteWinsByForfeit:
      gameResultType = SGFCGameResultTypeWhiteWin;
      winType = SGFCWinTypeWinByForfeit;
      isValid = YES;
      break;
    default:
      gameResultType = SGFCGameResultTypeUnknownResult;
      winType = SGFCWinTypeWinWithScore;
      isValid = NO;
      break;
  }

  return SGFCGameResultMake(gameResultType, winType, 0.0, isValid);
}

// -----------------------------------------------------------------------------
/// @brief Maps the SGFCGameResult struct @a gameResult to a value from the
/// app-specific enum GoGameHasEndedReason. Returns
/// #GoGameHasEndedReasonNotYetEnded if no mapping is possible.
// -----------------------------------------------------------------------------
+ (enum GoGameHasEndedReason) goGameHasEndedReasonForGameResult:(SGFCGameResult)gameResult
{
  if (! gameResult.IsValid)
    return GoGameHasEndedReasonNotYetEnded;

  switch (gameResult.GameResultType)
  {
    case SGFCGameResultTypeBlackWin:
    case SGFCGameResultTypeWhiteWin:
      switch (gameResult.WinType)
      {
        case SGFCWinTypeWinByResignation:
          if (gameResult.GameResultType == SGFCGameResultTypeBlackWin)
            return GoGameHasEndedReasonBlackWinsByResignation;
          else
            return GoGameHasEndedReasonWhiteWinsByResignation;
        case SGFCWinTypeWinOnTime:
          if (gameResult.GameResultType == SGFCGameResultTypeBlackWin)
            return GoGameHasEndedReasonBlackWinsOnTime;
          else
            return GoGameHasEndedReasonWhiteWinsOnTime;
        case SGFCWinTypeWinByForfeit:
          if (gameResult.GameResultType == SGFCGameResultTypeBlackWin)
            return GoGameHasEndedReasonBlackWinsByForfeit;
          else
            return GoGameHasEndedReasonWhiteWinsByForfeit;
        default:
          return GoGameHasEndedReasonNotYetEnded;
      }
    default:
      return GoGameHasEndedReasonNotYetEnded;
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
///
/// @note The notations provided as examples in the SGF specification
/// ("5 mins Japanese style, 1 move / min", "25 moves / 10 min") are currently
/// not supported because they are poorly structured. Ignoring the fact that
/// they are also incomplete (the first example does not specify the number of
/// periods/lifes, the second example does not specify the time system), an
/// attempt to recognize data in poorly structured @a sgfOvertimeString might
/// look for regex patterns like these:
/// - "[0-9\.]+ min(s)?" => indicates a period duration
/// - "[0-9]+ move(s)?" => indicates a minimum number of moves
/// - "[0-9]+ period(s)?" => indicates a number of periods
/// - "[0-9]+ extra" => indicates an extra time duration
/// - The time system could be derived if a keywords is found anywhere in the
///   string.
// -----------------------------------------------------------------------------
+ (GoTimeSystem*) periodBasedTimeSystemForSgfOvertimeString:(NSString*)sgfOvertimeString
                                       absoluteTimeDuration:(double*)absoluteTimeDuration
                             didConsumeAbsoluteTimeDuration:(bool*)didConsumeAbsoluteTimeDuration
{
  if (didConsumeAbsoluteTimeDuration)
    *didConsumeAbsoluteTimeDuration = false;

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

@end
