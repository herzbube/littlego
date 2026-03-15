// -----------------------------------------------------------------------------
// Copyright 2026 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoGameInfo.h"
#import "GoGameInfoDates.h"
#import "GoGameInfoRank.h"
#import "GoGameInfoRound.h"
#import "GoGameInfoRules.h"
#import "GoGameResult.h"


@implementation GoGameInfo

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GoGameInfo object with default values.
///
/// @note This is the designated initializer of GoGameInfo.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.recorderName = nil;
  self.sourceName = nil;
  self.annotationAuthor = nil;
  self.copyrightInformation = nil;
  self.gameName = nil;
  self.gameInformation = nil;
  self.gameInfoDates = [[[GoGameInfoDates alloc] init] autorelease];
  self.gameInfoRules = [[[GoGameInfoRules alloc] init] autorelease];
  self.gameResult = [[[GoGameResult alloc] init] autorelease];
  self.openingInformation = nil;
  self.blackPlayerName = nil;
  self.blackPlayerRank = [[[GoGameInfoRank alloc] init] autorelease];
  self.blackPlayerTeamName = nil;
  self.whitePlayerName = nil;
  self.whitePlayerRank = [[[GoGameInfoRank alloc] init] autorelease];
  self.whitePlayerTeamName = nil;
  self.gameLocation = nil;
  self.eventName = nil;
  self.gameInfoRound = [[[GoGameInfoRound alloc] init] autorelease];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (id) initWithCoder:(NSCoder*)decoder
{
  self = [super init];
  if (! self)
    return nil;

  if ([decoder decodeIntForKey:nscodingVersionKey] != nscodingVersion)
    return nil;

  self.recorderName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoRecorderNameKey];
  self.sourceName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoSourceNameKey];
  self.annotationAuthor = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoAnnotationAuthorKey];
  self.copyrightInformation = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoCopyrightInformationKey];
  self.gameName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoGameNameKey];
  self.gameInformation = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoGameInformationKey];
  self.gameInfoDates = [decoder decodeObjectOfClass:[GoGameInfoDates class] forKey:goGameInfoGameInfoDatesKey];
  self.gameInfoRules = [decoder decodeObjectOfClass:[GoGameInfoRules class] forKey:goGameInfoGameInfoRulesKey];
  self.gameResult = [decoder decodeObjectOfClass:[GoGameResult class] forKey:goGameInfoGameResultKey];
  self.openingInformation = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoOpeningInformationKey];
  self.blackPlayerName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoBlackPlayerNameKey];
  self.blackPlayerRank = [decoder decodeObjectOfClass:[GoGameInfoRank class] forKey:goGameInfoBlackPlayerRankKey];
  self.blackPlayerTeamName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoBlackPlayerTeamNameKey];
  self.whitePlayerName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoWhitePlayerNameKey];
  self.whitePlayerRank = [decoder decodeObjectOfClass:[GoGameInfoRank class] forKey:goGameInfoWhitePlayerRankKey];
  self.whitePlayerTeamName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoWhitePlayerTeamNameKey];
  self.gameLocation = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoGameLocationKey];
  self.eventName = [decoder decodeObjectOfClass:[NSString class] forKey:goGameInfoEventNameKey];
  self.gameInfoRound = [decoder decodeObjectOfClass:[GoGameInfoRound class] forKey:goGameInfoGameInfoRoundKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief NSSecureCoding protocol method.
// -----------------------------------------------------------------------------
+ (BOOL) supportsSecureCoding
{
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoGameInfo object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.recorderName = nil;
  self.sourceName = nil;
  self.annotationAuthor = nil;
  self.copyrightInformation = nil;
  self.gameName = nil;
  self.gameInformation = nil;
  self.gameInfoDates = nil;
  self.gameInfoRules = nil;
  self.gameResult = nil;
  self.openingInformation = nil;
  self.blackPlayerName = nil;
  self.blackPlayerRank = nil;
  self.blackPlayerTeamName = nil;
  self.whitePlayerName = nil;
  self.whitePlayerRank = nil;
  self.whitePlayerTeamName = nil;
  self.gameLocation = nil;
  self.eventName = nil;
  self.gameInfoRound = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];

  [encoder encodeObject:self.recorderName forKey:goGameInfoRecorderNameKey];
  [encoder encodeObject:self.sourceName forKey:goGameInfoSourceNameKey];
  [encoder encodeObject:self.annotationAuthor forKey:goGameInfoAnnotationAuthorKey];
  [encoder encodeObject:self.copyrightInformation forKey:goGameInfoCopyrightInformationKey];
  [encoder encodeObject:self.gameName forKey:goGameInfoGameNameKey];
  [encoder encodeObject:self.gameInformation forKey:goGameInfoGameInformationKey];
  [encoder encodeObject:self.gameInfoDates forKey:goGameInfoGameInfoDatesKey];
  [encoder encodeObject:self.gameInfoRules forKey:goGameInfoGameInfoRulesKey];
  [encoder encodeObject:self.gameResult forKey:goGameInfoGameResultKey];
  [encoder encodeObject:self.openingInformation forKey:goGameInfoOpeningInformationKey];
  [encoder encodeObject:self.blackPlayerName forKey:goGameInfoBlackPlayerNameKey];
  [encoder encodeObject:self.blackPlayerRank forKey:goGameInfoBlackPlayerRankKey];
  [encoder encodeObject:self.blackPlayerTeamName forKey:goGameInfoBlackPlayerTeamNameKey];
  [encoder encodeObject:self.whitePlayerName forKey:goGameInfoWhitePlayerNameKey];
  [encoder encodeObject:self.whitePlayerRank forKey:goGameInfoWhitePlayerRankKey];
  [encoder encodeObject:self.whitePlayerTeamName forKey:goGameInfoWhitePlayerTeamNameKey];
  [encoder encodeObject:self.gameLocation forKey:goGameInfoGameLocationKey];
  [encoder encodeObject:self.eventName forKey:goGameInfoEventNameKey];
  [encoder encodeObject:self.gameInfoRound forKey:goGameInfoGameInfoRoundKey];
}

@end
