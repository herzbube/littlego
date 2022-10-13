// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "GoNodeSetup.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GoNodeSetup.
// -----------------------------------------------------------------------------
@interface GoNodeSetup()
@property(nonatomic, retain) NSMutableArray* mutableBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableWhiteSetupStones;
@property(nonatomic, retain) NSMutableArray* mutableNoSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousBlackSetupStones;
@property(nonatomic, retain) NSMutableArray* mutablePreviousWhiteSetupStones;
@end


@implementation GoNodeSetup

// -----------------------------------------------------------------------------
/// @brief Initializes a GoNodeSetup object.
///
/// @note This is the designated initializer of GoNodeSetup.
// -----------------------------------------------------------------------------
- (id) initWithGame:(GoGame*)game
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.mutableBlackSetupStones = nil;
  self.mutableWhiteSetupStones = nil;
  self.mutableNoSetupStones = nil;
  self.setupFirstMoveColor = GoColorNone;
  self.mutablePreviousBlackSetupStones = nil;
  self.mutablePreviousWhiteSetupStones = nil;
  self.previousSetupFirstMoveColor = GoColorNone;

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

  // TODO xxx
//  self.type = [decoder decodeIntForKey:goMoveTypeKey];
//  self.player = [decoder decodeObjectForKey:goMovePlayerKey];
//  _point = [decoder decodeObjectForKey:goMovePointKey];  // don't use self, otherwise we trigger the setter!
//  // The previous/next moves were not archived. Whoever is unarchiving this
//  // GoMove is responsible for setting the previous/next move.
//  self.previous = nil;
//  self.next = nil;
//  self.capturedStones = [decoder decodeObjectForKey:goMoveCapturedStonesKey];
//  self.moveNumber = [decoder decodeIntForKey:goMoveMoveNumberKey];
//  // The hash was not archived. Whoever is unarchiving this GoMove is
//  // responsible for re-calculating the hash.
//  self.zobristHash = 0;
//  self.goMoveValuation = [decoder decodeIntForKey:goMoveGoMoveValuationKey];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GoNodeSetup object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.mutableBlackSetupStones = nil;
  self.mutableWhiteSetupStones = nil;
  self.mutableNoSetupStones = nil;
  self.mutablePreviousBlackSetupStones = nil;
  self.mutablePreviousWhiteSetupStones = nil;

  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief NSCoding protocol method.
// -----------------------------------------------------------------------------
- (void) encodeWithCoder:(NSCoder*)encoder
{
  // TODO xxx
//  [encoder encodeInt:nscodingVersion forKey:nscodingVersionKey];
//  [encoder encodeInt:self.type forKey:goMoveTypeKey];
//  [encoder encodeObject:self.player forKey:goMovePlayerKey];
//  [encoder encodeObject:self.point forKey:goMovePointKey];
//  // The GoMove objects for the next/previous move are not archived because
//  // in a game with many moves (e.g. a thousand moves) the result would be a
//  // stack overflow (archiving the next GoMove object causes that object to
//  // access its own next GoMove object, and so on).
//  [encoder encodeObject:self.capturedStones forKey:goMoveCapturedStonesKey];
//  [encoder encodeInt:self.moveNumber forKey:goMoveMoveNumberKey];
//  [encoder encodeInt:self.goMoveValuation forKey:goMoveGoMoveValuationKey];
//  // GoZobristTable is not archived, instead a new GoZobristTable object with
//  // random values is created each time when a game is unarchived. Zobrist
//  // hashes created by the previous GoZobristTable object are thus invalid.
//  // This is the reason why we don't archive self.zobristHash here - it doesn't
//  // make sense to archive an invalid value. A side effect of not archiving
//  // self.zobristHash is that the overall archive becomes smaller.
}

#pragma mark - NSObject overrides

// -----------------------------------------------------------------------------
/// @brief Returns a description for this GoNodeSetup object.
///
/// This method is invoked when GoNodeSetup needs to be represented as a string,
/// i.e. by NSLog, or when the debugger command "po" is used on the object.
// -----------------------------------------------------------------------------
- (NSString*) description
{
  // Don't use self to access properties to avoid unnecessary overhead during
  // debugging
  return [NSString stringWithFormat:@"GoNodeSetup(%p): blackSetupStones = %@, whiteSetupStones = %@, noSetupStones = %@, setupFirstMoveColor = %d", self, _mutableBlackSetupStones, _mutableWhiteSetupStones, _mutableNoSetupStones, _setupFirstMoveColor];
}

#pragma mark - Public API - Delayed initialization

// -----------------------------------------------------------------------------
/// @brief Captures setup information prior to this GoNodeSetup.
// -----------------------------------------------------------------------------
- (void) capturePreviousSetupInformation:(GoGame*)game
{
  // TODO xxx
}

#pragma mark - Public API - Applying and reverting setup information

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) applySetup
{
  // TODO xxx
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) revertSetup
{
  // TODO xxx
}

#pragma mark - Public API - Placing and removing stones

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) placeBlackSetupStone:(GoPoint*)point
{
  // TODO xxx
  // TODO xxx Is invoked by LoadGameCommand before previous setup has been captured
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) placeWhiteSetupStone:(GoPoint*)point
{
  // TODO xxx
  // TODO xxx Is invoked by LoadGameCommand before previous setup has been captured
}

// -----------------------------------------------------------------------------
// Method is documented in the header file.
// -----------------------------------------------------------------------------
- (void) clearSetupStone:(GoPoint*)point
{
  // TODO xxx
  // TODO xxx Is invoked by LoadGameCommand before previous setup has been captured
}

#pragma mark - Public API - Properties

- (bool) isEmpty
{
  return ((! self.blackSetupStones || self.blackSetupStones.count == 0) &&
          (! self.whiteSetupStones || self.whiteSetupStones.count == 0) &&
          (! self.noSetupStones || self.noSetupStones.count == 0) &&
          self.setupFirstMoveColor == GoColorNone);
}

@end

