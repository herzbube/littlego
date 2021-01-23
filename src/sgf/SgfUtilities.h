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


// Forward declarations
@class SGFCDocumentReadResult;


// -----------------------------------------------------------------------------
/// @brief The SgfUtilities class is a container for various utility functions
/// related to working with SGF data.
///
/// @ingroup go
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
+ (void) parseSgfGameDates:(NSArray*)sgfGameDates dateArray:(NSArray**)dateArray stringArray:(NSArray**)stringArray;
+ (NSString*) stringForSgfGameResult:(SGFCGameResult)sgfGameResult;
+ (NSString*) stringForSgfGoPlayerRank:(SGFCGoPlayerRank)sgfGoPlayerRank;
+ (UIColor*) colorForLoadResultWithNoMessages;
+ (UIColor*) colorForLoadResultWithMessagesOfType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage;
+ (UIImage*) coloredIndicatorForLoadResult:(SGFCDocumentReadResult*)loadResult;
+ (UIColor*) colorForMessageType:(SGFCMessageType)messageType isCriticalMessage:(bool)isCriticalMessage;
+ (UIImage*) coloredIndicatorForMessage:(SGFCMessage*)message;
+ (SGFCGameResult) gameResultForGoGameHasEndedReason:(enum GoGameHasEndedReason)goGameHasEndedReason;
+ (enum GoGameHasEndedReason) goGameHasEndedReasonForGameResult:(SGFCGameResult)gameResult;

@end
