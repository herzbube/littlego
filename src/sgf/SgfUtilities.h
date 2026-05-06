// -----------------------------------------------------------------------------
// Copyright 2021-2026 Patrick Näf (herzbube@herzbube.ch)
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
@class SGFCDocumentReadResult;
@class GoGameInfoDates;
@class GoGameInfoRank;
@class GoGameInfoRound;
@class GoGameResult;
@class GoTimeSystem;
@class TimeSettingsModel;


// -----------------------------------------------------------------------------
/// @brief The SgfUtilities class is a container for various utility functions
/// related to working with SGF data.
///
/// @ingroup sgf
///
/// All functions in SgfUtilities are class methods, so there is no need to
/// create an instance of SgfUtilities.
// -----------------------------------------------------------------------------
@interface SgfUtilities : NSObject
{
}

+ (bool) isLoadOperationSuccessful:(SGFCDocumentReadResult*)readResult
               withLoadSuccessType:(enum SgfLoadSuccessType)loadSuccessType;

+ (NSString*) stringForSgfBoardSize:(SGFCBoardSize)sgfBoardSize;
+ (enum GoBoardSize) goBoardSizeForSgfBoardSize:(SGFCBoardSize)sgfBoardSize errorMessage:(NSString**)errorMessage;
+ (UIColor*) colorForLoadResultWithNoMessages;
+ (UIColor*) colorForLoadResultWithMessagesOfType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage;
+ (UIImage*) coloredIndicatorForLoadResult:(SGFCDocumentReadResult*)loadResult;
+ (UIColor*) colorForMessageType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage;
+ (UIImage*) coloredIndicatorForMessage:(SGFCMessage*)message;
+ (NSString*) sgfTimeSystemIdentifierForTimeSystemType:(enum GoTimeSystemType)timeSystemType;
+ (enum GoTimeSystemType) timeSystemTypeForSgfTimeSystemIdentifier:(NSString*)sgfTimeSystemIdentifier;
+ (NSString*) sgfOvertimeStringForPeriodBasedTimeSystem:(GoTimeSystem*)periodBasedTimeSystem;
+ (GoTimeSystem*) periodBasedTimeSystemForSgfOvertimeString:(NSString*)sgfOvertimeString
                                       absoluteTimeDuration:(double*)absoluteTimeDuration
                             didConsumeAbsoluteTimeDuration:(bool*)didConsumeAbsoluteTimeDuration;
+ (NSString*) sgfDurationStringForDurationValue:(double)durationValue;
+ (double) durationValueFromSgfDurationString:(NSString*)sgfDurationString;
+ (TimeSettingsModel*) timeSettingsFromSgfGameInfoNode:(SGFCNode*)sgfGameInfoNode;
+ (TimeSettingsModel*) timeSettingsFromSgfGameInfo:(SGFCGameInfo*)sgfGameInfo;
+ (GoGameResult*) gameResultFromSgfString:(NSString*)rePropertyValue;
+ (NSString*) sgfStringFromGameResult:(GoGameResult*)gameResult;
+ (GoGameInfoRound*) gameInfoRoundFromSgfGameInfo:(SGFCGameInfo*)sgfGameInfo;
+ (NSString*) sgfStringFromGameInfoRound:(GoGameInfoRound*)gameInfoRound;
+ (GoGameInfoRank*) gameInfoRankFromSgfGoGameInfo:(SGFCGoGameInfo*)sgfGoGameInfo
                                  blackPlayerRank:(bool)blackPlayerRank;
+ (NSString*) sgfStringFromGameInfoRank:(GoGameInfoRank*)gameInfoRank;
+ (enum GoGameInfoRankType) gameInfoRankTypeForSgfRankType:(SGFCGoPlayerRankType)sgfRankType;
+ (SGFCGoPlayerRankType) sgfRankTypeForGameInfoRankType:(enum GoGameInfoRankType)gameInfoRankType;
+ (enum GoGameInfoRatingType) gameInfoRatingTypeForSgfRatingType:(SGFCGoPlayerRatingType)sgfRatingType;
+ (SGFCGoPlayerRatingType) sgfRatingTypeForGameInfoRatingType:(enum GoGameInfoRatingType)gameInfoRatingType;
+ (GoGameInfoDates*) gameInfoDatesFromSgfGameInfo:(SGFCGameInfo*)sgfGameInfo;
+ (NSString*) sgfStringFromGameInfoDates:(GoGameInfoDates*)gameInfoDates;

@end
