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
  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
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

@end
