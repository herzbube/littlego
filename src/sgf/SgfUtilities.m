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
      break;
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
      rankTypeAsString = @"k";
      break;
    case SGFCGoPlayerRankTypeAmateurDan:
      rankTypeAsString = @"d";
      break;
    case SGFCGoPlayerRankTypeProfessionalDan:
      rankTypeAsString = @"p";
      break;
    default:
      assert(0);
      return @"";
  }

  // We ignore SGFCGoPlayerRatingType
  return [NSString stringWithFormat:@"%@%ld", rankTypeAsString, (long)sgfGoPlayerRank.Rank];
}

@end
